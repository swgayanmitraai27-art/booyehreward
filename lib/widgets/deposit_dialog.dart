import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/app_state.dart';
import '../utils/url_launcher_util.dart';

class DepositDialog extends StatefulWidget {
  final AppState appState;

  const DepositDialog({super.key, required this.appState});

  @override
  State<DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<DepositDialog> {
  final TextEditingController _amountController = TextEditingController(text: '50');

  int _currentStep = 0; // 0: Select Amount, 1: Dedicated QR & UPI Screen
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

        // 2. Check Wallet balance sync directly
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
      // Fallback direct UPI URI
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
          content: Text('Checking with bank/Razorpay... Balance will update automatically once verified.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (successData != null) {
      return _buildSuccessDialog();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 500 ? 440.0 : screenWidth * 0.95;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: _currentStep == 0 ? _buildAmountSelectionStep() : _buildDedicatedQrStep(),
      ),
    );
  }

  // STEP 1: Select Amount & Bonus Breakdown
  Widget _buildAmountSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet, color: Color(0xFF1D4ED8), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ADD REAL CASH',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 0.5),
                      ),
                      Text(
                        'Instant Razorpay UPI Deposit',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 10% Extra Cashback Highlight Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF59E0B), width: 1),
            ),
            child: const Row(
              children: [
                Text('🎁', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '10% EXTRA BONUS CASH on every deposit! Use for Paid Match entries.',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF78350F)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Amount Input Box
          const Text(
            'SELECT OR ENTER RECHARGE AMOUNT',
            style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.8),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            ),
            child: Row(
              children: [
                const Text('₹', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    decoration: const InputDecoration(
                      hintText: 'Enter amount (Min ₹10)',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Presets Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [20, 50, 100, 200, 500, 1000].map((amt) {
              final isSelected = currentAmount.toInt() == amt;
              return InkWell(
                onTap: () {
                  _amountController.text = amt.toString();
                  setState(() {});
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    '₹$amt',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Total Playable Breakdown Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Deposit Cash (₹):', style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF64748B))),
                    Text('₹${currentAmount.toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🎁 Free Bonus Cash (+10%):', style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                    Text('+ ₹${bonusCash.toStringAsFixed(1)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF059669))),
                  ],
                ),
                const Divider(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Playable Balance:', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                    Text('₹${totalPlayableCash.toStringAsFixed(1)}', style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (errorMsg != null) ...[
            Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
          ],

          // Continue Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () => _generateOfficialRazorpayQr(currentAmount),
              child: Text(
                'CONTINUE TO PAY ₹${currentAmount.toInt()}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 2: Dedicated Full-Screen Razorpay QR & 1-Tap UPI Apps
  Widget _buildDedicatedQrStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 20),
                onPressed: () {
                  _pollingTimer?.cancel();
                  setState(() => _currentStep = 0);
                },
              ),
              const Column(
                children: [
                  Text('SCAN & PAY (OFFICIAL RAZORPAY)', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  Text('All UPI Apps Supported (0% Fee)', style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Amount Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Text(
              'PAYING: ₹${currentAmount.toInt()} (+ ₹${bonusCash.toStringAsFixed(1)} Extra Bonus)',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8)),
            ),
          ),
          const SizedBox(height: 14),

          // Full Razorpay QR Box
          Container(
            width: 240,
            height: 240,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF93C5FD), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withAlpha(25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isQrLoading || qrImageBytes == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF1D4ED8), strokeWidth: 3),
                      const SizedBox(height: 12),
                      Text(
                        'Generating Official QR for ₹${currentAmount.toInt()}...',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      qrImageBytes!,
                      fit: BoxFit.contain,
                      width: 216,
                      height: 216,
                    ),
                  ),
          ),
          const SizedBox(height: 14),

          // Supported UPI Apps Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUpiAppBadge('PhonePe', const Color(0xFF5F259F)),
              const SizedBox(width: 8),
              _buildUpiAppBadge('GPay', const Color(0xFF1A73E8)),
              const SizedBox(width: 8),
              _buildUpiAppBadge('Paytm', const Color(0xFF00B9F1)),
              const SizedBox(width: 8),
              _buildUpiAppBadge('BHIM', const Color(0xFFF37021)),
            ],
          ),
          const SizedBox(height: 16),

          // 1-Tap Pay via Installed UPI App Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.flash_on, color: Colors.amber, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D4ED8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _openUpiPayment,
              label: Text(
                'PAY VIA UPI APP (₹${currentAmount.toInt()})',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Live Polling Status / Refresh Button
          InkWell(
            onTap: _manualCheckBalance,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Auto-verifying payment... (Tap to Refresh)',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                  ),
                ],
              ),
            ),
          ),

          if (errorMsg != null) ...[
            const SizedBox(height: 8),
            Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildUpiAppBadge(String name, Color color) {
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

  // SUCCESS CELEBRATION
  Widget _buildSuccessDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFD1FAE5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF059669), size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'PAYMENT SUCCESSFUL!',
              style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
            ),
            const SizedBox(height: 6),
            Text(
              '₹${successData?['amount'] ?? currentAmount} successfully added to your Deposit Cash wallet!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '🎁 + ₹${(successData?['bonus'] ?? bonusCash).toStringAsFixed(1)} Bonus Cash Credited!',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('GREAT, LET\'S PLAY!', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
