import 'dart:async';
import 'dart:convert';
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
  final TextEditingController _amountController = TextEditingController(text: '100');

  bool isQrLoading = false;
  String? qrImageUrl;
  String? activeQrId;
  String? activePaymentUrl;
  Timer? _pollingTimer;
  Map<String, dynamic>? successData;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchRazorpayQr(100);
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

  Future<void> _fetchRazorpayQr(double amt) async {
    if (amt < 10) return;
    setState(() {
      isQrLoading = true;
      errorMsg = null;
    });

    try {
      final res = await http.post(
        Uri.parse('https://www.swgayanbhumi.in/api/skillwinner/qr'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': widget.appState.user.uid,
          'amount': amt,
        }),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final qId = data['qrId'] as String;
          final payUrl = data['imageUrl'] as String? ?? 'https://www.swgayanbhumi.in/pay?app=skillwinner&userId=${widget.appState.user.uid}&amount=${amt.toInt()}&auto=1';
          
          // Generate direct QR image url from the payment url
          final directQrImage = 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${Uri.encodeComponent(payUrl)}';

          if (mounted) {
            setState(() {
              activeQrId = qId;
              activePaymentUrl = payUrl;
              qrImageUrl = directQrImage;
              isQrLoading = false;
            });
            _startAutoPoller(qId);
            return;
          }
        }
      }
    } catch (_) {}

    // Fallback payment url
    final fallbackUrl = 'https://www.swgayanbhumi.in/pay?app=skillwinner&userId=${widget.appState.user.uid}&amount=${amt.toInt()}&auto=1';
    if (mounted) {
      setState(() {
        activeQrId = 'fallback_${DateTime.now().millisecondsSinceEpoch}';
        activePaymentUrl = fallbackUrl;
        qrImageUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=${Uri.encodeComponent(fallbackUrl)}';
        isQrLoading = false;
      });
    }
  }

  void _startAutoPoller(String qrId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        // 1. Check QR check API
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

        // 2. Also check Firestore directly
        await widget.appState.refreshFromFirestore();
      } catch (_) {}
    });
  }

  Future<void> _openGatewayUrl() async {
    final url = activePaymentUrl ?? 'https://www.swgayanbhumi.in/pay?app=skillwinner&userId=${widget.appState.user.uid}&amount=${currentAmount.toInt()}&auto=1';
    await UrlLauncherUtil.openUrl(url);
  }

  Future<void> _manualCheckBalance() async {
    setState(() => errorMsg = null);
    await widget.appState.refreshFromFirestore();
    if (!mounted) return;

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
      errorMsg = 'Payment not confirmed yet. Please scan the QR code or tap Pay via UPI.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(18),
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
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppTheme.winningGreen, size: 40),
          ),
          const SizedBox(height: 14),
          Text(
            'Deposit Cash Credited!',
            style: AppTheme.gamingTitle(fontSize: 20, color: const Color(0xFF065F46)),
          ),
          const SizedBox(height: 6),
          const Text(
            '10% Extra Deposit Cash has been added to your wallet.',
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
              child: const Text('DONE & PLAY MATCHES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                    child: Icon(Icons.qr_code_scanner_rounded, color: Colors.blue.shade700, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SW TECH • RAZORPAY OFFICIAL GATEWAY',
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
                    'Recharge ₹${currentAmount.toInt()} ➔ Get ₹${totalDepositCash.toStringAsFixed(1)} Deposit Cash (10% Extra Cash)!',
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
                  _fetchRazorpayQr(amt.toDouble());
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
          const SizedBox(height: 12),

          // RAZORPAY QR CODE DISPLAY CARD
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.blue.shade100, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isQrLoading
                        ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
                        : Image.network(
                            qrImageUrl ?? 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=https://swgayanbhumi.in',
                            fit: BoxFit.contain,
                          ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '📸 Screenshot QR & Pay with GPay / PhonePe / Paytm',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // BUTTON 1: DIRECT PAY VIA UPI APP / IN-APP GATEWAY
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.flash_on_rounded, size: 16),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: _openGatewayUrl,
              label: Text(
                '⚡ OPEN GPAY / PHONEPE / GATEWAY (₹${currentAmount.toInt()})',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // BUTTON 2: MANUAL STATUS CHECK
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 16),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1D4ED8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _manualCheckBalance,
              label: const Text('Check Balance Status', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
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
