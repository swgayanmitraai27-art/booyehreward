import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/url_launcher_util.dart';

class DepositDialog extends StatefulWidget {
  final AppState appState;

  const DepositDialog({super.key, required this.appState});

  @override
  State<DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<DepositDialog> {
  final TextEditingController _amountController = TextEditingController(text: '20');

  bool isQrLoading = false;
  Uint8List? qrImageBytes;
  String? activeQrId;
  String? activePaymentUrl;
  double initialDepositCash = 0;
  Timer? _pollingTimer;
  Map<String, dynamic>? successData;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    initialDepositCash = widget.appState.user.wallet.depositCash;
    _fetchRazorpayQrFromApi(20);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  double get currentAmount => double.tryParse(_amountController.text.trim()) ?? 0;
  double get bonusCash => currentAmount * 0.10; // 10% Extra Deposit Cash
  double get totalDepositCash => currentAmount + bonusCash;

  Future<void> _fetchRazorpayQrFromApi(double amt) async {
    if (amt < 10) return;
    setState(() {
      isQrLoading = true;
      errorMsg = null;
      qrImageBytes = null;
    });

    try {
      final res = await http.post(
        Uri.parse('https://www.swgayanbhumi.in/api/skillwinner/qr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.appState.user.uid,
          'amount': amt,
        }),
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final qId = data['qrId'] as String;
          final b64 = data['imageBase64'] as String?;
          final payUrl = data['paymentUrl'] as String?;

          Uint8List? bytes;
          if (b64 != null && b64.isNotEmpty) {
            bytes = base64Decode(b64);
          }

          if (mounted) {
            setState(() {
              activeQrId = qId;
              qrImageBytes = bytes;
              activePaymentUrl = payUrl;
              isQrLoading = false;
            });
            _startAutoPoller(qId);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('[DepositDialog] Razorpay QR API Fetch Error: $e');
    }

    if (mounted) {
      setState(() {
        isQrLoading = false;
        errorMsg = 'Could not fetch Razorpay QR. Tap retry or check your internet connection.';
      });
    }
  }

  void _startAutoPoller(String qrId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        // 1. Check Razorpay QR API Status
        final res = await http.get(
          Uri.parse('https://www.swgayanbhumi.in/api/skillwinner/qr/check?qrId=$qrId&userId=${widget.appState.user.uid}'),
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['paid'] == true || data['status'] == 'SUCCESS') {
            timer.cancel();
            await widget.appState.refreshFromFirestore();
            if (mounted) {
              setState(() {
                successData = {
                  'amount': data['amount'] ?? currentAmount,
                  'bonus': data['extraBonus'] ?? bonusCash,
                  'total': data['totalDepositCash'] ?? totalDepositCash,
                  'txId': data['paymentId'] ?? qrId,
                };
              });
            }
            return;
          }
        }

        // 2. Check Firestore wallet directly
        await widget.appState.refreshFromFirestore();
        final newBal = widget.appState.user.wallet.depositCash;
        if (newBal > initialDepositCash) {
          timer.cancel();
          if (mounted) {
            setState(() {
              successData = {
                'amount': currentAmount,
                'bonus': bonusCash,
                'total': totalDepositCash,
                'txId': 'VERIFIED_ON_WALLET',
              };
            });
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _downloadQr() async {
    if (activePaymentUrl != null) {
      await UrlLauncherUtil.openUrl(activePaymentUrl!);
    } else if (activeQrId != null) {
      await UrlLauncherUtil.openUrl('https://api.razorpay.com/v1/l/qrcode/$activeQrId');
    }
  }

  Future<void> _openRazorpayWeb() async {
    final url = activePaymentUrl ?? 'https://www.swgayanbhumi.in/pay?app=skillwinner&userId=${widget.appState.user.uid}&amount=${currentAmount.toInt()}&auto=1';
    await UrlLauncherUtil.openUrl(url);
  }

  Future<void> _manualCheckBalance() async {
    setState(() => errorMsg = null);
    await widget.appState.refreshFromFirestore();
    if (!mounted) return;

    if (widget.appState.user.wallet.depositCash > initialDepositCash) {
      _pollingTimer?.cancel();
      setState(() {
        successData = {
          'amount': currentAmount,
          'bonus': bonusCash,
          'total': totalDepositCash,
          'txId': 'VERIFIED_ON_WALLET',
        };
      });
      return;
    }

    if (activeQrId != null) {
      try {
        final res = await http.get(
          Uri.parse('https://www.swgayanbhumi.in/api/skillwinner/qr/check?qrId=$activeQrId&userId=${widget.appState.user.uid}'),
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          if (data['paid'] == true || data['status'] == 'SUCCESS') {
            _pollingTimer?.cancel();
            setState(() {
              successData = {
                'amount': data['amount'] ?? currentAmount,
                'bonus': data['extraBonus'] ?? bonusCash,
                'total': data['totalDepositCash'] ?? totalDepositCash,
                'txId': data['paymentId'] ?? activeQrId,
              };
            });
            return;
          }
        }
      } catch (_) {}
    }

    setState(() {
      errorMsg = 'Payment in progress... Complete in GPay/PhonePe and balance will reflect automatically.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: successData != null ? _buildSuccessView() : _buildQrPaymentBody(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFA7F3D0), width: 2.5),
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppTheme.winningGreen, size: 44),
          ),
          const SizedBox(height: 14),
          Text(
            'Payment Received & Credited! 🎉',
            textAlign: TextAlign.center,
            style: AppTheme.gamingTitle(fontSize: 19, color: const Color(0xFF065F46)),
          ),
          const SizedBox(height: 6),
          const Text(
            '10% Extra Deposit Cash has been added to your wallet automatically.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Amount Paid', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    Text('₹${(successData!['amount'] as num).toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('10% Extra Deposit Bonus', style: TextStyle(fontSize: 13, color: Color(0xFF047857), fontWeight: FontWeight.w600)),
                    Text('+₹${(successData!['bonus'] as num).toStringAsFixed(1)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Credited Deposit Cash', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    Text('₹${(successData!['total'] as num).toStringAsFixed(1)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                _pollingTimer?.cancel();
                Navigator.of(context).pop();
              },
              child: const Text('DONE & PLAY TOURNAMENTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrPaymentBody() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.qr_code_2_rounded, color: Colors.blue.shade700, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OFFICIAL RAZORPAY UPI QR',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        'Add Deposit Cash',
                        style: AppTheme.gamingTitle(fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  _pollingTimer?.cancel();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 10% Extra Bonus Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Row(
              children: [
                const Text('🎁', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recharge ₹${currentAmount.toInt()} ➔ Get ₹${totalDepositCash.toStringAsFixed(1)} (+10% Extra Deposit Cash)!',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Presets Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [10, 20, 50, 100, 200, 500].map((amt) {
              final isSelected = currentAmount.toInt() == amt;
              return InkWell(
                onTap: () {
                  _amountController.text = amt.toString();
                  setState(() {});
                  _fetchRazorpayQrFromApi(amt.toDouble());
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? const Color(0xFF0F172A) : Colors.transparent),
                  ),
                  child: Text(
                    '₹$amt',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF334155),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // OFFICIAL RAZORPAY GENERATED QR IMAGE CARD (RENDERED VIA DIRECT MEMORY BYTES)
          Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 320, maxHeight: 360),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade100, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: isQrLoading || qrImageBytes == null
                  ? Container(
                      height: 260,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: Colors.blue),
                          const SizedBox(height: 14),
                          Text(
                            'Loading Razorpay QR (₹${currentAmount.toInt()})...',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        qrImageBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // DUAL ACTION BUTTONS: DOWNLOAD QR + PAY ON RAZORPAY WEB
          Row(
            children: [
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.download_rounded, size: 16),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _downloadQr,
                  label: const Text('Download QR', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _openRazorpayWeb,
                  label: Text('Pay on Web (₹${currentAmount.toInt()})', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // LIVE POLLING / REFRESH BUTTON
          InkWell(
            onTap: _manualCheckBalance,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sync_rounded, size: 14, color: Color(0xFF047857)),
                  SizedBox(width: 6),
                  Text(
                    'Paid? Tap here to Verify & Refresh Balance',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                  ),
                ],
              ),
            ),
          ),

          if (errorMsg != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMsg!,
              style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}
