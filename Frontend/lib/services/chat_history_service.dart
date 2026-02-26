import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';


class ChatSession {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'messages': messages.map((m) => m.toMap()).toList(),
      };

  static ChatSession fromMap(Map map) {
    return ChatSession(
      id: map['id'],
      title: map['title'],
      createdAt: DateTime.parse(map['createdAt']),
      messages: (map['messages'] as List)
          .map((e) => ChatMessage.fromMap(Map.from(e)))
          .toList(),
    );
  }
}

class ChatHistoryService {
  static final _box = Hive.box('chat_sessions');
  static const _uuid = Uuid();

  static ChatSession? activeSession;

  // -------- Sessions --------

  static List<ChatSession> getSessions() {
    return _box.values.map((e) => ChatSession.fromMap(Map.from(e))).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static void saveSession(ChatSession session) {
    _box.put(session.id, session.toMap());
  }

  static void deleteSession(String id) {
    _box.delete(id);
  }

  // -------- Active Session --------

  static ChatSession createNewSession() {
    final session = ChatSession(
      id: _uuid.v4(),
      title: "New chat",
      messages: [],
      createdAt: DateTime.now(),
    );

    activeSession = session;
    return session;
  }

  static void setActiveSession(ChatSession session) {
    activeSession = session;
  }

  static void updateActiveSessionMessages(List<ChatMessage> messages) {
    if (activeSession == null) return;
    activeSession = ChatSession(
      id: activeSession!.id,
      title: activeSession!.title,
      messages: messages,
      createdAt: activeSession!.createdAt,
    );
  }

  // -------- Helpers --------

  static bool isMeaningfulChat(List<ChatMessage> messages) {
    if (messages.length < 3) return false;

    return messages.any((m) =>
        m.text.length > 40 ||
        m.text.toLowerCase().contains("habit") ||
        m.text.toLowerCase().contains("task"));
  }

  static String generateTitle(List<ChatMessage> messages) {
    final userMsg = messages.firstWhere(
      (m) => m.role == "user",
      orElse: () => messages.first,
    );

    final text = userMsg.text.trim();
    return text.length > 32 ? "${text.substring(0, 32)}…" : text;
  }
}
