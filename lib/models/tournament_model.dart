class FFTournament {
  final String id;
  final String title;
  final String category; // BR | CS | LW | MEGA | CUSTOM
  final String mode;
  final String teamFormat; // solo | duo | squad
  final String map;
  final String bannerUrl;
  final int entryFeeCoins;
  final int totalSlots;
  final int filledSlots;
  final String status; // OPEN | LIVE | ENDED
  final String scheduleType; // dynamic | scheduled
  final String matchTimeText;
  final String scheduledTime;
  final FFPrizePool prizePool;
  final int roundNumber;
  final bool isMega;
  final List<FFGroup> groups;
  final bool isUserRegistered;
  final int? userSlot;
  final String? userGroup;

  FFTournament({
    required this.id,
    required this.title,
    required this.category,
    required this.mode,
    required this.teamFormat,
    required this.map,
    required this.bannerUrl,
    required this.entryFeeCoins,
    required this.totalSlots,
    required this.filledSlots,
    required this.status,
    required this.scheduleType,
    required this.matchTimeText,
    required this.scheduledTime,
    required this.prizePool,
    required this.roundNumber,
    required this.isMega,
    required this.groups,
    this.isUserRegistered = false,
    this.userSlot,
    this.userGroup,
  });

  factory FFTournament.fromJson(Map<String, dynamic> json) {
    var rawGroups = json['groups'] as List? ?? [];
    List<FFGroup> parsedGroups = rawGroups.map((g) => FFGroup.fromJson(g as Map<String, dynamic>)).toList();

    return FFTournament(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Free Fire Match',
      category: json['category'] as String? ?? 'BR',
      mode: json['mode'] as String? ?? 'Battle Royale (Solo)',
      teamFormat: json['teamFormat'] as String? ?? 'solo',
      map: json['map'] as String? ?? 'Bermuda',
      bannerUrl: json['bannerUrl'] as String? ?? 'https://vps.swgayanbhumi.in/uploads/br_banner.png',
      entryFeeCoins: (json['entryFeeCoins'] as num?)?.toInt() ?? 20,
      totalSlots: (json['totalSlots'] as num?)?.toInt() ?? 48,
      filledSlots: (json['filledSlots'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'OPEN',
      scheduleType: json['scheduleType'] as String? ?? 'dynamic',
      matchTimeText: json['matchTimeText'] as String? ?? 'Starts when Slots Full',
      scheduledTime: json['scheduledTime'] as String? ?? '',
      prizePool: FFPrizePool.fromJson(json['prizePool'] as Map<String, dynamic>? ?? {}),
      roundNumber: (json['roundNumber'] as num?)?.toInt() ?? 1,
      isMega: json['isMega'] as bool? ?? false,
      groups: parsedGroups,
      isUserRegistered: json['isUserRegistered'] as bool? ?? false,
      userSlot: (json['userSlot'] as num?)?.toInt(),
      userGroup: json['userGroup'] as String?,
    );
  }
}

class FFPrizePool {
  final int totalCoins;
  final int firstPlace;
  final int secondPlace;
  final int thirdPlace;
  final int perKill;

  FFPrizePool({
    this.totalCoins = 200,
    this.firstPlace = 200,
    this.secondPlace = 0,
    this.thirdPlace = 0,
    this.perKill = 0,
  });

  factory FFPrizePool.fromJson(Map<String, dynamic> json) {
    return FFPrizePool(
      totalCoins: (json['totalCoins'] as num?)?.toInt() ?? 200,
      firstPlace: (json['firstPlace'] as num?)?.toInt() ?? 200,
      secondPlace: (json['secondPlace'] as num?)?.toInt() ?? 0,
      thirdPlace: (json['thirdPlace'] as num?)?.toInt() ?? 0,
      perKill: (json['perKill'] as num?)?.toInt() ?? 0,
    );
  }
}

class FFGroup {
  final String groupId;
  final String groupName;
  final int maxSlots;
  final int filledSlots;
  final String roomId;
  final String roomPassword;
  final bool isCredentialsPublished;
  final String? publishedAt;
  final List<FFParticipant> participants;

  FFGroup({
    required this.groupId,
    required this.groupName,
    required this.maxSlots,
    required this.filledSlots,
    required this.roomId,
    required this.roomPassword,
    required this.isCredentialsPublished,
    this.publishedAt,
    required this.participants,
  });

  factory FFGroup.fromJson(Map<String, dynamic> json) {
    var rawParts = json['participants'] as List? ?? [];
    return FFGroup(
      groupId: json['groupId'] as String? ?? '',
      groupName: json['groupName'] as String? ?? 'Group A',
      maxSlots: (json['maxSlots'] as num?)?.toInt() ?? 48,
      filledSlots: (json['filledSlots'] as num?)?.toInt() ?? 0,
      roomId: json['roomId'] as String? ?? '',
      roomPassword: json['roomPassword'] as String? ?? '',
      isCredentialsPublished: json['isCredentialsPublished'] as bool? ?? false,
      publishedAt: json['publishedAt'] as String?,
      participants: rawParts.map((p) => FFParticipant.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }
}

class FFParticipant {
  final String uid;
  final String inGameName;
  final String inGameId;
  final int slotNo;
  final String? teamCode;
  final String? teamName;
  final String registeredAt;

  FFParticipant({
    required this.uid,
    required this.inGameName,
    required this.inGameId,
    required this.slotNo,
    this.teamCode,
    this.teamName,
    required this.registeredAt,
  });

  factory FFParticipant.fromJson(Map<String, dynamic> json) {
    return FFParticipant(
      uid: json['uid'] as String? ?? '',
      inGameName: json['inGameName'] as String? ?? 'Gamer',
      inGameId: json['inGameId'] as String? ?? '',
      slotNo: (json['slotNo'] as num?)?.toInt() ?? 1,
      teamCode: json['teamCode'] as String?,
      teamName: json['teamName'] as String?,
      registeredAt: json['registeredAt'] as String? ?? '',
    );
  }
}

class FFTeam {
  final String teamCode;
  final String tournamentId;
  final String teamName;
  final String captainUid;
  final int maxMembers;
  final List<Map<String, dynamic>> members;
  final bool isLocked;

  FFTeam({
    required this.teamCode,
    required this.tournamentId,
    required this.teamName,
    required this.captainUid,
    required this.maxMembers,
    required this.members,
    required this.isLocked,
  });

  factory FFTeam.fromJson(Map<String, dynamic> json) {
    return FFTeam(
      teamCode: json['teamCode'] as String? ?? '',
      tournamentId: json['tournamentId'] as String? ?? '',
      teamName: json['teamName'] as String? ?? 'My Squad',
      captainUid: json['captainUid'] as String? ?? '',
      maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 4,
      members: (json['members'] as List? ?? []).map((m) => Map<String, dynamic>.from(m as Map)).toList(),
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }
}
