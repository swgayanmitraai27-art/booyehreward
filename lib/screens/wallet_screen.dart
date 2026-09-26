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

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
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
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${wallet.depositCash.toInt()}',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                ),
                                const Text(
                                  'Entry for Paid Matches',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: Color(0xFF64748B)),
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
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🏆 WINNING CASH',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${wallet.winningCash.toInt()}',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                                ),
                                const Text(
                                  '100% UPI Withdrawable',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
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
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.appState.withdrawals.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final w = widget.appState.withdrawals[index];

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₹${w.amount.toInt()} Payout', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w900, fontSize: 13)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: w.status == WithdrawalStatus.completed
                                  ? const Color(0xFFECFDF5)
                                  : w.status == WithdrawalStatus.rejected
                                      ? Colors.red.shade100
                                      : Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              w.status.name.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: w.status == WithdrawalStatus.completed
                                    ? const Color(0xFF065F46)
                                    : w.status == WithdrawalStatus.rejected
                                        ? Colors.red.shade900
                                        : Colors.amber.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('UPI ID: ${w.upiId}', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600)),
                          if (w.adminNotes != null)
                            Text('Note: ${w.adminNotes}', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
