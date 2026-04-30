class ConversationMessage {
  final int id;
  final String phone;
  final String message;
  final String role;
  final DateTime createdAt;

  bool get isUser => role == 'user';

  ConversationMessage.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        phone = json['phone'] as String,
        message = json['message'] as String,
        role = json['role'] as String,
        createdAt = DateTime.parse(json['created_at'] as String).toLocal();
}
