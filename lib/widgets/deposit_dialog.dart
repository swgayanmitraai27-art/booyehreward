import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:js_interop' as js_interop;
import 'dart:js_interop_unsafe' as js_util;
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class DepositDialog extends StatefulWidget {
  final AppState appState;

  const DepositDialog({super.key, required this.appState});

  @override
  State<DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<DepositDialog> {
  final TextEditingController _amountController = TextEditingController(text: '100');
  bool isWaitingForPayment = false;
  String currentCheckoutUrl = '';
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
  double get bonusCash => currentAmount * 0.10; // 10% Extra Deposit Cash

  void _openCheckoutUrl(String url) {
    if (kIsWeb) {
      try {
        final global = js_interop.globalContext;
        if (global.has('openWindowUrl')) {
          global.callMethod('openWindowUrl'.toJS, url.toJS);
          return;
        }
      } catch (e) {
        debugPrint('[DepositDialog] openWindowUrl error: $e');
      }
    }
  }

  void _startPaymentProcess() {
    final amount = currentAmount;
    if (amount < 10) {
      setState(() => errorMsg = 'Minimum deposit amount is ₹10.');
      return;
    }

    final user = widget.appState.user;
    initialDepositCash = user.wallet.depositCash;
    currentCheckoutUrl = 'https://www.swgayanbhumi.in/pay?app=skillwinner&userId=${Uri.encodeComponent(user.uid)}&amount=${amount.toInt()}';

    // 1. Open official registered website checkout tab
    _openCheckoutUrl(currentCheckoutUrl);

    // 2. Set waiting state and start Firestore poller
    setState(() {
      isWaitingForPayment = true;
      errorMsg = null;
    });

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await widget.appState.refreshFromFirestore();
      if (!mounted) {
        timer.cancel();
        return;
      }

      final newBalance = widget.appState.user.wallet.depositCash;
      if (newBalance > initialDepositCash) {
        timer.cancel();
        setState(() {
          isWaitingForPayment = false;
          successData = {
            'addedReal': amount,
            'addedBonus': bonusCash,
            'totalAdded': amount + bonusCash,
            'paymentId': 'VERIFIED_ON_GATEWAY',
          };
        });
      }
    });
  }

  Future<void> _manualCheckBalance() async {
    setState(() {
      errorMsg = null;
    });
    await widget.appState.refreshFromFirestore();
    if (!mounted) return;

    final newBalance = widget.appState.user.wallet.depositCash;
    if (newBalance > initialDepositCash) {
      _pollingTimer?.cancel();
      setState(() {
        isWaitingForPayment = false;
        successData = {
          'addedReal': currentAmount,
          'addedBonus': bonusCash,
          'totalAdded': currentAmount + bonusCash,
          'paymentId': 'VERIFIED_ON_GATEWAY',
        };
      });
    } else {
      setState(() {
        errorMsg = 'Payment not completed yet. Please finish payment in the open browser tab.';
      });
    }
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
                          'SW TECH • OFFICIAL RAZORPAY GATEWAY',
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
                      '₹${(successData!['addedReal'] as num).toInt()} Paid + 10% Extra = ₹${((successData!['addedReal'] as num) * 1.10).toStringAsFixed(1)} Deposit Cash credited successfully.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF047857), fontWeight: FontWeight.w600),
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
            ] else if (isWaitingForPayment) ...[
              // WAITING / IN-PROGRESS VIEW
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF1D4ED8)),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Official Payment Gateway Opened!',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Complete your payment in the opened tab (swgayanbhumi.in). Your balance will update automatically here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF1D4ED8)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _openCheckoutUrl(currentCheckoutUrl),
                            child: const Text('Re-open Page', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D4ED8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _manualCheckBalance,
                            child: const Text('Check Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        _pollingTimer?.cancel();
                        setState(() => isWaitingForPayment = false);
                      },
                      child: const Text('Cancel & Change Amount', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 10% EXTRA DEPOSIT CASH PROMO BANNER
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
                            'SPECIAL 10% EXTRA DEPOSIT CASH!',
                            style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                          ),
                          Text(
                            'Recharge ₹${currentAmount.toInt()} ➔ Get ₹${(currentAmount * 1.10).toStringAsFixed(1)} Deposit Cash in Wallet!',
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

              // PRESET CHIPS (Min ₹10)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [10, 20, 50, 100, 200, 500].map((amt) {
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
                  onPressed: _startPaymentProcess,
                  child: Text(
                    'PAY ₹${currentAmount.toInt()} VIA OFFICIAL GATEWAY',
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
