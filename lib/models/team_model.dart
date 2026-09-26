class TeamMember {
  String uid;
  String inGameName;
  String inGameUid;
  bool isCaptain;
  int slotNumber;
  DateTime joinedAt;
  double amountPaid;

  TeamMember({
    required this.uid,
    required this.inGameName,
    required this.inGameUid,
    this.isCaptain = false,
    required this.slotNumber,
    required this.joinedAt,
    required this.amountPaid,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'inGameName': inGameName,
    'inGameUid': inGameUid,
    'isCaptain': isCaptain,
    'slotNumber': slotNumber,
    'joinedAt': joinedAt.toIso8601String(),
    'amountPaid': amountPaid,
  };

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
    uid: json['uid'] ?? '',
    inGameName: json['inGameName'] ?? '',
    inGameUid: json['inGameUid'] ?? '',
    isCaptain: json['isCaptain'] ?? false,
    slotNumber: (json['slotNumber'] ?? 1) as int,
    joinedAt: json['joinedAt'] != null ? DateTime.parse(json['joinedAt']) : DateTime.now(),
    amountPaid: ((json['amountPaid'] ?? 0) as num).toDouble(),
  );
}

class RegisteredTeam {
  String teamId;
  String matchId;
  String teamCode; // Random 6-char code (e.g. BOY842)
  String captainUid;
  String captainName;
  int maxSize; // 2 for Duo, 4 for Squad
  String teamName;
  List<TeamMember> members;
  DateTime createdAt;

  RegisteredTeam({
    required this.teamId,
    required this.matchId,
    required this.teamCode,
    required this.captainUid,
    required this.captainName,
    required this.maxSize,
    required this.teamName,
    required this.members,
    required this.createdAt,
  });

  bool get isComplete => members.length >= maxSize;
  int get slotsRemaining => (maxSize - members.length).clamp(0, maxSize);

  bool hasMember(String uid) => members.any((m) => m.uid == uid);

  Map<String, dynamic> toJson() => {
    'teamId': teamId,
    'matchId': matchId,
    'teamCode': teamCode,
    'captainUid': captainUid,
    'captainName': captainName,
    'maxSize': maxSize,
    'teamName': teamName,
    'members': members.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory RegisteredTeam.fromJson(Map<String, dynamic> json) => RegisteredTeam(
    teamId: json['teamId'] ?? '',
    matchId: json['matchId'] ?? '',
    teamCode: json['teamCode'] ?? '',
    captainUid: json['captainUid'] ?? '',
    captainName: json['captainName'] ?? '',
    maxSize: (json['maxSize'] ?? 4) as int,
    teamName: json['teamName'] ?? 'Squad Team',
    members: (json['members'] as List<dynamic>?)
            ?.map((m) => TeamMember.fromJson(m))
            .toList() ??
        [],
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
  );
}
