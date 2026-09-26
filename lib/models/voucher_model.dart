class StoreItem {
  String id;
  String title;
  String description;
  String imageUrl; // Image URL or asset
  String iconEmoji;
  int rewardCoinsPrice; // Cost in 🎟️ Winning/Reward Coins
  String rewardValue; // e.g. "₹10 Code" or "100 💎"

  StoreItem({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl = '',
    required this.iconEmoji,
    required this.rewardCoinsPrice,
    required this.rewardValue,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'imageUrl': imageUrl,
    'iconEmoji': iconEmoji,
    'rewardCoinsPrice': rewardCoinsPrice,
    'rewardValue': rewardValue,
  };

  factory StoreItem.fromJson(Map<String, dynamic> json) => StoreItem(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    imageUrl: json['imageUrl'] ?? '',
    iconEmoji: json['iconEmoji'] ?? '🎁',
    rewardCoinsPrice: (json['rewardCoinsPrice'] ?? 50) as int,
    rewardValue: json['rewardValue'] ?? '',
  );
}

enum VoucherClaimStatus { pending, delivered, rejected }

class VoucherClaim {
  String id;
  String userId;
  String userName;
  String inGameUid;
  String whatsappNumber; // Captured during redemption for admin WhatsApp delivery!
  String itemTitle;
  int rewardCoinsSpent;
  VoucherClaimStatus status;
  String? redeemCode;
  DateTime requestedAt;
  DateTime? deliveredAt;

  VoucherClaim({
    required this.id,
    required this.userId,
    required this.userName,
    required this.inGameUid,
    required this.whatsappNumber,
    required this.itemTitle,
    required this.rewardCoinsSpent,
    required this.status,
    this.redeemCode,
    required this.requestedAt,
    this.deliveredAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'inGameUid': inGameUid,
    'whatsappNumber': whatsappNumber,
    'itemTitle': itemTitle,
    'rewardCoinsSpent': rewardCoinsSpent,
    'status': status.name,
    'redeemCode': redeemCode,
    'requestedAt': requestedAt.toIso8601String(),
    'deliveredAt': deliveredAt?.toIso8601String(),
  };

  factory VoucherClaim.fromJson(Map<String, dynamic> json) => VoucherClaim(
    id: json['id'] ?? '',
    userId: json['userId'] ?? '',
    userName: json['userName'] ?? '',
    inGameUid: json['inGameUid'] ?? '',
    whatsappNumber: json['whatsappNumber'] ?? '',
    itemTitle: json['itemTitle'] ?? '',
    rewardCoinsSpent: (json['rewardCoinsSpent'] ?? 0) as int,
    status: VoucherClaimStatus.values.firstWhere(
      (e) => e.name == json['status'],
      orElse: () => VoucherClaimStatus.pending,
    ),
    redeemCode: json['redeemCode'],
    requestedAt: json['requestedAt'] != null ? DateTime.parse(json['requestedAt']) : DateTime.now(),
    deliveredAt: json['deliveredAt'] != null ? DateTime.parse(json['deliveredAt']) : null,
  );
}
