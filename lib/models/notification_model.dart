enum NotificationType {
  matchFull,
  roomCredentials,
  matchResult,
  adminBroadcast,
  walletDeposit,
  systemAlert,
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String targetType; // 'all' | 'match' | 'user' | 'admin'
  final String? targetId;
  final String? matchId;
  final DateTime createdAt;
  bool isRead;
  final String? imageUrl;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.targetType = 'all',
    this.targetId,
    this.matchId,
    required this.createdAt,
    this.isRead = false,
    this.imageUrl,
    this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'type': type.name,
    'target_type': targetType,
    'target_id': targetId,
    'match_id': matchId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'is_read': isRead,
    'image_url': imageUrl,
    'data': data,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      final dateVal = json['created_at'] ?? json['createdAt'];
      if (dateVal != null) {
        parsedDate = DateTime.parse(dateVal.toString()).toLocal();
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return AppNotification(
      id: json['id']?.toString() ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.systemAlert,
      ),
      targetType: json['target_type']?.toString() ?? json['targetType']?.toString() ?? 'all',
      targetId: json['target_id']?.toString() ?? json['targetId']?.toString(),
      matchId: json['match_id']?.toString() ?? json['matchId']?.toString(),
      createdAt: parsedDate,
      isRead: json['is_read'] == true || json['isRead'] == true,
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
    );
  }
}
