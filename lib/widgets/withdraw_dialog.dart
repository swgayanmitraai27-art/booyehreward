import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class WithdrawDialog extends StatefulWidget {
  final AppState appState;

  const WithdrawDialog({super.key, required this.appState});

  @override
  State<WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<WithdrawDialog> {
  final TextEditingController _amountController = TextEditingController(text: '100');
  final TextEditingController _upiController = TextEditingController();
  bool isProcessing = false;
  String? errorMsg;
  String? successMsg;

  @override
  void dispose() {
    _amountController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _processWithdrawal() {
    setState(() {
      errorMsg = null;
      successMsg = null;
    });

    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final upiId = _upiController.text.trim();

    if (amount < 50) {
      setState(() => errorMsg = 'Minimum withdrawal amount is ₹50.');
      return;
    }

    if (amount > widget.appState.user.wallet.winningCash) {
      setState(() => errorMsg = 'Insufficient Winning Cash! You have ₹${widget.appState.user.wallet.winningCash.toInt()} available.');
      return;
    }

    if (!upiId.contains('@')) {
      setState(() => errorMsg = 'Please enter a valid UPI ID (e.g. 9876543210@ybl, yourname@oksbi).');
      return;
    }

    setState(() => isProcessing = true);

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      final res = widget.appState.requestWithdrawal(amount, upiId);
      setState(() {
        isProcessing = false;
        if (res['success'] == true) {
          successMsg = res['message'];
        } else {
          errorMsg = res['message'];
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final winningCash = widget.appState.user.wallet.winningCash;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
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
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.currency_rupee, color: AppTheme.winningGreen, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '3-WALLET WITHDRAWAL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: AppTheme.winningGreen,
                          ),
                        ),
                        Text(
                          'Withdraw to UPI',
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
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'WITHDRAWABLE WINNINGS',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF166534)),
                      ),
                      Text(
                        'Won from paid matches only',
                        style: TextStyle(fontSize: 9.5, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                  Text(
                    '₹${winningCash.toInt()}',
                    style: AppTheme.gamingNumber(fontSize: 20, color: const Color(0xFF166534)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            if (successMsg != null) ...[
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
                      'Withdrawal Request Submitted!',
                      style: AppTheme.gamingTitle(fontSize: 16, color: const Color(0xFF065F46)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule, size: 14, color: Color(0xFF059669)),
                          SizedBox(width: 6),
                          Text(
                            '24 Hours Ke Andar Transfer to your UPI',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Amount deducted immediately from wallet. Live payout status is updated below in your 4-Wallet history.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK & VIEW STATUS'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text(
                'WITHDRAWAL AMOUNT (MIN ₹50)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: AppTheme.gamingNumber(fontSize: 18),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text('₹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'ENTER UPI ID / PHONEPE NUMBER',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _upiController,
                decoration: InputDecoration(
                  hintText: 'e.g. 9876543210@ybl or user@oksbi',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),

              if (errorMsg != null) ...[
                const SizedBox(height: 10),
                Text(
                  errorMsg!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: winningCash >= 50 ? AppTheme.winningGreen : Colors.grey.shade300,
                    foregroundColor: winningCash >= 50 ? Colors.white : Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: (winningCash >= 50 && !isProcessing) ? _processWithdrawal : null,
                  child: isProcessing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            SizedBox(width: 8),
                            Text('SUBMITTING...'),
                          ],
                        )
                      : Text(
                          'SUBMIT WITHDRAWAL (₹${_amountController.text})',
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
