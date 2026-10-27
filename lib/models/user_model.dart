class UserModel {
  final String uid;
  String displayName;
  final String email;
  final String phoneNumber;
  int adCoins;
  int winningCoins;
  int gameScore;
  int knifeHitHighScore;
  int fruitSlashHighScore;
  int speedMathHighScore;
  int ticTacToeHighScore;
  int weeklyScore;
  int spinCount;
  String lastSpinDate;
  int scratchCount;
  String lastScratchDate;
  String lastCheckInDate;
  int streakDays;
  final String role;
  String referralCode;
  String referredBy;
  String inGameName;
  String inGameId;
  int totalWins;
  int totalKills;
  bool hasPlayedFirstMatch;
  int miniGameCoinsToday;
  String miniGameDate;

  UserModel({
    required this.uid,
    required this.displayName,
    this.email = '',
    this.phoneNumber = '',
    this.adCoins = 0,
    this.winningCoins = 0,
    this.gameScore = 0,
    this.knifeHitHighScore = 0,
    this.fruitSlashHighScore = 0,
    this.speedMathHighScore = 0,
    this.ticTacToeHighScore = 0,
    this.weeklyScore = 0,
    this.spinCount = 0,
    this.lastSpinDate = '',
    this.scratchCount = 0,
    this.lastScratchDate = '',
    this.lastCheckInDate = '',
    this.streakDays = 0,
    this.role = 'user',
    this.referralCode = '',
    this.referredBy = '',
    this.inGameName = '',
    this.inGameId = '',
    this.totalWins = 0,
    this.totalKills = 0,
    this.hasPlayedFirstMatch = false,
    this.miniGameCoinsToday = 0,
    this.miniGameDate = '',
  });

  factory UserModel.guest() {
    final randomId = DateTime.now().millisecondsSinceEpoch % 10000;
    final rCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    return UserModel(
      uid: 'guest_$randomId',
      displayName: 'Player_$randomId',
      email: '',
      phoneNumber: '',
      adCoins: 20, // 20 Welcome coins
      gameScore: 0,
      knifeHitHighScore: 0,
      fruitSlashHighScore: 0,
      speedMathHighScore: 0,
      ticTacToeHighScore: 0,
      weeklyScore: 0,
      spinCount: 0,
      lastSpinDate: '',
      scratchCount: 0,
      lastScratchDate: '',
      lastCheckInDate: '',
      streakDays: 1,
      role: 'user',
      referralCode: rCode,
      referredBy: '',
      inGameName: 'Player_$randomId',
      inGameId: '',
      totalWins: 0,
      totalKills: 0,
      hasPlayedFirstMatch: false,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as String? ?? 'guest_1001',
      displayName: json['displayName'] as String? ?? 'Player',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      adCoins: (json['adCoins'] as num?)?.toInt() ?? 20,
      winningCoins: (json['winningCoins'] as num?)?.toInt() ?? 0,
      gameScore: (json['gameScore'] as num?)?.toInt() ?? 0,
      knifeHitHighScore: (json['knifeHitHighScore'] as num?)?.toInt() ?? 0,
      fruitSlashHighScore: (json['fruitSlashHighScore'] as num?)?.toInt() ?? 0,
      speedMathHighScore: (json['speedMathHighScore'] as num?)?.toInt() ?? 0,
      ticTacToeHighScore: (json['ticTacToeHighScore'] as num?)?.toInt() ?? 0,
      weeklyScore: (json['weeklyScore'] as num?)?.toInt() ?? 0,
      spinCount: (json['spinCount'] as num?)?.toInt() ?? 0,
      lastSpinDate: json['lastSpinDate'] as String? ?? '',
      scratchCount: (json['scratchCount'] as num?)?.toInt() ?? 0,
      lastScratchDate: json['lastScratchDate'] as String? ?? '',
      lastCheckInDate: json['lastCheckInDate'] as String? ?? '',
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      role: json['role'] as String? ?? 'user',
      referralCode: json['referralCode'] as String? ?? '',
      referredBy: json['referredBy'] as String? ?? '',
      inGameName: json['inGameName'] as String? ?? json['displayName'] as String? ?? '',
      inGameId: json['inGameId'] as String? ?? '',
      totalWins: (json['totalWins'] as num?)?.toInt() ?? 0,
      totalKills: (json['totalKills'] as num?)?.toInt() ?? 0,
      hasPlayedFirstMatch: json['hasPlayedFirstMatch'] as bool? ?? false,
      miniGameCoinsToday: (json['miniGameCoinsToday'] as num?)?.toInt() ?? 0,
      miniGameDate: json['miniGameDate'] as String? ?? '',
    );
  }

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? phoneNumber,
    int? adCoins,
    int? winningCoins,
    int? gameScore,
    int? knifeHitHighScore,
    int? fruitSlashHighScore,
    int? speedMathHighScore,
    int? ticTacToeHighScore,
    int? weeklyScore,
    int? spinCount,
    String? lastSpinDate,
    int? scratchCount,
    String? lastScratchDate,
    String? lastCheckInDate,
    int? streakDays,
    String? role,
    String? referralCode,
    String? referredBy,
    String? inGameName,
    String? inGameId,
    int? totalWins,
    int? totalKills,
    bool? hasPlayedFirstMatch,
    int? miniGameCoinsToday,
    String? miniGameDate,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      adCoins: adCoins ?? this.adCoins,
      winningCoins: winningCoins ?? this.winningCoins,
      gameScore: gameScore ?? this.gameScore,
      knifeHitHighScore: knifeHitHighScore ?? this.knifeHitHighScore,
      fruitSlashHighScore: fruitSlashHighScore ?? this.fruitSlashHighScore,
      speedMathHighScore: speedMathHighScore ?? this.speedMathHighScore,
      ticTacToeHighScore: ticTacToeHighScore ?? this.ticTacToeHighScore,
      weeklyScore: weeklyScore ?? this.weeklyScore,
      spinCount: spinCount ?? this.spinCount,
      lastSpinDate: lastSpinDate ?? this.lastSpinDate,
      scratchCount: scratchCount ?? this.scratchCount,
      lastScratchDate: lastScratchDate ?? this.lastScratchDate,
      lastCheckInDate: lastCheckInDate ?? this.lastCheckInDate,
      streakDays: streakDays ?? this.streakDays,
      role: role ?? this.role,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      inGameName: inGameName ?? this.inGameName,
      inGameId: inGameId ?? this.inGameId,
      totalWins: totalWins ?? this.totalWins,
      totalKills: totalKills ?? this.totalKills,
      hasPlayedFirstMatch: hasPlayedFirstMatch ?? this.hasPlayedFirstMatch,
      miniGameCoinsToday: miniGameCoinsToday ?? this.miniGameCoinsToday,
      miniGameDate: miniGameDate ?? this.miniGameDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'adCoins': adCoins,
      'winningCoins': winningCoins,
      'gameScore': gameScore,
      'knifeHitHighScore': knifeHitHighScore,
      'fruitSlashHighScore': fruitSlashHighScore,
      'speedMathHighScore': speedMathHighScore,
      'ticTacToeHighScore': ticTacToeHighScore,
      'weeklyScore': weeklyScore,
      'spinCount': spinCount,
      'lastSpinDate': lastSpinDate,
      'scratchCount': scratchCount,
      'lastScratchDate': lastScratchDate,
      'lastCheckInDate': lastCheckInDate,
      'streakDays': streakDays,
      'role': role,
      'referralCode': referralCode,
      'miniGameCoinsToday': miniGameCoinsToday,
      'miniGameDate': miniGameDate,
      'referredBy': referredBy,
      'inGameName': inGameName,
      'inGameId': inGameId,
      'totalWins': totalWins,
      'totalKills': totalKills,
      'hasPlayedFirstMatch': hasPlayedFirstMatch,
    };
  }

  int get totalCoins => adCoins + winningCoins;
}
