import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/app_state.dart';
import '../utils/url_launcher_util.dart';

class DepositScreen extends StatefulWidget {
  final AppState appState;
  final double initialAmount;

  const DepositScreen({
    super.key,
    required this.appState,
    this.initialAmount = 50.0,
  });

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  late final TextEditingController _amountController;
  int _currentStep = 0; // 0: Select Amount, 1: Full-Screen Dedicated QR & UPI Pay
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
    _amountController = TextEditingController(text: widget.initialAmount.toInt().toString());
    initialDepositCash = widget.appState.user.wallet.depositCash;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  double get currentAmount => double.tryParse(_amountController.text.trim()) ?? 0;
  double get bonusCash => (currentAmount * 0.10); // 10% Extra Bonus Cashback
  double get totalPlayableCash => currentAmount + bonusCash;

  Future<void> _generateOfficialRazorpayQr(double amt) async {
    if (amt < 10) {
      setState(() => errorMsg = 'Minimum recharge amount is ₹10.');
      return;
    }
    setState(() {
      _currentStep = 1;
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
      debugPrint('[DepositScreen] Razorpay QR API Fetch Error: $e');
    }

    if (mounted) {
      setState(() {
        isQrLoading = false;
        errorMsg = 'Could not generate Razorpay QR. Tap retry or check your internet connection.';
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
            widget.appState.depositCash(currentAmount, qrId, description: 'Added ₹${currentAmount.toInt()} Real Cash via Razorpay UPI');
            if (mounted) {
              setState(() {
                successData = {
                  'amount': data['amount'] ?? currentAmount,
                  'bonus': data['extraBonus'] ?? bonusCash,
                  'total': data['totalDepositCash'] ?? totalPlayableCash,
                  'txId': data['paymentId'] ?? qrId,
                };
              });
            }
            return;
          }
        }

        // 2. Check Wallet balance sync directly on VPS
        final curBal = widget.appState.user.wallet.depositCash;
        if (curBal > initialDepositCash) {
          timer.cancel();
          if (mounted) {
            setState(() {
              successData = {
                'amount': currentAmount,
                'bonus': bonusCash,
                'total': totalPlayableCash,
                'txId': 'VERIFIED_ON_LEDGER',
              };
            });
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _openUpiPayment() async {
    if (activePaymentUrl != null && activePaymentUrl!.isNotEmpty) {
      await UrlLauncherUtil.openUrl(activePaymentUrl!);
    } else {
      final upiUri = 'upi://pay?pa=7307222384@ybl&pn=BooyahRewards&am=${currentAmount.toInt()}&cu=INR&tn=BR_DEP_${widget.appState.user.uid}';
      await UrlLauncherUtil.openUrl(upiUri);
    }
  }

  void _manualCheckBalance() async {
    final curBal = widget.appState.user.wallet.depositCash;
    if (curBal > initialDepositCash) {
      setState(() {
        successData = {
          'amount': currentAmount,
          'bonus': bonusCash,
          'total': totalPlayableCash,
          'txId': 'MANUAL_VERIFIED',
        };
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checking with Razorpay... Balance will update automatically once verified.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () {
            if (_currentStep == 1 && successData == null) {
              setState(() {
                _currentStep = 0;
                _pollingTimer?.cancel();
              });
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Add Cash (Razorpay UPI)',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user, color: Color(0xFF059669), size: 14),
                SizedBox(width: 4),
                Text(
                  '100% Safe',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: successData != null
              ? _buildSuccessView()
              : _currentStep == 0
                  ? _buildStepSelectAmount()
                  : _buildStepQrPayment(),
        ),
      ),
    );
  }

  Widget _buildStepSelectAmount() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withAlpha(50),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'CURRENT DEPOSIT BALANCE',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '+10% FREE BONUS',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w900, color: Colors.black),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${widget.appState.user.wallet.depositCash.toStringAsFixed(2)}',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Deposit cash is used to join paid tournaments & win real cash prizes.',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'SELECT RECHARGE AMOUNT',
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
          ),
          const SizedBox(height: 10),

          // Preset Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [20, 50, 100, 200, 500, 1000].map((amt) {
              final isSelected = currentAmount == amt.toDouble();
              return InkWell(
                onTap: () {
                  setState(() {
                    _amountController.text = amt.toString();
                    errorMsg = null;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1D4ED8) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isSelected ? 20 : 6),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '₹$amt',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          const Text(
            'OR ENTER CUSTOM AMOUNT (MIN ₹10)',
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w900),
            onChanged: (_) => setState(() => errorMsg = null),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text('₹', style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1D4ED8), width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
          const SizedBox(height: 14),

          // 10% Extra Cashback Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('🎁', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '10% Extra Cashback Bonus',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                        Text(
                          'You will receive ₹${totalPlayableCash.toStringAsFixed(1)} total in wallet',
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '+ ₹${bonusCash.toStringAsFixed(1)}',
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                ),
              ],
            ),
          ),

          if (errorMsg != null) ...[
            const SizedBox(height: 12),
            Text(errorMsg!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () => _generateOfficialRazorpayQr(currentAmount),
              child: Text(
                'PROCEED TO PAY ₹${currentAmount.toInt()}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepQrPayment() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Amount Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amount to Pay', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    Text(
                      '₹${currentAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    '+ ₹${bonusCash.toStringAsFixed(1)} Extra Bonus',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF047857)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Dedicated QR Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'SCAN & PAY VIA ANY UPI APP',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),
                const Text(
                  'PhonePe • Google Pay • Paytm • BHIM • Cred',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                // QR Display Box
                Container(
                  width: 230,
                  height: 230,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                  ),
                  child: isQrLoading
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1D4ED8)),
                            SizedBox(height: 12),
                            Text(
                              'Generating Razorpay QR...',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                            ),
                          ],
                        )
                      : qrImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                qrImageBytes!,
                                width: 220,
                                height: 220,
                                fit: BoxFit.contain,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.qr_code_2, size: 64, color: Colors.grey),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => _generateOfficialRazorpayQr(currentAmount),
                                  child: const Text('Retry QR'),
                                ),
                              ],
                            ),
                ),
                const SizedBox(height: 16),

                // Supported UPI Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildUpiBadge('PhonePe', const Color(0xFF5F259F)),
                    const SizedBox(width: 6),
                    _buildUpiBadge('GPay', const Color(0xFF1A73E8)),
                    const SizedBox(width: 6),
                    _buildUpiBadge('Paytm', const Color(0xFF002970)),
                    const SizedBox(width: 6),
                    _buildUpiBadge('BHIM', const Color(0xFF007A3D)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1-Tap UPI Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _openUpiPayment,
              icon: const Icon(Icons.bolt, color: Colors.amber, size: 20),
              label: Text(
                'PAY VIA UPI APP (₹${currentAmount.toInt()})',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13.5, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Auto-Verification Bar
          InkWell(
            onTap: _manualCheckBalance,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Auto-verifying payment with Razorpay... (Tap to Check)',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Back Button
          TextButton(
            onPressed: () {
              _pollingTimer?.cancel();
              setState(() => _currentStep = 0);
            },
            child: const Text(
              'Change Amount / Go Back',
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiBadge(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        name,
        style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _buildSuccessView() {
    final amt = successData?['amount'] ?? currentAmount;
    final bonus = successData?['bonus'] ?? bonusCash;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Color(0xFF059669), size: 70),
          ),
          const SizedBox(height: 20),
          const Text(
            'Deposit Successful!',
            style: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${amt.toStringAsFixed(2)} added to your deposit balance.',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Deposit Amount:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text('₹${amt.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('10% Bonus Cashback:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    Text('+ ₹${bonus.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Wallet Added:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('₹${(amt + bonus).toStringAsFixed(2)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('BACK TO WALLET', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
