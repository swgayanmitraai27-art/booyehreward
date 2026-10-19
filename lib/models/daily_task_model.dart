class DailyTaskItem {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final int targetCount;
  final int rewardCoins;
  final String actionRoute; // 'WATCH_ADS', 'MATCHES', 'SHARE', 'CHECK_IN'
  final bool isStreakMilestone;

  const DailyTaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.targetCount,
    required this.rewardCoins,
    required this.actionRoute,
    this.isStreakMilestone = false,
  });

  int getProgress(UserDailyTaskData data) {
    switch (id) {
      case 'task_daily_login':
        return data.hasCheckedInToday ? 1 : 0;
      case 'task_streak_3':
      case 'task_streak_7':
      case 'task_streak_14':
        return data.checkInStreak;
      case 'task_watch_ads':
      case 'task_watch_10_ads':
      case 'task_watch_30_ads':
        return data.adsWatchedToday;
      case 'task_join_match':
        return data.matchesJoinedToday;
      case 'task_win_booyah':
        return data.booyahsWonToday;
      case 'task_share_referral':
        return data.referralsDoneToday;
      default:
        return 0;
    }
  }

  bool isCompleted(UserDailyTaskData data) => getProgress(data) >= targetCount;
  bool isClaimed(UserDailyTaskData data) {
    if (isStreakMilestone) {
      return data.claimedMilestoneTaskIds.contains(id);
    }
    return data.claimedTaskIds.contains(id);
  }

  bool canClaim(UserDailyTaskData data) => isCompleted(data) && !isClaimed(data);
}

class UserDailyTaskData {
  String lastCheckInDate; // YYYY-MM-DD
  int checkInStreak; // 1 to 14
  bool hasCheckedInToday;
  int adsWatchedToday;
  int matchesJoinedToday;
  int booyahsWonToday;
  int referralsDoneToday;
  List<String> claimedTaskIds;
  List<String> claimedMilestoneTaskIds;

  UserDailyTaskData({
    required this.lastCheckInDate,
    this.checkInStreak = 1,
    this.hasCheckedInToday = false,
    this.adsWatchedToday = 0,
    this.matchesJoinedToday = 0,
    this.booyahsWonToday = 0,
    this.referralsDoneToday = 0,
    List<String>? claimedTaskIds,
    List<String>? claimedMilestoneTaskIds,
  })  : claimedTaskIds = claimedTaskIds ?? [],
        claimedMilestoneTaskIds = claimedMilestoneTaskIds ?? [];

  static String getTodayDateString() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  /// 14-Day Progressive Streak Rewards (Calibrated for strict owner profitability):
  /// Day 1-2: 1, Day 3: 2 (🌟 Milestone), Day 4-6: 1, Day 7: 3 (🏆 Super Bonus),
  /// Day 8-13: 1, Day 14: 5 (👑 Grand Jackpot)
  static int getRewardForDay(int day) {
    switch (day) {
      case 1:
      case 2:
        return 1;
      case 3:
        return 2; // 🌟 3-Day Milestone Bonus
      case 4:
      case 5:
      case 6:
        return 1;
      case 7:
        return 3; // 🏆 7-Day Champion Bonus
      case 8:
      case 9:
      case 10:
      case 11:
      case 12:
      case 13:
        return 1;
      case 14:
        return 5; // 👑 14-Day Grand Legend Jackpot
      default:
        return 1;
    }
  }

  int getTodayCheckInReward() => getRewardForDay(checkInStreak);

  /// Automatically check if today is a new day and reset daily mission counters
  void checkAndResetForNewDay() {
    final today = getTodayDateString();
    if (lastCheckInDate != today) {
      // Check if streak was broken (missed yesterday)
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

      if (lastCheckInDate == yesterdayStr) {
        // Consecutive day
        if (hasCheckedInToday) {
          if (checkInStreak >= 14) {
            checkInStreak = 1;
            claimedMilestoneTaskIds.clear(); // Reset 14-day cycle milestones
          } else {
            checkInStreak += 1;
          }
        }
      } else {
        // Broken streak: reset to Day 1
        checkInStreak = 1;
        claimedMilestoneTaskIds.clear();
      }

      lastCheckInDate = today;
      hasCheckedInToday = false;
      adsWatchedToday = 0;
      matchesJoinedToday = 0;
      booyahsWonToday = 0;
      referralsDoneToday = 0;
      claimedTaskIds.clear();
    }
  }

  Map<String, dynamic> toJson() => {
    'lastCheckInDate': lastCheckInDate,
    'checkInStreak': checkInStreak,
    'hasCheckedInToday': hasCheckedInToday,
    'adsWatchedToday': adsWatchedToday,
    'matchesJoinedToday': matchesJoinedToday,
    'booyahsWonToday': booyahsWonToday,
    'referralsDoneToday': referralsDoneToday,
    'claimedTaskIds': claimedTaskIds,
    'claimedMilestoneTaskIds': claimedMilestoneTaskIds,
  };

  factory UserDailyTaskData.fromJson(Map<String, dynamic> json) {
    final data = UserDailyTaskData(
      lastCheckInDate: json['lastCheckInDate'] ?? getTodayDateString(),
      checkInStreak: (json['checkInStreak'] ?? 1) as int,
      hasCheckedInToday: (json['hasCheckedInToday'] ?? false) as bool,
      adsWatchedToday: (json['adsWatchedToday'] ?? 0) as int,
      matchesJoinedToday: (json['matchesJoinedToday'] ?? 0) as int,
      booyahsWonToday: (json['booyahsWonToday'] ?? 0) as int,
      referralsDoneToday: (json['referralsDoneToday'] ?? 0) as int,
      claimedTaskIds: (json['claimedTaskIds'] is List)
          ? List<String>.from(json['claimedTaskIds'])
          : <String>[],
      claimedMilestoneTaskIds: (json['claimedMilestoneTaskIds'] is List)
          ? List<String>.from(json['claimedMilestoneTaskIds'])
          : <String>[],
    );
    data.checkAndResetForNewDay();
    return data;
  }

  static UserDailyTaskData createInitial() {
    return UserDailyTaskData(
      lastCheckInDate: getTodayDateString(),
      checkInStreak: 1,
      hasCheckedInToday: false,
    );
  }
}

/// Official List of Booyah Rewards Daily Tasks & Streak Milestones
class DailyTasksCatalog {
  // Streak Milestone Tasks (3-Day, 7-Day, 14-Day) - Safe & Profitable
  static const List<DailyTaskItem> streakMilestoneTasks = [
    DailyTaskItem(
      id: 'task_streak_3',
      title: '3-Day Login Streak 🔥',
      description: 'Lagatar 3 din login karein aur milestone bonus claim karein',
      iconEmoji: '🔥',
      targetCount: 3,
      rewardCoins: 1,
      actionRoute: 'CHECK_IN',
      isStreakMilestone: true,
    ),
    DailyTaskItem(
      id: 'task_streak_7',
      title: '7-Day Champion Streak 🏆',
      description: 'Lagatar 7 din active rahein aur mega champion reward jeetein',
      iconEmoji: '🏆',
      targetCount: 7,
      rewardCoins: 2,
      actionRoute: 'CHECK_IN',
      isStreakMilestone: true,
    ),
    DailyTaskItem(
      id: 'task_streak_14',
      title: '14-Day Legend Streak 👑',
      description: 'Lagatar 14 din login karke Grand Legend jackpot jeetein',
      iconEmoji: '👑',
      targetCount: 14,
      rewardCoins: 5,
      actionRoute: 'CHECK_IN',
      isStreakMilestone: true,
    ),
  ];

  // Daily Missions (Reset every night at 12 AM)
  static const List<DailyTaskItem> dailyMissions = [
    DailyTaskItem(
      id: 'task_daily_login',
      title: 'Daily Login Check-In',
      description: 'App daily open karke apna free check-in coin claim karein',
      iconEmoji: '📅',
      targetCount: 1,
      rewardCoins: 1,
      actionRoute: 'CHECK_IN',
    ),
    DailyTaskItem(
      id: 'task_watch_ads',
      title: 'Watch 3 Video Ads',
      description: 'Daily 3 Video Ads dekhein aur +1 extra coin jeetein',
      iconEmoji: '📺',
      targetCount: 3,
      rewardCoins: 1,
      actionRoute: 'WATCH_ADS',
    ),
    DailyTaskItem(
      id: 'task_watch_10_ads',
      title: 'Watch 10 Video Ads',
      description: 'Daily 10 Video Ads dekhein aur +2 Coins bonus claim karein',
      iconEmoji: '🎬',
      targetCount: 10,
      rewardCoins: 2,
      actionRoute: 'WATCH_ADS',
    ),
    DailyTaskItem(
      id: 'task_watch_30_ads',
      title: 'Watch 30 Ads Mega Task 🌟',
      description: 'Daily 30 Video Ads dekhein aur +5 Coins Mega Jackpot jeetein!',
      iconEmoji: '💎',
      targetCount: 30,
      rewardCoins: 5,
      actionRoute: 'WATCH_ADS',
    ),
    DailyTaskItem(
      id: 'task_join_match',
      title: 'Join 1 Tournament Match',
      description: 'Kisi bhi Free ya Coin match mein participate karein',
      iconEmoji: '⚔️',
      targetCount: 1,
      rewardCoins: 1,
      actionRoute: 'MATCHES',
    ),
    DailyTaskItem(
      id: 'task_win_booyah',
      title: 'Get 1 Booyah (Match Win)',
      description: 'Custom room match jeetkar Booyah bonus claim karein',
      iconEmoji: '🏆',
      targetCount: 1,
      rewardCoins: 2,
      actionRoute: 'MATCHES',
    ),
    DailyTaskItem(
      id: 'task_share_referral',
      title: 'Invite Friends Daily',
      description: 'Apna referral code WhatsApp/Telegram par share karein',
      iconEmoji: '👥',
      targetCount: 1,
      rewardCoins: 1,
      actionRoute: 'SHARE',
    ),
  ];

  static List<DailyTaskItem> get allTasks => [
    ...dailyMissions,
    ...streakMilestoneTasks,
  ];
}
