import 'package:flutter/material.dart';
import '../models/withdrawal_model.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/deposit_dialog.dart';
import '../widgets/withdraw_dialog.dart';
import '../widgets/ff_brand_elements.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback onGoToStore;

  const WalletScreen({
    super.key,
    required this.appState,
    required this.onGoToStore,
  });

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int subTab = 0;

  @override
  Widget build(BuildContext context) {
    final user = widget.appState.user;
    final wallet = user.wallet;

    return Stack(
      children: [
        // Subtle FF Short Logo Watermark in Background
        Positioned(
          right: -30,
          top: 40,
          child: const FfWatermark(size: 220, opacity: 0.04, angle: 0.15),
        ),
        Positioned(
          left: -40,
          bottom: 80,
          child: const FfWatermark(size: 240, opacity: 0.03, angle: -0.2),
        ),

        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DUAL ECONOMY LEDGER',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF64748B),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '4-Wallet Balance & Payouts',
                        style: AppTheme.gamingTitle(fontSize: 20),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        Image.asset('imgasest/FF_SHORT_LOGO.PNG.png', width: 14, height: 14),
                        const SizedBox(width: 4),
                        const Text(
                          'ZERO-LOSS ACTIVE',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 1. FREE-TO-PLAY WALLET (Ad-Based / Non-Cash)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withAlpha(25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            children: [
                              Text('🎮', style: TextStyle(fontSize: 10)),
                              SizedBox(width: 4),
                              Text(
                                'FREE-TO-PLAY ECONOMY',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF92400E),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Ad-Supported • Store Redemptions',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFEF3C7)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🟡 AD COINS',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${wallet.adCoins}',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
                                ),
                                const Text(
                                  'Entry for Free Matches',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFEF3C7)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🎟️ REWARD COINS',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${wallet.rewardCoins}',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
                                ),
                                const Text(
                                  'Free Match Winnings',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryAmber,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: widget.onGoToStore,
                        icon: const Text('🎁', style: TextStyle(fontSize: 14)),
                        label: const Text(
                          'REDEEM GOOGLE PLAY & DIAMOND CODES',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. PRO REAL MONEY WALLET (Paid Esports)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Row(
                            children: [
                              Text('💎', style: TextStyle(fontSize: 10)),
                              SizedBox(width: 4),
                              Text(
                                'PRO REAL CASH ECONOMY',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF065F46),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Real Money • Instant UPI Payouts',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.winningGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3-Card Real & Promotional Economy (Bonus Cash, Deposit Cash, Winning Cash)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7).withAlpha(100),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🎁 BONUS CASH',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${wallet.bonusCash.toStringAsFixed(1)}',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                                ),
                                const Text(
                                  '10% Cashback (Used 1st)',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 8, color: Color(0xFF92400E)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '💵 DEPOSIT CASH',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${wallet.depositCash.toInt()}',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                ),
                                const Text(
                                  'Match Entry Only',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 8, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🏆 WINNINGS',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${wallet.winningCash.toInt()}',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                                ),
                                const Text(
                                  '100% Withdrawable',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => DepositDialog(appState: widget.appState),
                              );
                            },
                            icon: const Icon(Icons.add_card, size: 16),
                            label: const Text('+ ADD CASH', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => WithdrawDialog(appState: widget.appState),
                              );
                            },
                            icon: const Icon(Icons.account_balance, size: 16, color: AppTheme.primaryAmber),
                            label: const Text('WITHDRAW (UPI)', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Sub Tabs for Transactions / UPI Requests
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => subTab = 0),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: subTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: subTab == 0
                                ? [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, 1))]
                                : null,
                          ),
                          child: Text(
                            'Transactions (${widget.appState.transactions.length})',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: subTab == 0 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => subTab = 1),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: subTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: subTab == 1
                                ? [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, 1))]
                                : null,
                          ),
                          child: Text(
                            'UPI Requests (${widget.appState.withdrawals.length})',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: subTab == 1 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Transaction / Withdrawal List
              if (subTab == 0) ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.appState.transactions.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final t = widget.appState.transactions[index];
                    final isCredit = t.amount > 0;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: CircleAvatar(
                        backgroundColor: isCredit ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isCredit ? AppTheme.winningGreen : Colors.red,
                          size: 18,
                        ),
                      ),
                      title: Text(t.description, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${DateFormat('dd MMM, hh:mm a').format(t.createdAt)} • ${t.walletAffected.name.toUpperCase()}',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.grey),
                      ),
                      trailing: Text(
                        isCredit
                            ? '+${t.currency == 'INR' ? '₹' : ''}${t.amount.toInt()} ${t.currency == 'INR' ? '' : t.currency}'
                            : '${t.currency == 'INR' ? '₹' : ''}${t.amount.toInt()} ${t.currency == 'INR' ? '' : t.currency}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isCredit ? AppTheme.winningGreen : const Color(0xFF0F172A),
                        ),
                      ),
                    );
                  },
                ),
              ] else ...[
                if (widget.appState.withdrawals.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text(
                          'No UPI withdrawal requests yet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Win paid tournaments and withdraw directly to your UPI (Min ₹50).',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.appState.withdrawals.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final w = widget.appState.withdrawals[index];

                      final isCompleted = w.status == WithdrawalStatus.completed;
                      final isRejected = w.status == WithdrawalStatus.rejected;
                      final isPending = w.status == WithdrawalStatus.pending;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCompleted
                                ? const Color(0xFFA7F3D0)
                                : isRejected
                                    ? const Color(0xFFFECACA)
                                    : const Color(0xFFFDE68A),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(8),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? const Color(0xFFECFDF5)
                                            : isRejected
                                                ? const Color(0xFFFEF2F2)
                                                : const Color(0xFFFFFBEB),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isCompleted
                                            ? Icons.check_circle
                                            : isRejected
                                                ? Icons.cancel
                                                : Icons.access_time,
                                        size: 16,
                                        color: isCompleted
                                            ? AppTheme.winningGreen
                                            : isRejected
                                                ? Colors.red
                                                : Colors.amber.shade800,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '₹${w.amount.toInt()} UPI Payout',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? const Color(0xFFECFDF5)
                                        : isRejected
                                            ? const Color(0xFFFEF2F2)
                                            : const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isCompleted
                                          ? const Color(0xFFA7F3D0)
                                          : isRejected
                                              ? const Color(0xFFFECACA)
                                              : const Color(0xFFFDE68A),
                                    ),
                                  ),
                                  child: Text(
                                    isCompleted
                                        ? 'APPROVED / PAID'
                                        : isRejected
                                            ? 'REJECTED'
                                            : 'IN REVIEW (24H)',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: isCompleted
                                          ? const Color(0xFF065F46)
                                          : isRejected
                                              ? Colors.red.shade900
                                              : const Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.account_balance, size: 13, color: Color(0xFF64748B)),
                                      const SizedBox(width: 6),
                                      Text(
                                        w.upiId,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    DateFormat('dd MMM, hh:mm a').format(w.requestedAt),
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (isPending) ...[
                              const Row(
                                children: [
                                  Icon(Icons.info_outline, size: 12, color: Color(0xFFD97706)),
                                  SizedBox(width: 4),
                                  Text(
                                    '24 Hours ke andar aapke UPI account par transfer ho jayega.',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                                  ),
                                ],
                              ),
                            ] else if (isCompleted) ...[
                              Row(
                                children: [
                                  const Icon(Icons.verified, size: 12, color: AppTheme.winningGreen),
                                  SizedBox(width: 4),
                                  Text(
                                    'Payment Transferred! Ref: ${w.payoutTxnRef ?? "UTR Success"}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                                  ),
                                ],
                              ),
                            ] else if (isRejected) ...[
                              Row(
                                children: [
                                  const Icon(Icons.error_outline, size: 12, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Refunded to Wallet. Note: ${w.adminNotes ?? "Invalid UPI"}',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
