import 'package:flutter/material.dart';
import '../models/daily_task_model.dart';
import '../services/app_state.dart';
import '../services/ad_service.dart';

class DailyLoginPopupDialog extends StatefulWidget {
  final AppState appState;
  final VoidCallback? onNavigateToEarn;

  const DailyLoginPopupDialog({
    super.key,
    required this.appState,
    this.onNavigateToEarn,
  });

  static Future<void> show(BuildContext context, AppState appState, {VoidCallback? onNavigateToEarn}) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DailyLoginPopupDialog(
        appState: appState,
        onNavigateToEarn: onNavigateToEarn,
      ),
    );
  }

  @override
  State<DailyLoginPopupDialog> createState() => _DailyLoginPopupDialogState();
}

class _DailyLoginPopupDialogState extends State<DailyLoginPopupDialog> {
  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final taskData = appState.dailyTaskData;
    taskData.checkAndResetForNewDay();
    final hasCheckedIn = taskData.hasCheckedInToday;
    final todayReward = taskData.getTodayCheckInReward();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF59E0B), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withAlpha(50),
              blurRadius: 25,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row with Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber, width: 1.2),
                        ),
                        child: const Text('🎁', style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DAILY LOGIN REWARDS',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.amber,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.local_fire_department, color: Colors.deepOrangeAccent, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                'Streak: Day ${taskData.checkInStreak} of 14',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Streak Callout Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Text('🌟', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Day 3: +2 🪙 • Day 7: +3 🪙 • Day 14: +5 🪙 Jackpot!',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFDE68A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 14-Day Calendar (Two Rows of 7)
              _buildCalendarGrid(taskData, hasCheckedIn),

              const SizedBox(height: 16),

              // Big Claim Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasCheckedIn ? const Color(0xFF334155) : const Color(0xFFF59E0B),
                    foregroundColor: hasCheckedIn ? const Color(0xFF94A3B8) : Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: hasCheckedIn ? 0 : 5,
                  ),
                  onPressed: hasCheckedIn
                      ? null
                      : () {
                          final res = appState.claimDailyCheckIn();
                          AdService.showInterstitialAd(context: context);
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF065F46),
                              content: Text(res['message'] ?? 'Claimed successfully!'),
                            ),
                          );
                        },
                  icon: Icon(hasCheckedIn ? Icons.check_circle : Icons.card_giftcard, size: 20),
                  label: Text(
                    hasCheckedIn
                        ? 'DAY ${taskData.checkInStreak} CLAIMED ✅'
                        : 'CLAIM DAY ${taskData.checkInStreak} BONUS (+$todayReward 🪙)',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Quick Missions Progress
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TODAY\'S ACTIVE MISSIONS & STREAKS',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.amber),
                    ),
                    const SizedBox(height: 8),
                    _buildQuickMissionProgress(
                      icon: '🔥',
                      label: '3-Day Login Streak',
                      current: taskData.checkInStreak >= 3 ? 3 : taskData.checkInStreak,
                      target: 3,
                      reward: '+1 🪙',
                    ),
                    const SizedBox(height: 6),
                    _buildQuickMissionProgress(
                      icon: '🏆',
                      label: '7-Day Champion Streak',
                      current: taskData.checkInStreak >= 7 ? 7 : taskData.checkInStreak,
                      target: 7,
                      reward: '+2 🪙',
                    ),
                    const SizedBox(height: 6),
                    _buildQuickMissionProgress(
                      icon: '📺',
                      label: 'Watch 3 Video Ads',
                      current: taskData.adsWatchedToday >= 3 ? 3 : taskData.adsWatchedToday,
                      target: 3,
                      reward: '+1 🪙',
                    ),
                    const SizedBox(height: 6),
                    _buildQuickMissionProgress(
                      icon: '💎',
                      label: 'Watch 30 Ads Mega Task',
                      current: taskData.adsWatchedToday >= 30 ? 30 : taskData.adsWatchedToday,
                      target: 30,
                      reward: '+5 🪙',
                    ),
                    const SizedBox(height: 6),
                    _buildQuickMissionProgress(
                      icon: '⚔️',
                      label: 'Join 1 Tournament Match',
                      current: taskData.matchesJoinedToday,
                      target: 1,
                      reward: '+1 🪙',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Navigate to Earn Screen or Close
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('CLOSE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onNavigateToEarn?.call();
                      },
                      child: const Text('ALL TASKS ➔', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(UserDailyTaskData taskData, bool hasCheckedIn) {
    return Column(
      children: [
        // Row 1: Days 1 to 7
        _buildCalendarRow(1, 7, taskData, hasCheckedIn),
        const SizedBox(height: 6),
        // Row 2: Days 8 to 14
        _buildCalendarRow(8, 14, taskData, hasCheckedIn),
      ],
    );
  }

  Widget _buildCalendarRow(int startDay, int endDay, UserDailyTaskData taskData, bool hasCheckedIn) {
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

  Widget _buildQuickMissionProgress({
    required String icon,
    required String label,
    required int current,
    required int target,
    required String reward,
  }) {
    final progress = (current / target).clamp(0.0, 1.0);
    final isDone = current >= target;

    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '$current/$target • $reward',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: isDone ? const Color(0xFF4ADE80) : const Color(0xFFFCD34D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDone ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
