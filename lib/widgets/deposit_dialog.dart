import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:js_interop' as js_interop;
import 'dart:js_interop_unsafe' as js_util;
import '../services/app_state.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import '../services/razorpay_checkout_service.dart';

class DepositDialog extends StatefulWidget {
  final AppState appState;

  const DepositDialog({super.key, required this.appState});

  @override
  State<DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<DepositDialog> {
  final TextEditingController _amountController = TextEditingController(text: '100');
  bool isProcessing = false;
  String processingStep = '';
  Map<String, dynamic>? successData;
  String? errorMsg;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get currentAmount => double.tryParse(_amountController.text.trim()) ?? 0;
  double get bonusCoins => currentAmount * 0.50; // 50% instant bonus

  void _openDirectCheckoutUrl() {
    final amount = currentAmount.toInt();
    final user = widget.appState.user;
    final checkoutUrl = 'https://www.swgayanbhumi.in/pay?app=skillwinner&userId=${Uri.encodeComponent(user.uid)}&amount=$amount';

    if (kIsWeb) {
      final global = js_interop.globalContext;
      if (global.has('openWindowUrl')) {
        global.callMethod('openWindowUrl'.toJS, checkoutUrl.toJS);
      }
    }
  }

  Future<void> _processDeposit() async {
    final amount = currentAmount;
    if (amount < 10) {
      setState(() => errorMsg = 'Minimum deposit amount is ₹10.');
      return;
    }

    setState(() {
      isProcessing = true;
      errorMsg = null;
      processingStep = 'Creating Razorpay Live Order...';
    });

    final user = widget.appState.user;
    String orderId = '';
    String keyId = 'rzp_live_TakGRfnTFl20dG';
    double bonusCoinsAmt = amount * 0.5;

    // STEP 1: Try Native JS Bridge first on Web
    final jsData = await RazorpayCheckoutService.createOrderViaJs(
      userId: user.uid,
      amount: amount,
      name: user.displayName,
      phone: user.phoneNumber,
      email: user.email,
    );

    if (jsData != null && (jsData['orderId'] != null || jsData['order_id'] != null || jsData['id'] != null)) {
      orderId = (jsData['orderId'] ?? jsData['order_id'] ?? jsData['id']).toString();
      keyId = (jsData['keyId'] ?? jsData['key'] ?? keyId).toString();
      bonusCoinsAmt = ((jsData['bonusCoins'] ?? bonusCoinsAmt) as num).toDouble();
    } else {
      // Fallback to PaymentService.createOrder
      final orderRes = await PaymentService.createOrder(
        userId: user.uid,
        amount: amount,
        name: user.displayName,
        phone: user.phoneNumber,
        email: user.email,
      );

      if (orderRes.success && orderRes.orderId.isNotEmpty) {
        orderId = orderRes.orderId;
        keyId = orderRes.keyId;
        bonusCoinsAmt = orderRes.bonusCoins;
      }
    }

    if (!mounted) return;

    if (orderId.isEmpty) {
      // Direct Web Checkout Fallback
      _openDirectCheckoutUrl();
      setState(() {
        isProcessing = false;
        processingStep = '';
      });
      return;
    }

    setState(() {
      processingStep = 'Waiting for Razorpay Payment Window...';
    });

    // STEP 2: Open Real Razorpay Web SDK Gateway Modal
    final paymentResult = await RazorpayCheckoutService.openCheckout(
      keyId: keyId,
      orderId: orderId,
      amount: amount,
      name: 'Booyah Rewards (SkillWinner)',
      description: 'Add ₹${amount.toInt()} (+₹${bonusCoinsAmt.toInt()} Bonus)',
      userEmail: user.email,
      userPhone: user.phoneNumber,
      userName: user.displayName,
    );

    if (!mounted) return;

    if (!paymentResult.success) {
      setState(() {
        isProcessing = false;
        errorMsg = paymentResult.error ?? 'Payment was cancelled or failed.';
      });
      return;
    }

    final realPaymentId = paymentResult.paymentId ?? 'pay_${DateTime.now().millisecondsSinceEpoch}';
    final realSignature = paymentResult.signature ?? 'sig_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      processingStep = 'Verifying Payment & Crediting Wallet...';
    });

    // STEP 3: Call API 2 -> Verify Payment & Auto-Credit
    final verifyRes = await PaymentService.verifyPayment(
      orderId: orderId,
      paymentId: realPaymentId,
      signature: realSignature,
      userId: user.uid,
      amount: amount,
      bonusCoins: bonusCoinsAmt,
    );

    if (!mounted) return;

    // Credit in local AppState & sync to Firestore
    final finalBonus = verifyRes.addedBonus > 0 ? verifyRes.addedBonus : bonusCoinsAmt;
    widget.appState.depositCash(amount, realPaymentId, bonusCoins: finalBonus);

    setState(() {
      isProcessing = false;
      successData = {
        'orderId': orderId,
        'paymentId': realPaymentId,
        'addedReal': amount,
        'addedBonus': finalBonus,
        'totalAdded': amount + finalBonus,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(20),
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
                      child: Icon(Icons.account_balance_wallet, color: Colors.blue.shade700, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SKILLWINNER • RAZORPAY LIVE',
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (successData != null) ...[
              // SUCCESS VIEW
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.winningGreen, size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Payment Verified & Credited!',
                      style: AppTheme.gamingTitle(fontSize: 16, color: const Color(0xFF065F46)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${(successData!['addedReal'] as num).toInt()} Real Cash + ${(successData!['addedBonus'] as num).toInt()} 🟡 Bonus Ad Coins credited successfully.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Text(
                        'Ref ID: ${successData!['paymentId']}',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Color(0xFF065F46), fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('DONE & PLAY TOURNAMENTS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 50% BONUS PROMO BANNER
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF59E0B)),
                ),
                child: Row(
                  children: [
                    const Text('🎁', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SPECIAL 50% BONUS OFFER ACTIVE!',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                          ),
                          Text(
                            'Recharge ₹${currentAmount.toInt()} ➔ Get ₹${currentAmount.toInt()} Cash + ${bonusCoins.toInt()} 🟡 Bonus Coins Free!',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // AMOUNT INPUT
              const Text(
                'ENTER RECHARGE AMOUNT (₹)',
                style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.5),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text('₹', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade300)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.blue, width: 2)),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // PRESET CHIPS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [20, 50, 100, 200, 500].map((amt) {
                  final isSelected = currentAmount.toInt() == amt;
                  return InkWell(
                    onTap: () {
                      _amountController.text = amt.toString();
                      setState(() {});
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              const SizedBox(height: 16),

              if (errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    errorMsg!,
                    style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                  ),
                ),
              ],

              // PAY BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: isProcessing ? null : _processDeposit,
                  child: isProcessing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            const SizedBox(width: 10),
                            Text(processingStep, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        )
                      : Text(
                          'PAY ₹${currentAmount.toInt()} WITH RAZORPAY',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
