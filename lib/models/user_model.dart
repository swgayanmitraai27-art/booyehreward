class UserWallet {
  // 1. FREE-TO-PLAY ECONOMY (Ad-Based, Zero Loss)
  int adCoins;      // 🟡 Ad Coins: Earned strictly by watching ads (Entry for Free Matches)
  int rewardCoins;  // 🎟️ Reward Coins: Won from Free Matches (Redeemable for Google Play / FF Diamonds, NO CASH OUT)

  // 2. PAID ESPORTS ECONOMY (Real Money)
  double depositCash; // 💵 Deposit Cash (₹): Added via Razorpay (Entry for Paid Matches, non-withdrawable)
  double winningCash; // 🏆 Winning Cash (₹): Won from Paid Matches (100% Withdrawable to UPI)

  UserWallet({
    required this.adCoins,
    required this.rewardCoins,
    required this.depositCash,
    required this.winningCash,
  });

  Map<String, dynamic> toJson() => {
    'adCoins': adCoins,
    'rewardCoins': rewardCoins,
    'depositCash': depositCash,
    'winningCash': winningCash,
  };

  factory UserWallet.fromJson(Map<String, dynamic> json) => UserWallet(
    adCoins: ((json['adCoins'] ?? json['bonus_balance'] ?? json['ad_coins'] ?? json['bonus'] ?? 0) as num).toInt(),
    rewardCoins: ((json['rewardCoins'] ?? json['reward_coins'] ?? 0) as num).toInt(),
    depositCash: ((json['depositCash'] ?? json['real_balance'] ?? json['realCash'] ?? json['real'] ?? 0) as num).toDouble(),
    winningCash: ((json['winningCash'] ?? json['total_winnings'] ?? json['winnings'] ?? 0) as num).toDouble(),
  );
}

class AdTracker {
  int adsWatchedToday;
  int adsWatchedSinceLastCoin; // 0, 1, 2 -> at 3 resets and awards 1 Ad Coin
  int dailyLimitRemaining;     // e.g. 30 ads daily
  DateTime? lastAdTimestamp;

  AdTracker({
    required this.adsWatchedToday,
    required this.adsWatchedSinceLastCoin,
    required this.dailyLimitRemaining,
    this.lastAdTimestamp,
  });

  Map<String, dynamic> toJson() => {
    'adsWatchedToday': adsWatchedToday,
    'adsWatchedSinceLastCoin': adsWatchedSinceLastCoin,
    'dailyLimitRemaining': dailyLimitRemaining,
    'lastAdTimestamp': lastAdTimestamp?.toIso8601String(),
  };

  factory AdTracker.fromJson(Map<String, dynamic> json) => AdTracker(
    adsWatchedToday: (json['adsWatchedToday'] ?? 0) as int,
    adsWatchedSinceLastCoin: (json['adsWatchedSinceLastCoin'] ?? 0) as int,
    dailyLimitRemaining: (json['dailyLimitRemaining'] ?? 30) as int,
    lastAdTimestamp: json['lastAdTimestamp'] != null ? DateTime.tryParse(json['lastAdTimestamp']) : null,
  );
}

class UserStats {
  int matchesPlayed;
  int matchesWon;
  int totalKills;
  double totalWinningsCash;
  int totalRewardCoinsWon;
  int totalCoinsEarned;

  UserStats({
    required this.matchesPlayed,
    required this.matchesWon,
    required this.totalKills,
    required this.totalWinningsCash,
    required this.totalRewardCoinsWon,
    required this.totalCoinsEarned,
  });

  Map<String, dynamic> toJson() => {
    'matchesPlayed': matchesPlayed,
    'matchesWon': matchesWon,
    'totalKills': totalKills,
    'totalWinningsCash': totalWinningsCash,
    'totalRewardCoinsWon': totalRewardCoinsWon,
    'totalCoinsEarned': totalCoinsEarned,
  };

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
    matchesPlayed: (json['matchesPlayed'] ?? 0) as int,
    matchesWon: (json['matchesWon'] ?? 0) as int,
    totalKills: (json['totalKills'] ?? 0) as int,
    totalWinningsCash: ((json['totalWinningsCash'] ?? 0) as num).toDouble(),
    totalRewardCoinsWon: (json['totalRewardCoinsWon'] ?? 0) as int,
    totalCoinsEarned: (json['totalCoinsEarned'] ?? 0) as int,
  );
}

class UserModel {
  String uid;
  String displayName;
  String email;
  String phoneNumber;
  String inGameName;
  String inGameUid;
  int inGameLevel; // Minimum Level 40+ for Anti-Hack protection
  String password;
  UserWallet wallet;
  AdTracker adTracker;
  UserStats stats;
  String role; // 'user' | 'admin'

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    required this.inGameName,
    required this.inGameUid,
    this.inGameLevel = 52,
    this.password = '',
    required this.wallet,
    required this.adTracker,
    required this.stats,
    this.role = 'user',
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'phoneNumber': phoneNumber,
    'inGameName': inGameName,
    'inGameUid': inGameUid,
    'inGameLevel': inGameLevel,
    'password': password,
    'wallet': wallet.toJson(),
    'adTracker': adTracker.toJson(),
    'stats': stats.toJson(),
    'role': role,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    var walletMap = json['wallet'] as Map<String, dynamic>? ?? {};
    if (walletMap.isEmpty && (json['real_balance'] != null || json['depositCash'] != null)) {
      walletMap = {
        'depositCash': json['depositCash'] ?? json['real_balance'] ?? 0,
        'winningCash': json['winningCash'] ?? json['total_winnings'] ?? 0,
        'adCoins': json['adCoins'] ?? json['bonus_balance'] ?? 0,
        'rewardCoins': json['rewardCoins'] ?? 0,
      };
    } else {
      // If wallet map exists, also merge top-level real_balance if depositCash is 0
      final dep = walletMap['depositCash'] ?? json['depositCash'] ?? json['real_balance'] ?? 0;
      final ad = walletMap['adCoins'] ?? json['adCoins'] ?? json['bonus_balance'] ?? 0;
      walletMap['depositCash'] = dep;
      walletMap['adCoins'] = ad;
    }

    return UserModel(
      uid: json['uid'] ?? json['userId'] ?? 'user_01',
      displayName: json['displayName'] ?? json['name'] ?? 'Gamer',
      email: json['email'] ?? 'gamer@booyah.com',
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      inGameName: json['inGameName'] ?? json['in_game_name'] ?? 'FF_WARRIOR',
      inGameUid: json['inGameUid'] ?? json['in_game_uid'] ?? '10000000',
      inGameLevel: (json['inGameLevel'] ?? 45) as int,
      password: json['password'] ?? '',
      wallet: UserWallet.fromJson(walletMap),
      adTracker: AdTracker.fromJson(json['adTracker'] ?? {}),
      stats: UserStats.fromJson(json['stats'] ?? {}),
      role: json['role'] ?? 'user',
    );
  }
}
