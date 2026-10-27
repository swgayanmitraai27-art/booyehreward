class SupportTicket {
  final String ticketId;
  final String uid;
  final String userName;
  final String category;
  final String subject;
  final String status; // OPEN | REPLIED | RESOLVED
  final List<SupportMessage> messages;
  final String createdAt;
  final String updatedAt;

  SupportTicket({
    required this.ticketId,
    required this.uid,
    required this.userName,
    required this.category,
    required this.subject,
    required this.status,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    var rawMsgs = json['messages'] as List? ?? [];
    List<SupportMessage> parsed = rawMsgs.map((m) => SupportMessage.fromJson(m as Map<String, dynamic>)).toList();

    return SupportTicket(
      ticketId: json['ticketId'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Player',
      category: json['category'] as String? ?? 'General Help',
      subject: json['subject'] as String? ?? 'Support Request',
      status: json['status'] as String? ?? 'OPEN',
      messages: parsed,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }
}

class SupportMessage {
  final String sender; // user | admin
  final String text;
  final String time;

  SupportMessage({
    required this.sender,
    required this.text,
    required this.time,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      sender: json['sender'] as String? ?? 'user',
      text: json['text'] as String? ?? '',
      time: json['time'] as String? ?? '',
    );
  }
}
