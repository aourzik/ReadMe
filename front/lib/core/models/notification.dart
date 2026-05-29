class AppNotification {
  final String id;
  final String type; // loan_request | loan_accepted | loan_declined | message_received
  final DateTime createdAt;
  final bool read;
  final String? loanId;
  final String? bookTitle;
  final String fromUserId;
  final String fromUserName;
  final String? fromUserHandle;

  const AppNotification({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.read,
    this.loanId,
    this.bookTitle,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserHandle,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
    id:             json['id'] as String,
    type:           json['type'] as String,
    createdAt:      DateTime.parse(json['createdAt'] as String),
    read:           json['read'] as bool,
    loanId:         json['loanId'] as String?,
    bookTitle:      json['bookTitle'] as String?,
    fromUserId:     json['fromUserId'] as String,
    fromUserName:   json['fromUserName'] as String,
    fromUserHandle: json['fromUserHandle'] as String?,
  );

  String get title {
    switch (type) {
      case 'loan_request':  return '${fromUserName.split(' ').first} veut emprunter un livre';
      case 'loan_accepted': return 'Prêt accepté par ${fromUserName.split(' ').first}';
      case 'loan_declined': return 'Prêt refusé par ${fromUserName.split(' ').first}';
      case 'message_received': return 'Message de ${fromUserName.split(' ').first}';
      default: return 'Nouvelle notification';
    }
  }

  String get subtitle {
    switch (type) {
      case 'loan_request':  return bookTitle != null ? '« $bookTitle »' : '';
      case 'loan_accepted': return bookTitle != null ? '« $bookTitle »' : '';
      case 'loan_declined': return bookTitle != null ? '« $bookTitle »' : '';
      case 'message_received': return 'Appuie pour répondre';
      default: return '';
    }
  }
}
