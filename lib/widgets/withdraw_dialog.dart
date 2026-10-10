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
  late TextEditingController _coinsController;
  final TextEditingController _upiController = TextEditingController();
  bool isProcessing = false;
  String? errorMsg;
  String? successMsg;

  @override
  void initState() {
    super.initState();
    _coinsController = TextEditingController(text: '${widget.appState.minWithdrawalCoins}');
  }

  @override
  void dispose() {
    _coinsController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _processWithdrawal() {
    setState(() {
      errorMsg = null;
      successMsg = null;
    });

    final coins = double.tryParse(_coinsController.text.trim()) ?? 0;
    final upiId = _upiController.text.trim();
    final minCoins = widget.appState.minWithdrawalCoins;
    final rate = widget.appState.coinToRupeeRate;

    if (coins < minCoins) {
      setState(() => errorMsg = 'Minimum withdrawal limit is $minCoins 🪙 Winning Coins (₹${(minCoins * rate).toStringAsFixed(1)}).');
      return;
    }

    if (coins > widget.appState.user.wallet.winningCash) {
      setState(() => errorMsg = 'Insufficient Winning Coins! You have ${widget.appState.user.wallet.winningCash.toInt()} 🪙 available.');
      return;
    }

    if (!upiId.contains('@')) {
      setState(() => errorMsg = 'Please enter a valid UPI ID (e.g. 9876543210@ybl, yourname@oksbi).');
      return;
    }

    setState(() => isProcessing = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final res = widget.appState.requestWithdrawal(coins, upiId);
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
    final winningCoins = widget.appState.user.wallet.winningCash;
    final rate = widget.appState.coinToRupeeRate;
    final minCoins = widget.appState.minWithdrawalCoins;
    final enteredCoins = double.tryParse(_coinsController.text.trim()) ?? 0;
    final calculatedPayout = enteredCoins * rate;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('🪙', style: TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WINNING COINS REDEMPTION',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        Text(
                          'Withdraw to UPI Cash',
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

            // Available Winning Coins Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AVAILABLE WINNING COINS',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '1 Coin = ₹${rate.toStringAsFixed(2)} Cash (1000 Coins = ₹${(1000 * rate).toInt()})',
                        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                  Text(
                    '🪙 ${winningCoins.toInt()}',
                    style: AppTheme.gamingNumber(fontSize: 18, color: const Color(0xFF78350F)),
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
                            '24 Hours Ke Andar Direct UPI Transfer',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      successMsg!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF065F46), fontWeight: FontWeight.w600),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'COINS TO WITHDRAW (MIN $minCoins COINS)',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _coinsController.text = '${winningCoins.toInt()}';
                      });
                    },
                    child: const Text('Withdraw Max', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFFD97706))),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _coinsController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                style: AppTheme.gamingNumber(fontSize: 18),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text('🪙', style: TextStyle(fontSize: 18)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 6),

              // Quick Coin Presets
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      label: const Text('1,000 Coins', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      onPressed: () => setState(() => _coinsController.text = '1000'),
                    ),
                    const SizedBox(width: 4),
                    ActionChip(
                      label: const Text('2,000 Coins', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      onPressed: () => setState(() => _coinsController.text = '2000'),
                    ),
                    const SizedBox(width: 4),
                    ActionChip(
                      label: const Text('5,000 Coins', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      onPressed: () => setState(() => _coinsController.text = '5000'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Calculated Real Cash Payout Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'You Will Receive in UPI:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                    ),
                    Text(
                      '₹${calculatedPayout.toStringAsFixed(2)}',
                      style: AppTheme.gamingNumber(fontSize: 16, color: const Color(0xFF047857)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'ENTER UPI ID / PHONEPE NUMBER',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF475569)),
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
                    backgroundColor: (winningCoins >= minCoins && enteredCoins >= minCoins) ? AppTheme.winningGreen : Colors.grey.shade300,
                    foregroundColor: (winningCoins >= minCoins && enteredCoins >= minCoins) ? Colors.white : Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: (winningCoins >= minCoins && enteredCoins >= minCoins && !isProcessing) ? _processWithdrawal : null,
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
                          'SUBMIT WITHDRAWAL (₹${calculatedPayout.toStringAsFixed(1)})',
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
