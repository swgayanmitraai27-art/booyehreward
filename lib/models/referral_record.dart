class ReferralRecord {
  final String id;
  final String referrerUid;
  final String referrerName;
  final String referrerCode;
  final String referredUid;
  final String referredName;
  final DateTime createdAt;
  final double bonusCashAwarded;
  final int adCoinsAwarded;

  ReferralRecord({
    required this.id,
    required this.referrerUid,
    required this.referrerName,
    required this.referrerCode,
    required this.referredUid,
    required this.referredName,
    required this.createdAt,
    this.bonusCashAwarded = 10.0,
    this.adCoinsAwarded = 10,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'referrerUid': referrerUid,
    'referrerName': referrerName,
    'referrerCode': referrerCode,
    'referredUid': referredUid,
    'referredName': referredName,
    'createdAt': createdAt.toIso8601String(),
    'bonusCashAwarded': bonusCashAwarded,
    'adCoinsAwarded': adCoinsAwarded,
  };

  factory ReferralRecord.fromJson(Map<String, dynamic> json) => ReferralRecord(
    id: json['id'] ?? 'ref_${DateTime.now().millisecondsSinceEpoch}',
    referrerUid: json['referrerUid'] ?? '',
    referrerName: json['referrerName'] ?? 'Inviter',
    referrerCode: json['referrerCode'] ?? '',
    referredUid: json['referredUid'] ?? '',
    referredName: json['referredName'] ?? 'Friend',
    createdAt: json['createdAt'] != null
        ? (DateTime.tryParse(json['createdAt'])?.toLocal() ?? DateTime.now())
        : DateTime.now(),
    bonusCashAwarded: ((json['bonusCashAwarded'] ?? 10.0) as num).toDouble(),
    adCoinsAwarded: json['adCoinsAwarded'] ?? 10,
  );
}
