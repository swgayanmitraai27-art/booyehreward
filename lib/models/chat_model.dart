class ChatMessage {
  final String id;
  final String uid;
  final String senderName;
  final String text;
  final String timestamp;

  ChatMessage({
    required this.id,
    required this.uid,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Gamer',
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp,
    };
  }
}
