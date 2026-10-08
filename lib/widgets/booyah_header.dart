import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/url_launcher_util.dart';
import 'deposit_dialog.dart';
import 'withdraw_dialog.dart';
import 'notification_dialog.dart';

class BooyahHeader extends StatelessWidget implements PreferredSizeWidget {
  final AppState appState;
  final Function(int)? onTabChange;

  const BooyahHeader({
    super.key,
    required this.appState,
    this.onTabChange,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final user = appState.user;
    final unreadCount = appState.notifications.length;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: const Color(0xFFE2E8F0),
          height: 1,
        ),
      ),
      titleSpacing: 12,
      title: Row(
        children: [
          // Top Header Branding: BOOYAH_ICON.PNG.png centered/scaled cleanly
          InkWell(
            onTap: () => onTabChange?.call(0),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Image.asset(
                'imgasest/BOOYAH_ICON.PNG.png',
                height: 38,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryAmber,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('B', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('BOOYAH', style: AppTheme.gamingTitle(fontSize: 18)),
                    ],
                  );
                },
              ),
            ),
          ),
          const Spacer(),

          // Wallet Status Chips (Dynamic Review Safe Mode vs Real Cash Mode)
          // 🟡 1. Ad Coins
          InkWell(
            onTap: () => onTabChange?.call(3), // Earn coins tab
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withAlpha(25),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('🟡', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    '${user.wallet.adCoins}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          if (!appState.isRealCashModeEnabled) ...[
            // 🎟️ 2. Reward Coins (Safe Mode)
            InkWell(
              onTap: () => onTabChange?.call(3), // Go to rewards store tab
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFEF3C7)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withAlpha(20),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🎟️', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '${user.wallet.rewardCoins}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF78350F),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // 💵 2. Deposit Cash (Real Cash Mode)
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => DepositDialog(appState: appState),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withAlpha(20),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet, size: 13, color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Text(
                      '₹${user.wallet.depositCash.toInt()}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),

            // 🏆 3. Winning Cash (Real Cash Mode - UPI Withdrawable)
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => WithdrawDialog(appState: appState),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withAlpha(20),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, size: 13, color: Color(0xFF10B981)),
                    const SizedBox(width: 4),
                    Text(
                      '₹${user.wallet.winningCash.toInt()}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(width: 6),

          // 🏆 4. Weekly Leaderboard Quick Button
          InkWell(
            onTap: () => onTabChange?.call(2), // Leaderboard Tab
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withAlpha(30),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.emoji_events, size: 16, color: Color(0xFFD97706)),
            ),
          ),
          const SizedBox(width: 6),

          // 🔔 5. Notifications Bell Icon
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => NotificationDialog(appState: appState),
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const Icon(Icons.notifications_outlined, size: 16, color: Color(0xFF334155)),
                ),
                if (unreadCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE50914),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),

          // 💬 Dynamic Customer Support (Telegram)
          InkWell(
            onTap: () {
              UrlLauncherUtil.openUrl(appState.telegramSupportUrl);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0088CC), Color(0xFF0077B5)],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0088CC).withAlpha(60),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.send, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'SUPPORT',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
