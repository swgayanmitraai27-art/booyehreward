import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/daily_task_model.dart';
import '../services/app_state.dart';
import '../services/ad_service.dart';
import '../theme/app_theme.dart';

class DailyTasksWidget extends StatelessWidget {
  final AppState appState;
  final VoidCallback? onWatchAdClick;
  final VoidCallback? onBrowseMatchesClick;

  const DailyTasksWidget({
    super.key,
    required this.appState,
    this.onWatchAdClick,
    this.onBrowseMatchesClick,
  });

  @override
  Widget build(BuildContext context) {
    final taskData = appState.dailyTaskData;
    taskData.checkAndResetForNewDay();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 📅 14-DAY DAILY CHECK-IN HERO CARD
        _buildDailyCheckInCard(context, taskData),

        const SizedBox(height: 18),

        // 2. 🎯 DAILY MISSIONS HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryAmber.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.stars, color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY MISSIONS',
                      style: AppTheme.gamingTitle(fontSize: 16, color: const Color(0xFF0F172A)),
                    ),
                    const Text(
                      'Daily tasks complete karein aur Free Coins kamayein',
                      style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.autorenew, color: Colors.amber, size: 12),
                  SizedBox(width: 4),
                  Text('Daily Reset 12 AM', style: TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // DAILY MISSIONS LIST (ADS, MATCHES, SHARING)
        ...DailyTasksCatalog.dailyMissions
            .where((task) => task.id != 'task_daily_login')
            .map((task) => _buildTaskCard(context, task, taskData)),

        const SizedBox(height: 14),

        // 3. 🔥 STREAK MILESTONES HEADER (3, 7, 14 DAYS)
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.deepOrange.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_fire_department, color: Colors.deepOrangeAccent, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STREAK MILESTONES',
                  style: AppTheme.gamingTitle(fontSize: 16, color: const Color(0xFF0F172A)),
                ),
                const Text(
                  'Lagatar login streak banayein aur extra bonus jeetein',
                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // STREAK MILESTONES LIST
        ...DailyTasksCatalog.streakMilestoneTasks
            .map((task) => _buildTaskCard(context, task, taskData)),
      ],
    );
  }

  // --- 📅 14-DAY STREAK CHECK-IN CARD ---
  Widget _buildDailyCheckInCard(BuildContext context, UserDailyTaskData taskData) {
    final todayReward = taskData.getTodayCheckInReward();
    final hasCheckedIn = taskData.hasCheckedInToday;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('📅', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAILY CHECK-IN BONUS',
                        style: AppTheme.gamingTitle(fontSize: 14, color: Colors.amber),
                      ),
                      Text(
                        'Streak: Day ${taskData.checkInStreak} of 14 • Free Coins Daily',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber, width: 1),
                ),
                child: Text(
                  'Day ${taskData.checkInStreak}/14',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.amber),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Milestone summary callout
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Text('🌟', style: TextStyle(fontSize: 12)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Day 3: +2 🪙 • Day 7: +3 🪙 • Day 14: +5 🪙 Jackpot!',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFFDE68A)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 14 Days Visual (2 Rows of 7)
          _buildDayCardsRow(1, 7, taskData, hasCheckedIn),
          const SizedBox(height: 6),
          _buildDayCardsRow(8, 14, taskData, hasCheckedIn),

          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: hasCheckedIn ? const Color(0xFF334155) : const Color(0xFFF59E0B),
                foregroundColor: hasCheckedIn ? const Color(0xFF94A3B8) : Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: hasCheckedIn ? 0 : 3,
              ),
              onPressed: hasCheckedIn
                  ? null
                  : () {
                      final res = appState.claimDailyCheckIn();
                      AdService.showInterstitialAd(context: context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFF065F46),
                          content: Text(res['message'] ?? 'Claimed successfully!'),
                        ),
                      );
                    },
              icon: Icon(hasCheckedIn ? Icons.check_circle : Icons.card_giftcard, size: 18),
              label: Text(
                hasCheckedIn
                    ? 'TODAY CLAIMED ✅ (Come back tomorrow for Day ${taskData.checkInStreak < 14 ? taskData.checkInStreak + 1 : 1})'
                    : 'CLAIM TODAY\'S LOGIN BONUS (+$todayReward COIN)',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCardsRow(int startDay, int endDay, UserDailyTaskData taskData, bool hasCheckedIn) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (endDay - startDay) + 1;
        final itemWidth = (constraints.maxWidth - ((count - 1) * 5)) / count;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (i) {
            final dayNum = startDay + i;
            final isPast = dayNum < taskData.checkInStreak || (dayNum == taskData.checkInStreak && hasCheckedIn);
            final isToday = dayNum == taskData.checkInStreak && !hasCheckedIn;
            final dayCoins = UserDailyTaskData.getRewardForDay(dayNum);
            final isMilestone = dayNum == 3 || dayNum == 7 || dayNum == 14;

            return Container(
              width: itemWidth,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isToday
                    ? Colors.amber.withAlpha(45)
                    : (isPast
                        ? const Color(0xFF065F46)
                        : (isMilestone ? const Color(0xFF3B2E05) : Colors.white.withAlpha(10))),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isToday
                      ? Colors.amber
                      : (isPast
                          ? const Color(0xFF10B981)
                          : (isMilestone ? Colors.amber.withAlpha(120) : Colors.white12)),
                  width: isToday ? 1.5 : (isMilestone ? 1.2 : 0.8),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'D$dayNum',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      color: isToday
                          ? Colors.amber
                          : (isPast
                              ? const Color(0xFF6EE7B7)
                              : (isMilestone ? const Color(0xFFFDE68A) : Colors.grey)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dayNum == 14 ? '👑' : (dayNum == 7 ? '🏆' : (dayNum == 3 ? '🌟' : '🪙')),
                    style: TextStyle(fontSize: isMilestone ? 12 : 10),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '+$dayCoins',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: isToday ? Colors.amber : Colors.white,
                    ),
                  ),
                  if (isPast) ...[
                    const SizedBox(height: 1),
                    const Icon(Icons.check_circle, size: 9, color: Color(0xFF10B981)),
                  ],
                ],
              ),
            );
          }),
        );
      },
    );
  }

  // --- 🎯 MISSION CARD WIDGET ---
  Widget _buildTaskCard(BuildContext context, DailyTaskItem task, UserDailyTaskData taskData) {
    final progress = task.getProgress(taskData);
    final target = task.targetCount;
    final isDone = task.isCompleted(taskData);
    final isClaimed = task.isClaimed(taskData);
    final canClaim = task.canClaim(taskData);
    final double percent = (progress / target).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canClaim ? Colors.amber : const Color(0xFFE2E8F0),
          width: canClaim ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: canClaim ? Colors.amber.withAlpha(20) : Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(task.iconEmoji, style: const TextStyle(fontSize: 20)),
          ),

          const SizedBox(width: 12),

          // Title & Progress Bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withAlpha(40),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade700, width: 0.8),
                      ),
                      child: Text(
                        '+${task.rewardCoins} 🪙 Coins',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  task.description,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Progress Indicator Row
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDone ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$progress/$target',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isDone ? const Color(0xFF059669) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Action Button
          _buildTaskActionButton(context, task, taskData, canClaim, isClaimed),
        ],
      ),
    );
  }

  Widget _buildTaskActionButton(
    BuildContext context,
    DailyTaskItem task,
    UserDailyTaskData taskData,
    bool canClaim,
    bool isClaimed,
  ) {
    if (isClaimed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
            SizedBox(width: 4),
            Text('CLAIMED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B))),
          ],
        ),
      );
    }

    if (canClaim) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 2,
        ),
        onPressed: () {
          final res = appState.claimDailyTaskReward(task.id);
          AdService.showInterstitialAd(context: context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF065F46),
              content: Text(res['message'] ?? 'Reward claimed!'),
            ),
          );
        },
        child: const Text('CLAIM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
      );
    }

    // Task in progress -> "GO" button to action
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF0F172A),
        side: const BorderSide(color: Color(0xFF0F172A), width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () {
        switch (task.actionRoute) {
          case 'WATCH_ADS':
            if (onWatchAdClick != null) onWatchAdClick!();
            break;
          case 'MATCHES':
            if (onBrowseMatchesClick != null) onBrowseMatchesClick!();
            break;
          case 'SHARE':
            Clipboard.setData(ClipboardData(text: appState.user.referralCode));
            appState.recordReferralShareForTasks();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF065F46),
                content: Text('Referral Code (${appState.user.referralCode}) copied! Share with your friends!'),
              ),
            );
            break;
          default:
            break;
        }
      },
      child: const Text('START', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
    );
  }
}
