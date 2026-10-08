import 'team_model.dart';

enum MatchType { free, paid }
enum EntryFeeType { adCoins, cash }
enum GameType { freeFire, freeFireMax }
enum MatchMode { br, cs, loneWolf }
enum TeamType { solo, duo, squad }
enum MatchFormat { solo, duo, squad, cs4v4, loneWolf1v1, loneWolf2v2 }
enum MapType { bermuda, purgatory, kalahari, alpine, nexterra }
enum MatchStatus { upcoming, roomFilling, ongoing, completed, cancelled }

class TournamentModeItem {
  final String key;
  final String title;
  final String bannerUrl;
  final int defaultSlots;
  final String mode; // 'br', 'cs', 'loneWolf'
  final bool enabled;

  TournamentModeItem({
    required this.key,
    required this.title,
    required this.bannerUrl,
    required this.defaultSlots,
    required this.mode,
    this.enabled = true,
  });

  factory TournamentModeItem.fromJson(Map<String, dynamic> json) => TournamentModeItem(
    key: (json['key'] ?? '').toString().toUpperCase(),
    title: (json['title'] ?? '').toString(),
    bannerUrl: (json['bannerUrl'] ?? '').toString(),
    defaultSlots: (json['defaultSlots'] ?? 48) as int,
    mode: (json['mode'] ?? 'br').toString(),
    enabled: json['enabled'] != false,
  );

  Map<String, dynamic> toJson() => {
    'key': key,
    'title': title,
    'bannerUrl': bannerUrl,
    'defaultSlots': defaultSlots,
    'mode': mode,
    'enabled': enabled,
  };

  TournamentModeItem copyWith({
    String? key,
    String? title,
    String? bannerUrl,
    int? defaultSlots,
    String? mode,
    bool? enabled,
  }) {
    return TournamentModeItem(
      key: key ?? this.key,
      title: title ?? this.title,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      defaultSlots: defaultSlots ?? this.defaultSlots,
      mode: mode ?? this.mode,
      enabled: enabled ?? this.enabled,
    );
  }
}


class MatchCredentials {
  String roomId;
  String roomPassword;
  bool isRevealed;

  MatchCredentials({
    required this.roomId,
    required this.roomPassword,
    this.isRevealed = false,
  });

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'roomPassword': roomPassword,
    'isRevealed': isRevealed,
  };

  factory MatchCredentials.fromJson(Map<String, dynamic> json) => MatchCredentials(
    roomId: json['roomId'] ?? '',
    roomPassword: json['roomPassword'] ?? '',
    isRevealed: json['isRevealed'] ?? false,
  );
}

class ProfitShares {
  final double founder60;
  final double host25;
  final double investor15;

  ProfitShares({
    required this.founder60,
    required this.host25,
    required this.investor15,
  });

  Map<String, dynamic> toJson() => {
    'founder_60': founder60,
    'host_25': host25,
    'investor_15': investor15,
  };

  factory ProfitShares.fromJson(Map<String, dynamic> json) => ProfitShares(
    founder60: ((json['founder_60'] ?? json['founder60'] ?? 0) as num).toDouble(),
    host25: ((json['host_25'] ?? json['host25'] ?? 0) as num).toDouble(),
    investor15: ((json['investor_15'] ?? json['investor15'] ?? 0) as num).toDouble(),
  );
}

class FinancialBreakdown {
  final double totalEntryCollection;
  final double platformCommissionGross;
  final double gatewayFeeDeduction;
  final double netProfit;
  final ProfitShares shares;

  FinancialBreakdown({
    required this.totalEntryCollection,
    required this.platformCommissionGross,
    required this.gatewayFeeDeduction,
    required this.netProfit,
    required this.shares,
  });

  Map<String, dynamic> toJson() => {
    'total_entry_collection': totalEntryCollection,
    'platform_commission_gross': platformCommissionGross,
    'gateway_fee_deduction': gatewayFeeDeduction,
    'net_profit': netProfit,
    'shares': shares.toJson(),
  };

  factory FinancialBreakdown.fromJson(Map<String, dynamic> json) => FinancialBreakdown(
    totalEntryCollection: ((json['total_entry_collection'] ?? json['totalEntryCollection'] ?? 0) as num).toDouble(),
    platformCommissionGross: ((json['platform_commission_gross'] ?? json['platformCommissionGross'] ?? 0) as num).toDouble(),
    gatewayFeeDeduction: ((json['gateway_fee_deduction'] ?? json['gatewayFeeDeduction'] ?? 0) as num).toDouble(),
    netProfit: ((json['net_profit'] ?? json['netProfit'] ?? 0) as num).toDouble(),
    shares: ProfitShares.fromJson(json['shares'] != null ? Map<String, dynamic>.from(json['shares']) : {}),
  );

  /// Automated Profit Sharing Calculation Engine:
  /// - platform_commission_gross = 25% of total_entry_collection
  /// - gateway_fee_deduction = 2.36% of total_entry_collection (Razorpay standard 2% + 18% GST)
  /// - net_profit = platform_commission_gross - gateway_fee_deduction
  /// - founder_60 = 60% of net_profit
  /// - host_25 = 25% of net_profit
  /// - investor_15 = 15% of net_profit
  factory FinancialBreakdown.calculate({required double totalCollection}) {
    if (totalCollection <= 0) {
      return FinancialBreakdown(
        totalEntryCollection: 0,
        platformCommissionGross: 0,
        gatewayFeeDeduction: 0,
        netProfit: 0,
        shares: ProfitShares(founder60: 0, host25: 0, investor15: 0),
      );
    }
    final grossComm = totalCollection * 0.25;
    final gatewayFee = totalCollection * 0.0236;
    final net = grossComm - gatewayFee;
    final netProfit = net > 0 ? net : 0.0;

    return FinancialBreakdown(
      totalEntryCollection: totalCollection,
      platformCommissionGross: grossComm,
      gatewayFeeDeduction: gatewayFee,
      netProfit: netProfit,
      shares: ProfitShares(
        founder60: double.parse((netProfit * 0.60).toStringAsFixed(2)),
        host25: double.parse((netProfit * 0.25).toStringAsFixed(2)),
        investor15: double.parse((netProfit * 0.15).toStringAsFixed(2)),
      ),
    );
  }
}

class PrizePool {
  double totalPool;
  double perKill;
  double firstPlace;
  double? secondPlace;
  double? thirdPlace;
  double? fourthPlace;
  double? fifthPlace;

  PrizePool({
    required this.totalPool,
    required this.perKill,
    required this.firstPlace,
    this.secondPlace,
    this.thirdPlace,
    this.fourthPlace,
    this.fifthPlace,
  });

  Map<String, dynamic> toJson() => {
    'totalPool': totalPool,
    'perKill': perKill,
    'firstPlace': firstPlace,
    'secondPlace': secondPlace,
    'thirdPlace': thirdPlace,
    'fourthPlace': fourthPlace,
    'fifthPlace': fifthPlace,
  };

  factory PrizePool.fromJson(Map<String, dynamic> json) => PrizePool(
    totalPool: ((json['totalPool'] ?? 0) as num).toDouble(),
    perKill: ((json['perKill'] ?? 0) as num).toDouble(),
    firstPlace: ((json['firstPlace'] ?? 0) as num).toDouble(),
    secondPlace: json['secondPlace'] != null ? ((json['secondPlace']) as num).toDouble() : null,
    thirdPlace: json['thirdPlace'] != null ? ((json['thirdPlace']) as num).toDouble() : null,
    fourthPlace: json['fourthPlace'] != null ? ((json['fourthPlace']) as num).toDouble() : null,
    fifthPlace: json['fifthPlace'] != null ? ((json['fifthPlace']) as num).toDouble() : null,
  );
}

class MatchParticipant {
  String uid;
  String inGameName;
  String inGameUid;
  int slotNumber; // Specific slot chosen by user (e.g. 1 to 48)
  String paidWith; // 'AD_COINS' | 'DEPOSIT_CASH' | 'WINNING_CASH'
  double amountPaid;
  DateTime joinedAt;
  int kills;
  int? rank;
  double? prizeAwarded;
  bool isWinner;
  String? teamName; // 'Team A', 'Team B', 'Squad 1', etc.

  MatchParticipant({
    required this.uid,
    required this.inGameName,
    required this.inGameUid,
    required this.slotNumber,
    required this.paidWith,
    required this.amountPaid,
    required this.joinedAt,
    this.kills = 0,
    this.rank,
    this.prizeAwarded,
    this.isWinner = false,
    this.teamName,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'inGameName': inGameName,
    'inGameUid': inGameUid,
    'slotNumber': slotNumber,
    'paidWith': paidWith,
    'amountPaid': amountPaid,
    'joinedAt': joinedAt.toIso8601String(),
    'kills': kills,
    'rank': rank,
    'prizeAwarded': prizeAwarded,
    'isWinner': isWinner,
    'teamName': teamName,
  };

  factory MatchParticipant.fromJson(Map<String, dynamic> json) => MatchParticipant(
    uid: json['uid'] ?? '',
    inGameName: json['inGameName'] ?? '',
    inGameUid: json['inGameUid'] ?? '',
    slotNumber: (json['slotNumber'] ?? 1) as int,
    paidWith: json['paidWith'] ?? 'DEPOSIT_CASH',
    amountPaid: ((json['amountPaid'] ?? 0) as num).toDouble(),
    joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt']) : DateTime.now(),
    kills: (json['kills'] ?? 0) as int,
    rank: json['rank'] != null ? (json['rank'] as int) : null,
    prizeAwarded: json['prizeAwarded'] != null ? ((json['prizeAwarded']) as num).toDouble() : null,
    isWinner: json['isWinner'] ?? false,
    teamName: json['teamName'],
  );
}

class MatchModel {
  String id;
  String title;
  String? bannerImage;
  GameType gameType;
  MatchMode mode; // br, cs, loneWolf
  TeamType teamType; // solo, duo, squad
  MatchFormat matchFormat;
  MapType map;
  MatchType matchType;
  EntryFeeType entryFeeType;
  double entryFee; // e.g. 5 Ad Coins for Free, or ₹25 for Paid
  PrizePool prizePool;
  int maxSlots; // e.g. 50 (BR), 8 (CS 4v4), 2 (1v1), 4 (2v2)
  int filledSlots;
  MatchCredentials credentials;
  MatchStatus status;
  DateTime matchTime;
  List<MatchParticipant> participants;
  List<RegisteredTeam> registeredTeams;
  bool hasUserWatchedAdToUnlockRoom;
  DateTime? completedAt;
  DateTime? roomFillingStartedAt; // Timestamp when match reached 100% capacity (15-min countdown)
  String? hostName;
  FinancialBreakdown? financialBreakdown;

  MatchModel({
    required this.id,
    required this.title,
    this.bannerImage,
    required this.gameType,
    MatchMode? mode,
    TeamType? teamType,
    required this.matchFormat,
    required this.map,
    required this.matchType,
    required this.entryFeeType,
    required this.entryFee,
    required this.prizePool,
    required this.maxSlots,
    required this.filledSlots,
    required this.credentials,
    required this.status,
    required this.matchTime,
    required this.participants,
    List<RegisteredTeam>? registeredTeams,
    this.hasUserWatchedAdToUnlockRoom = false,
    this.completedAt,
    this.roomFillingStartedAt,
    this.hostName,
    this.financialBreakdown,
  })  : mode = mode ?? _inferMode(matchFormat),
        teamType = teamType ?? _inferTeamType(matchFormat),
        registeredTeams = registeredTeams ?? [];

  static MatchMode _inferMode(MatchFormat format) {
    if (format == MatchFormat.cs4v4) return MatchMode.cs;
    if (format == MatchFormat.loneWolf1v1 || format == MatchFormat.loneWolf2v2) return MatchMode.loneWolf;
    return MatchMode.br;
  }

  static TeamType _inferTeamType(MatchFormat format) {
    if (format == MatchFormat.duo || format == MatchFormat.loneWolf2v2) return TeamType.duo;
    if (format == MatchFormat.squad || format == MatchFormat.cs4v4) return TeamType.squad;
    return TeamType.solo;
  }

  // --- 75/25 AUTO-DISTRIBUTION FINANCIAL ENGINE ---
  double get totalCollection => entryFee * maxSlots;
  double get adminCommission => matchType == MatchType.paid ? (totalCollection * 0.25) : 0;
  double get distributablePrizePool => matchType == MatchType.paid ? (totalCollection * 0.75) : prizePool.totalPool;

  int get maxPossibleKills => maxSlots > 1 ? (maxSlots - 1) : 0;
  double get reservedKillPool => maxPossibleKills * prizePool.perKill;
  double get rankPrizePool {
    final pool = distributablePrizePool - reservedKillPool;
    return pool > 0 ? pool : 0;
  }

  int get teamSize {
    if (teamType == TeamType.squad || matchFormat == MatchFormat.squad || matchFormat == MatchFormat.cs4v4) return 4;
    if (teamType == TeamType.duo || matchFormat == MatchFormat.duo || matchFormat == MatchFormat.loneWolf2v2) return 2;
    return 1;
  }

  int get totalTeams => (maxSlots / teamSize).ceil();

  // Standard Esports Percentage Distribution based on Distribution Mode (Top 3, Top 5, Top 10)
  double getRankPercentage(int rank, {String? distMode}) {
    final mode = distMode ?? (prizePool.fifthPlace != null ? 'top5' : (prizePool.thirdPlace != null ? 'top3' : 'top10'));
    if (mode == 'top3') {
      if (rank == 1) return 0.50; // 50%
      if (rank == 2) return 0.30; // 30%
      if (rank == 3) return 0.20; // 20%
      return 0.0;
    } else if (mode == 'top5') {
      if (rank == 1) return 0.40; // 40%
      if (rank == 2) return 0.25; // 25%
      if (rank == 3) return 0.15; // 15%
      if (rank == 4) return 0.10; // 10%
      if (rank == 5) return 0.10; // 10%
      return 0.0;
    } else {
      // Top 10
      if (rank == 1) return 0.30; // 30%
      if (rank == 2) return 0.20; // 20%
      if (rank == 3) return 0.15; // 15%
      if (rank == 4 || rank == 5) return 0.075; // 7.5% each
      if (rank >= 6 && rank <= 10) return 0.04; // 4% each
      return 0.0;
    }
  }

  double getTeamRankPrize(int rank) {
    if (rank == 1 && prizePool.firstPlace > 0) return prizePool.firstPlace;
    if (rank == 2 && prizePool.secondPlace != null && prizePool.secondPlace! > 0) return prizePool.secondPlace!;
    if (rank == 3 && prizePool.thirdPlace != null && prizePool.thirdPlace! > 0) return prizePool.thirdPlace!;
    if (rank == 4 && prizePool.fourthPlace != null && prizePool.fourthPlace! > 0) return prizePool.fourthPlace!;
    if (rank == 5 && prizePool.fifthPlace != null && prizePool.fifthPlace! > 0) return prizePool.fifthPlace!;
    return rankPrizePool * getRankPercentage(rank);
  }

  double getIndividualRankPrize(int rank) {
    return getTeamRankPrize(rank) / (teamSize > 0 ? teamSize : 1);
  }

  double calculatePlayerPayout({required int rank, required int kills}) {
    if (isTeamBasedMode) {
      // CS / Lone Wolf: 100% of distributable pool divided equally among winning team
      final winningTeamSize = (maxSlots / 2).ceil();
      if (rank == 1) {
        return distributablePrizePool / (winningTeamSize > 0 ? winningTeamSize : 1);
      }
      return 0.0;
    }

    // BR Mode: Auto percentage rank prize + individual kills
    final rankMoney = getIndividualRankPrize(rank);
    final killMoney = kills * prizePool.perKill;
    return rankMoney + killMoney;
  }

  bool get isTeamBasedMode => mode == MatchMode.cs || mode == MatchMode.loneWolf;

  List<MatchParticipant> get teamAParticipants {
    final half = (maxSlots / 2).ceil();
    return participants.where((p) => p.teamName == 'Team A' || (p.teamName == null && p.slotNumber <= half)).toList();
  }

  List<MatchParticipant> get teamBParticipants {
    final half = (maxSlots / 2).ceil();
    return participants.where((p) => p.teamName == 'Team B' || (p.teamName == null && p.slotNumber > half)).toList();
  }

  RegisteredTeam? getTeamForUser(String uid) {
    try {
      return registeredTeams.firstWhere((t) => t.hasMember(uid) || t.captainUid == uid);
    } catch (_) {
      return null;
    }
  }

  RegisteredTeam? getTeamByCode(String code) {
    try {
      return registeredTeams.firstWhere((t) => t.teamCode.toUpperCase() == code.trim().toUpperCase());
    } catch (_) {
      return null;
    }
  }

  bool isSlotTaken(int slotNum) {
    return participants.any((p) => p.slotNumber == slotNum);
  }

  MatchParticipant? getParticipantBySlot(int slotNum) {
    try {
      return participants.firstWhere((p) => p.slotNumber == slotNum);
    } catch (_) {
      return null;
    }
  }

  bool get isFull => filledSlots >= maxSlots && maxSlots > 0;
  bool get isFillingRoom => status == MatchStatus.roomFilling || (isFull && status == MatchStatus.upcoming);

  Duration get roomCountdownRemaining {
    if (roomFillingStartedAt == null) {
      return const Duration(minutes: 15);
    }
    final elapsed = DateTime.now().difference(roomFillingStartedAt!);
    final remaining = const Duration(minutes: 15) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'bannerImage': bannerImage,
    'gameType': gameType.name,
    'mode': mode.name,
    'teamType': teamType.name,
    'matchFormat': matchFormat.name,
    'map': map.name,
    'matchType': matchType.name,
    'entryFeeType': entryFeeType.name,
    'entryFee': entryFee,
    'prizePool': prizePool.toJson(),
    'maxSlots': maxSlots,
    'filledSlots': filledSlots,
    'credentials': credentials.toJson(),
    'status': status == MatchStatus.completed
        ? 'COMPLETED'
        : (status == MatchStatus.roomFilling ? 'FILLING_ROOM' : status.name),
    'room_filling_started_at': roomFillingStartedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'host_name': hostName,
    'financial_breakdown': financialBreakdown?.toJson(),
    'matchTime': matchTime.toIso8601String(),
    'participants': participants.map((p) => p.toJson()).toList(),
    'registeredTeams': registeredTeams.map((t) => t.toJson()).toList(),
    'hasUserWatchedAdToUnlockRoom': hasUserWatchedAdToUnlockRoom,
  };

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    final format = MatchFormat.values.firstWhere((e) => e.name == json['matchFormat'], orElse: () => MatchFormat.solo);
    final mode = json['mode'] != null
        ? MatchMode.values.firstWhere((e) => e.name == json['mode'], orElse: () => _inferMode(format))
        : _inferMode(format);
    final teamType = json['teamType'] != null
        ? TeamType.values.firstWhere((e) => e.name == json['teamType'], orElse: () => _inferTeamType(format))
        : _inferTeamType(format);

    MatchStatus parseStatus(dynamic st) {
      if (st == 'COMPLETED' || st == 'completed') return MatchStatus.completed;
      if (st == 'ONGOING' || st == 'ongoing') return MatchStatus.ongoing;
      if (st == 'CANCELLED' || st == 'cancelled') return MatchStatus.cancelled;
      if (st == 'FILLING_ROOM' || st == 'roomFilling' || st == 'filling_room') return MatchStatus.roomFilling;
      return MatchStatus.upcoming;
    }

    return MatchModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      bannerImage: json['bannerImage'],
      gameType: GameType.values.firstWhere((e) => e.name == json['gameType'], orElse: () => GameType.freeFire),
      mode: mode,
      teamType: teamType,
      matchFormat: format,
      map: MapType.values.firstWhere((e) => e.name == json['map'], orElse: () => MapType.bermuda),
      matchType: MatchType.values.firstWhere((e) => e.name == json['matchType'], orElse: () => MatchType.free),
      entryFeeType: EntryFeeType.values.firstWhere((e) => e.name == json['entryFeeType'], orElse: () => EntryFeeType.adCoins),
      entryFee: ((json['entryFee'] ?? 0) as num).toDouble(),
      prizePool: PrizePool.fromJson(json['prizePool'] ?? {}),
      maxSlots: (json['maxSlots'] ?? 48) as int,
      filledSlots: (json['filledSlots'] ?? 0) as int,
      credentials: MatchCredentials.fromJson(json['credentials'] ?? {}),
      status: parseStatus(json['status']),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : (json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null),
      roomFillingStartedAt: json['room_filling_started_at'] != null
          ? DateTime.parse(json['room_filling_started_at'])
          : (json['roomFillingStartedAt'] != null ? DateTime.parse(json['roomFillingStartedAt']) : null),
      hostName: json['host_name'] ?? json['hostName'],
      financialBreakdown: json['financial_breakdown'] != null
          ? FinancialBreakdown.fromJson(Map<String, dynamic>.from(json['financial_breakdown']))
          : (json['financialBreakdown'] != null ? FinancialBreakdown.fromJson(Map<String, dynamic>.from(json['financialBreakdown'])) : null),
      matchTime: json['matchTime'] != null ? DateTime.parse(json['matchTime']) : DateTime.now().add(const Duration(minutes: 30)),
      participants: (json['participants'] as List<dynamic>?)
              ?.map((p) => MatchParticipant.fromJson(p))
              .toList() ??
          [],
      registeredTeams: (json['registeredTeams'] as List<dynamic>?)
              ?.map((t) => RegisteredTeam.fromJson(t))
              .toList() ??
          [],
      hasUserWatchedAdToUnlockRoom: json['hasUserWatchedAdToUnlockRoom'] ?? false,
    );
  }
}
