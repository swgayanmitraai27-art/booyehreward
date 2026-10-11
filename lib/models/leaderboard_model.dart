class LeaderboardEntry {
  final String uid;
  final String displayName;
  final String? inGameName;
  final String? inGameUid;
  final int inGameLevel;
  final String? avatarUrl;
  final int rank;
  final int kills;
  final int matchesWon;
  final int matchesPlayed;
  final double winningsCash;
  final int rewardCoins;
  final int points;
  final double prizeAmount; // 200 Coins for Rank 1, 150 Coins for Rank 2, 100 Coins for Rank 3, 0 for others
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.uid,
    required this.displayName,
    this.inGameName,
    this.inGameUid,
    this.inGameLevel = 45,
    this.avatarUrl,
    required this.rank,
    required this.kills,
    required this.matchesWon,
    required this.matchesPlayed,
    required this.winningsCash,
    required this.rewardCoins,
    required this.points,
    required this.prizeAmount,
    this.isCurrentUser = false,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'displayName': displayName,
    'inGameName': inGameName,
    'inGameUid': inGameUid,
    'inGameLevel': inGameLevel,
    'avatarUrl': avatarUrl,
    'rank': rank,
    'kills': kills,
    'matchesWon': matchesWon,
    'matchesPlayed': matchesPlayed,
    'winningsCash': winningsCash,
    'rewardCoins': rewardCoins,
    'points': points,
    'prizeAmount': prizeAmount,
    'isCurrentUser': isCurrentUser,
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
    uid: json['uid'] ?? '',
    displayName: json['displayName'] ?? json['name'] ?? 'Player',
    inGameName: json['inGameName'],
    inGameUid: json['inGameUid'],
    inGameLevel: json['inGameLevel'] ?? 45,
    avatarUrl: json['avatarUrl'],
    rank: json['rank'] ?? 0,
    kills: json['kills'] ?? 0,
    matchesWon: json['matchesWon'] ?? 0,
    matchesPlayed: json['matchesPlayed'] ?? 0,
    winningsCash: ((json['winningsCash'] ?? 0) as num).toDouble(),
    rewardCoins: json['rewardCoins'] ?? 0,
    points: json['points'] ?? 0,
    prizeAmount: ((json['prizeAmount'] ?? 0) as num).toDouble(),
    isCurrentUser: json['isCurrentUser'] ?? false,
  );
}

class WeeklyDistributionRecord {
  final String id;
  final String seasonLabel;
  final DateTime distributedAt;
  final String adminUid;
  final String adminName;
  final List<LeaderboardWinnerPayout> winners;
  final double totalDistributed;

  WeeklyDistributionRecord({
    required this.id,
    required this.seasonLabel,
    required this.distributedAt,
    required this.adminUid,
    required this.adminName,
    required this.winners,
    required this.totalDistributed,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'seasonLabel': seasonLabel,
    'distributedAt': distributedAt.toIso8601String(),
    'adminUid': adminUid,
    'adminName': adminName,
    'winners': winners.map((w) => w.toJson()).toList(),
    'totalDistributed': totalDistributed,
  };

  factory WeeklyDistributionRecord.fromJson(Map<String, dynamic> json) => WeeklyDistributionRecord(
    id: json['id'] ?? 'dist_${DateTime.now().millisecondsSinceEpoch}',
    seasonLabel: json['seasonLabel'] ?? 'Weekly Championship',
    distributedAt: json['distributedAt'] != null
        ? (DateTime.tryParse(json['distributedAt'])?.toLocal() ?? DateTime.now())
        : DateTime.now(),
    adminUid: json['adminUid'] ?? 'admin',
    adminName: json['adminName'] ?? 'Official Admin',
    winners: (json['winners'] as List? ?? [])
        .map((w) => LeaderboardWinnerPayout.fromJson(Map<String, dynamic>.from(w)))
        .toList(),
    totalDistributed: ((json['totalDistributed'] ?? 100.0) as num).toDouble(),
  );
}

class LeaderboardWinnerPayout {
  final int rank;
  final String uid;
  final String name;
  final String? inGameName;
  final double prizeAmount;
  final int points;

  LeaderboardWinnerPayout({
    required this.rank,
    required this.uid,
    required this.name,
    this.inGameName,
    required this.prizeAmount,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'uid': uid,
    'name': name,
    'inGameName': inGameName,
    'prizeAmount': prizeAmount,
    'points': points,
  };

  factory LeaderboardWinnerPayout.fromJson(Map<String, dynamic> json) => LeaderboardWinnerPayout(
    rank: json['rank'] ?? 1,
    uid: json['uid'] ?? '',
    name: json['name'] ?? 'Player',
    inGameName: json['inGameName'],
    prizeAmount: ((json['prizeAmount'] ?? 0) as num).toDouble(),
    points: json['points'] ?? 0,
  );
}
