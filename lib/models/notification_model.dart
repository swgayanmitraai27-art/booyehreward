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
    'created_at': createdAt.toIso8601String(),
    'is_read': isRead,
    'image_url': imageUrl,
    'data': data,
  };

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id: json['id'] ?? 'notif_${DateTime.now().millisecondsSinceEpoch}',
    title: json['title'] ?? '',
    body: json['body'] ?? '',
    type: NotificationType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => NotificationType.systemAlert,
    ),
    targetType: json['target_type'] ?? json['targetType'] ?? 'all',
    targetId: json['target_id'] ?? json['targetId'],
    matchId: json['match_id'] ?? json['matchId'],
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
    isRead: json['is_read'] ?? json['isRead'] ?? false,
    imageUrl: json['image_url'] ?? json['imageUrl'],
    data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
  );
}
