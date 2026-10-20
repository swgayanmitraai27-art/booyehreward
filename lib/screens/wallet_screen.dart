import 'package:flutter/services.dart';
import '../models/voucher_model.dart';
import 'package:flutter/material.dart';
import '../models/withdrawal_model.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/withdraw_dialog.dart';
import 'deposit_screen.dart';
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
                  Text(
                    'My Wallet',
                    style: AppTheme.gamingTitle(fontSize: 22),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 1. 🏆 REAL WINNINGS (₹ RUPAYE) WALLET (ALWAYS VISIBLE & WITHDRAWABLE)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFBEB), Color(0xFFFEF3C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withAlpha(30),
                      blurRadius: 12,
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Row(
                            children: [
                              Text('🏆', style: TextStyle(fontSize: 12)),
                              SizedBox(width: 4),
                              Text(
                                'TOTAL WINNING CASH (ASLI RUPAYE)',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF047857),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            'MIN ₹${widget.appState.minWithdrawalCoins}',
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AVAILABLE WINNINGS',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Free Fire matches jeet kar kamaye gaye rupaye',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                              ),
                            ],
                          ),
                          Text(
                            '₹${wallet.winningCash.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Two Primary Withdrawal Options (UPI & Redeem Code)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF047857),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => WithdrawDialog(appState: widget.appState, initialTab: 0),
                              );
                            },
                            icon: const Text('⚡', style: TextStyle(fontSize: 13)),
                            label: const Text(
                              'UPI WITHDRAWAL',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => WithdrawDialog(appState: widget.appState, initialTab: 1),
                              );
                            },
                            icon: const Text('🎟️', style: TextStyle(fontSize: 13)),
                            label: const Text(
                              'REDEEM CODE',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 10.5, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. FREE TOURNAMENT ENTRY COINS (Ad Coins + Ref Coins)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 8,
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Text('🎮', style: TextStyle(fontSize: 10)),
                              SizedBox(width: 4),
                              Text(
                                'FREE MATCH ENTRY TOKENS',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF334155),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
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
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${wallet.adCoins}',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF78350F)),
                                ),
                                const Text(
                                  'From Watching Ads',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 8.5, color: Color(0xFF94A3B8)),
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
                              color: const Color(0xFFF5F3FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFDDD6FE)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🎁 REF COINS',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF6D28D9)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${wallet.referralCoins}',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF5B21B6)),
                                ),
                                const Text(
                                  'Max 50% Free Match',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 8.5, color: Color(0xFF8B5CF6)),
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
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: widget.onGoToStore,
                        icon: const Icon(Icons.play_circle_fill, size: 16),
                        label: const Text(
                          '📺 ADS DEKHKAR FREE AD COINS LEIN',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (widget.appState.isRealCashModeEnabled) ...[
                const SizedBox(height: 16),

                // 2. REAL DEPOSIT CASH WALLET (Match Entry Only via Razorpay)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF93C5FD)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(15),
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
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: const Row(
                              children: [
                                Text('💵', style: TextStyle(fontSize: 11)),
                                SizedBox(width: 4),
                                Text(
                                  'DEPOSIT CASH',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1D4ED8),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '+10% BONUS',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AVAILABLE BALANCE',
                                  style: TextStyle(fontFamily: 'Inter', fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${wallet.depositCash.toStringAsFixed(2)}',
                                  style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                ),
                                if (wallet.bonusCash > 0)
                                  Text(
                                    '+ ₹${wallet.bonusCash.toStringAsFixed(2)} Bonus Cash Available',
                                    style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D4ED8),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DepositScreen(appState: widget.appState),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 18, color: Colors.white),
                          label: const Text('ADD CASH VIA RAZORPAY UPI (+10% FREE)', style: TextStyle(fontFamily: 'Inter', fontSize: 11.5, fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
                
              ],
              const SizedBox(height: 18),

              // Universal Sub Tabs for Transactions / UPI Requests / Claimed Redeem Codes
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
                            '⚡ All Txns (${widget.appState.transactions.length})',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
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
                            '🏦 UPI (${widget.appState.withdrawals.length})',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: subTab == 1 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => subTab = 2),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: subTab == 2 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: subTab == 2
                                ? [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, 1))]
                                : null,
                          ),
                          child: Text(
                            '🎟️ Codes (${widget.appState.voucherClaims.length})',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: subTab == 2 ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Sub Tab 0: All Transactions
              if (subTab == 0) ...[
                () {
                  final displayTxns = widget.appState.transactions;

                  if (displayTxns.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 36, color: Colors.blueGrey),
                          SizedBox(height: 6),
                          Text(
                            'No transactions recorded yet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Watch ads to get free entries or win tournaments to earn cash.',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayTxns.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (context, index) {
                      final t = displayTxns[index];
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
                  );
                }(),
              ] else if (subTab == 1) ...[
                // Sub Tab 1: UPI Withdrawal Requests
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
                          'Win tournaments and withdraw directly to your UPI (Min ₹100).',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => WithdrawDialog(appState: widget.appState, initialTab: 0),
                            );
                          },
                          icon: const Icon(Icons.account_balance, size: 14, color: AppTheme.primaryAmber),
                          label: const Text('WITHDRAW VIA UPI (₹100+)', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w900)),
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
              ] else if (subTab == 2) ...[
                // Sub Tab 2: Claimed Google Play Redeem Codes
                if (widget.appState.voucherClaims.isEmpty) ...[
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
                        Icon(Icons.confirmation_number_outlined, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text(
                          'No redeem codes claimed yet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Win tournaments and redeem Google Play codes starting from ₹100.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => WithdrawDialog(appState: widget.appState, initialTab: 1),
                            );
                          },
                          icon: const Text('🎟️', style: TextStyle(fontSize: 12)),
                          label: const Text('REDEEM CODE STORE', style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w900)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.appState.voucherClaims.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final claim = widget.appState.voucherClaims[index];
                      final isDelivered = claim.status == VoucherClaimStatus.delivered;
                      final isRejected = claim.status == VoucherClaimStatus.rejected;
                      final isPending = claim.status == VoucherClaimStatus.pending;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDelivered
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
                                        color: isDelivered
                                            ? const Color(0xFFECFDF5)
                                            : isRejected
                                                ? const Color(0xFFFEF2F2)
                                                : const Color(0xFFFFFBEB),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isDelivered
                                            ? Icons.check_circle
                                            : isRejected
                                                ? Icons.cancel
                                                : Icons.access_time,
                                        size: 16,
                                        color: isDelivered
                                            ? AppTheme.winningGreen
                                            : isRejected
                                                ? Colors.red
                                                : Colors.amber.shade800,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          claim.itemTitle,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w900,
                                            fontSize: 13,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        Text(
                                          'Cost: ₹${claim.rewardCoinsSpent} Winning Cash',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDelivered
                                        ? const Color(0xFFECFDF5)
                                        : isRejected
                                            ? const Color(0xFFFEF2F2)
                                            : const Color(0xFFFFFBEB),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDelivered
                                          ? const Color(0xFFA7F3D0)
                                          : isRejected
                                              ? const Color(0xFFFECACA)
                                              : const Color(0xFFFDE68A),
                                    ),
                                  ),
                                  child: Text(
                                    isDelivered
                                        ? 'CODE DELIVERED'
                                        : isRejected
                                            ? 'REJECTED'
                                            : 'PENDING APPROVAL',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: isDelivered
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
                                      const Icon(Icons.phone_android, size: 13, color: Color(0xFF64748B)),
                                      const SizedBox(width: 6),
                                      Text(
                                        'WhatsApp: ${claim.whatsappNumber}',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    DateFormat('dd MMM, hh:mm a').format(claim.requestedAt),
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
                                  Expanded(
                                    child: Text(
                                      'Admin review ke baad aapke WhatsApp aur yahan par code show hoga.',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                                    ),
                                  ),
                                ],
                              ),
                            ] else if (isDelivered && (claim.redeemCode != null && claim.redeemCode!.isNotEmpty)) ...[
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFF93C5FD)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'GOOGLE PLAY REDEEM CODE:',
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8)),
                                          ),
                                          const SizedBox(height: 2),
                                          SelectableText(
                                            claim.redeemCode!,
                                            style: const TextStyle(
                                              fontFamily: 'Courier',
                                              fontSize: 13,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF0F172A),
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1D4ED8),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: claim.redeemCode!));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            backgroundColor: AppTheme.winningGreen,
                                            content: Text('📋 Redeem Code copied! Play Store me paste karein.'),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.copy, size: 13),
                                      label: const Text('COPY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (isRejected) ...[
                              const Row(
                                children: [
                                  Icon(Icons.error_outline, size: 12, color: Colors.red),
                                  SizedBox(width: 4),
                                  Text(
                                    'Request rejected. Refunded to winning wallet.',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red),
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
