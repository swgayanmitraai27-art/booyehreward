class UserWallet {
  // 1. FREE-TO-PLAY ECONOMY (Ad-Based, Zero Loss)
  int adCoins;        // 🟡 Ad Coins: Earned strictly by watching ads (Entry for Free Matches)
  int rewardCoins;    // 🎟️ Reward Coins: Won from Free Matches (Redeemable for Google Play / FF Diamonds, NO CASH OUT)

  // 2. PAID ESPORTS ECONOMY (Real Money)
  double bonusCash;   // 🎁 Bonus Cash (₹): 10% Extra Deposit Cashback & Referrals (Match Entry ONLY, Non-withdrawable)
  double depositCash; // 💵 Deposit Cash (₹): Added via Razorpay (Match Entry ONLY, Non-withdrawable)
  double winningCash; // 🏆 Winning Cash (₹): Won from Paid Matches (100% Withdrawable to UPI)

  UserWallet({
    required this.adCoins,
    required this.rewardCoins,
    this.bonusCash = 0.0,
    required this.depositCash,
    required this.winningCash,
  });

  // Total Playable Real/Bonus Cash
  double get totalPlayableCash => bonusCash + depositCash + winningCash;

  Map<String, dynamic> toJson() => {
    'adCoins': adCoins,
    'rewardCoins': rewardCoins,
    'bonusCash': bonusCash,
    'depositCash': depositCash,
    'winningCash': winningCash,
  };

  factory UserWallet.fromJson(Map<String, dynamic> json) => UserWallet(
    adCoins: ((json['adCoins'] ?? json['ad_coins'] ?? json['bonus_balance'] ?? json['bonus'] ?? 0) as num).toInt(),
    rewardCoins: ((json['rewardCoins'] ?? json['reward_coins'] ?? 0) as num).toInt(),
    bonusCash: ((json['bonusCash'] ?? json['bonus_cash'] ?? 0) as num).toDouble(),
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
  String? inGameName;
  String? inGameUid;
  int inGameLevel;
  String? password;
  String role;
  String? avatarUrl;
  UserWallet wallet;
  AdTracker adTracker;
  UserStats stats;
  DateTime createdAt;
  bool isBanned;
  bool isVip;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    this.inGameName,
    this.inGameUid,
    this.inGameLevel = 45,
    this.password,
    this.role = 'user',
    this.avatarUrl,
    required this.wallet,
    required this.adTracker,
    required this.stats,
    DateTime? createdAt,
    this.isBanned = false,
    this.isVip = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'phoneNumber': phoneNumber,
    'inGameName': inGameName,
    'inGameUid': inGameUid,
    'inGameLevel': inGameLevel,
    'password': password,
    'role': role,
    'avatarUrl': avatarUrl,
    'wallet': wallet.toJson(),
    'adTracker': adTracker.toJson(),
    'stats': stats.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'isBanned': isBanned,
    'isVip': isVip,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    uid: (json['uid'] ?? 'guest_${DateTime.now().millisecondsSinceEpoch}') as String,
    displayName: (json['displayName'] ?? json['name'] ?? 'FreeFire Player') as String,
    email: (json['email'] ?? 'player@booyahrewards.app') as String,
    phoneNumber: (json['phoneNumber'] ?? json['phone'] ?? '+91 9876543210') as String,
    inGameName: json['inGameName'] as String?,
    inGameUid: json['inGameUid'] as String?,
    inGameLevel: (json['inGameLevel'] ?? json['level'] ?? 45) as int,
    password: json['password'] as String?,
    role: (json['role'] ?? 'user') as String,
    avatarUrl: json['avatarUrl'] as String?,
    wallet: json['wallet'] != null
        ? UserWallet.fromJson(json['wallet'] as Map<String, dynamic>)
        : UserWallet(
            adCoins: ((json['bonus_balance'] ?? json['ad_coins'] ?? 0) as num).toInt(),
            rewardCoins: ((json['reward_coins'] ?? 0) as num).toInt(),
            bonusCash: ((json['bonus_cash'] ?? 0) as num).toDouble(),
            depositCash: ((json['real_balance'] ?? json['depositCash'] ?? 0) as num).toDouble(),
            winningCash: ((json['total_winnings'] ?? json['winningCash'] ?? 0) as num).toDouble(),
          ),
    adTracker: json['adTracker'] != null
        ? AdTracker.fromJson(json['adTracker'] as Map<String, dynamic>)
        : AdTracker(adsWatchedToday: 0, adsWatchedSinceLastCoin: 0, dailyLimitRemaining: 30),
    stats: json['stats'] != null
        ? UserStats.fromJson(json['stats'] as Map<String, dynamic>)
        : UserStats(
            matchesPlayed: 0,
            matchesWon: 0,
            totalKills: 0,
            totalWinningsCash: 0,
            totalRewardCoinsWon: 0,
            totalCoinsEarned: 0,
          ),
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
        : DateTime.now(),
    isBanned: (json['isBanned'] ?? false) as bool,
    isVip: (json['isVip'] ?? false) as bool,
  );
}
