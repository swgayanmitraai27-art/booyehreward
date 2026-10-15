class NoticeMessage {
  final String id;
  final String senderUid;
  final String senderName;
  final String senderRole; // 'admin' or 'user'
  final String text;
  final DateTime createdAt;

  NoticeMessage({
    required this.id,
    required this.senderUid,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  bool get isAdmin => senderRole == 'admin' || senderUid == 'admin';

  factory NoticeMessage.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return NoticeMessage(
      id: json['id']?.toString() ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderUid: json['senderUid']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? 'Player',
      senderRole: json['senderRole']?.toString() ?? 'user',
      text: json['text']?.toString() ?? '',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderUid': senderUid,
      'senderName': senderName,
      'senderRole': senderRole,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class NoticeBoardData {
  final String title;
  final String body;
  final DateTime updatedAt;
  final bool allowUserMessages;
  final List<NoticeMessage> messages;

  NoticeBoardData({
    this.title = '📢 ज़रूरी सूचना (Official Admin Notice)',
    this.body = 'Booyah Rewards में आपका स्वागत है! यहाँ 100% फ्री टूर्नामेंट खेलें, 1 Ad = 1 Coin कमाएं और रिडीम कोड जीतें।',
    DateTime? updatedAt,
    this.allowUserMessages = false,
    this.messages = const [],
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory NoticeBoardData.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      parsedDate = json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final rawMessages = json['messages'];
    List<NoticeMessage> parsedMessages = [];
    if (rawMessages is List) {
      parsedMessages = rawMessages
          .whereType<Map>()
          .map((m) => NoticeMessage.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    return NoticeBoardData(
      title: json['title']?.toString() ?? '📢 ज़रूरी सूचना (Official Admin Notice)',
      body: json['body']?.toString() ?? 'Booyah Rewards में आपका स्वागत है! यहाँ 100% फ्री टूर्नामेंट खेलें, 1 Ad = 1 Coin कमाएं और रिडीम कोड जीतें।',
      updatedAt: parsedDate,
      allowUserMessages: json['allowUserMessages'] == true ||
          json['allowUserMessages']?.toString() == 'true',
      messages: parsedMessages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'updatedAt': updatedAt.toIso8601String(),
      'allowUserMessages': allowUserMessages,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  NoticeBoardData copyWith({
    String? title,
    String? body,
    DateTime? updatedAt,
    bool? allowUserMessages,
    List<NoticeMessage>? messages,
  }) {
    return NoticeBoardData(
      title: title ?? this.title,
      body: body ?? this.body,
      updatedAt: updatedAt ?? this.updatedAt,
      allowUserMessages: allowUserMessages ?? this.allowUserMessages,
      messages: messages ?? this.messages,
    );
  }
}
