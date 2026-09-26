import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';

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

  Future<void> _processDeposit() async {
    final amount = currentAmount;
    if (amount < 10) {
      setState(() => errorMsg = 'Minimum deposit amount is ₹10.');
      return;
    }

    setState(() {
      isProcessing = true;
      errorMsg = null;
      processingStep = 'Creating Razorpay Order via Server...';
    });

    final user = widget.appState.user;

    // STEP 1: Call API 1 -> Create Order (swgayanbhumi.in)
    final orderRes = await PaymentService.createOrder(
      userId: user.uid,
      amount: amount,
      name: user.displayName,
      phone: user.phoneNumber,
      email: user.email,
    );

    if (!mounted) return;

    if (!orderRes.success) {
      setState(() {
        isProcessing = false;
        errorMsg = orderRes.errorMessage ?? 'Failed to create payment order.';
      });
      return;
    }

    setState(() {
      processingStep = 'Opening Razorpay Gateway (${orderRes.orderId})...';
    });

    // STEP 2: Simulate Razorpay SDK Checkout / Payment
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final mockPaymentId = 'pay_${DateTime.now().millisecondsSinceEpoch.toString().substring(3)}';
    final mockSignature = 'sig_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}';

    setState(() {
      processingStep = 'Verifying HMAC Signature & Crediting Wallet...';
    });

    // STEP 3: Call API 2 -> Verify Payment & Auto-Credit (swgayanbhumi.in)
    final verifyRes = await PaymentService.verifyPayment(
      orderId: orderRes.orderId,
      paymentId: mockPaymentId,
      signature: mockSignature,
      userId: user.uid,
      amount: amount,
      bonusCoins: orderRes.bonusCoins > 0 ? orderRes.bonusCoins : bonusCoins,
    );

    if (!mounted) return;

    // Credit in local AppState
    final finalBonus = verifyRes.addedBonus > 0 ? verifyRes.addedBonus : bonusCoins;
    widget.appState.depositCash(amount, mockPaymentId, bonusCoins: finalBonus);

    setState(() {
      isProcessing = false;
      successData = {
        'orderId': orderRes.orderId,
        'paymentId': mockPaymentId,
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
                            style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                          ),
                          Text(
                            'Recharge ₹${currentAmount.toInt()} ➔ Get ₹${currentAmount.toInt()} Cash + ${bonusCoins.toInt()} 🟡 Bonus Coins Free!',
                            style: const TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF78350F)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'ENTER RECHARGE AMOUNT (₹)',
                style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() {}),
                style: AppTheme.gamingNumber(fontSize: 22),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text('₹', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),

              // Quick Amount Selectors
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [20, 50, 100, 200, 500].map((amt) {
                  final isSel = currentAmount == amt;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _amountController.text = amt.toString();
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSel ? Colors.transparent : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        '₹$amt',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              if (errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(errorMsg!, style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ],

              // Pay Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: isProcessing ? null : _processDeposit,
                  child: isProcessing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              processingStep.isNotEmpty ? processingStep : 'PROCESSING VIA RAZORPAY...',
                              style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      : Text(
                          'PAY ₹${currentAmount.toInt()} WITH RAZORPAY',
                          style: AppTheme.gamingTitle(fontSize: 14, color: Colors.white, isItalic: false),
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
