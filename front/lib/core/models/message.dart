class ChatMessage {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;
  final bool fromMe;
  final String senderName;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.createdAt,
    this.readAt,
    required this.fromMe,
    required this.senderName,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id:         json['id'] as String,
    content:    json['content'] as String,
    createdAt:  DateTime.parse(json['createdAt'] as String),
    readAt:     json['readAt'] != null ? DateTime.parse(json['readAt'] as String) : null,
    fromMe:     json['fromMe'] as bool,
    senderName: json['senderName'] as String,
  );
}

class Conversation {
  final String partnerId;
  final String partnerName;
  final String? partnerHandle;
  final String lastMessage;
  final DateTime lastAt;
  final int unread;

  const Conversation({
    required this.partnerId,
    required this.partnerName,
    this.partnerHandle,
    required this.lastMessage,
    required this.lastAt,
    required this.unread,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    partnerId:     json['partnerId'] as String,
    partnerName:   json['partnerName'] as String,
    partnerHandle: json['partnerHandle'] as String?,
    lastMessage:   json['lastMessage'] as String,
    lastAt:        DateTime.parse(json['lastAt'] as String),
    unread:        (json['unread'] as num).toInt(),
  );
}
