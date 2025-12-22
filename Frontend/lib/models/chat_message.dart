class ChatMessage {
  final String role; // "user" or "agent"
  final String text;
  final DateTime time;

  ChatMessage({
    required this.role,
    required this.text,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'text': text,
      'time': time.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map map) {
    return ChatMessage(
      role: map['role'],
      text: map['text'],
      time: DateTime.parse(map['time']),
    );
  }
}
