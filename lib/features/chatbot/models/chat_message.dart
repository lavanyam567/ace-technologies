/// Delivery state for a chat message.
enum MessageStatus { sending, sent, error }

/// A single user or Ace AI chat message.
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.status = MessageStatus.sent,
  });

  /// Returns a copy with selected values changed.
  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }

  /// Converts the message to JSON for local persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
    };
  }

  /// Builds a message from persisted JSON.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? MessageStatus.sent.name;
    return ChatMessage(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      isUser: json['isUser'] as bool? ?? false,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      status: MessageStatus.values.firstWhere(
        (status) => status.name == statusName,
        orElse: () => MessageStatus.sent,
      ),
    );
  }
}
