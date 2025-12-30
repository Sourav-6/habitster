import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_message.dart';

class ChatSession {
  final String id;
  final List<ChatMessage> messages;
  final DateTime createdAt;

  ChatSession({
    required this.id,
    required this.messages,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'messages': messages.map((m) => m.toMap()).toList(),
    };
  }

  factory ChatSession.fromMap(Map map) {
    return ChatSession(
      id: map['id'],
      createdAt: DateTime.parse(map['createdAt']),
      messages: (map['messages'] as List)
          .map((e) => ChatMessage.fromMap(Map.from(e)))
          .toList(),
    );
  }
}

class ChatHistoryService {
  static final _box = Hive.box('chat_history');
  static const _sessionsKey = 'sessions';
  static const _activeKey = 'active';

  static const _uuid = Uuid();

  /// -------- Active session --------

  static ChatSession getActiveSession() {
    final raw = _box.get(_activeKey);
    if (raw == null) {
      final session = ChatSession(
        id: _uuid.v4(),
        messages: [],
        createdAt: DateTime.now(),
      );
      _box.put(_activeKey, session.toMap());
      return session;
    }
    return ChatSession.fromMap(Map.from(raw));
  }

  static void saveActiveSession(ChatSession session) {
    _box.put(_activeKey, session.toMap());
  }

  /// -------- Message handling --------

  static List<ChatMessage> getMessages() {
    return getActiveSession().messages;
  }

  static void addMessage(ChatMessage message) {
    final session = getActiveSession();
    session.messages.add(message);
    saveActiveSession(session);
  }

  /// -------- Clear chat (UI only) --------

  static void clearCurrentChat() {
    final session = getActiveSession();
    session.messages.clear();
    saveActiveSession(session);
  }

  /// -------- New chat --------

  static void startNewChat() {
    final old = getActiveSession();

    if (old.messages.isNotEmpty) {
      final list = getSessions();
      list.add(old);
      _box.put(_sessionsKey, list.map((s) => s.toMap()).toList());
    }

    final fresh = ChatSession(
      id: _uuid.v4(),
      messages: [],
      createdAt: DateTime.now(),
    );

    saveActiveSession(fresh);
  }

  /// -------- History --------

  static List<ChatSession> getSessions() {
    final raw = _box.get(_sessionsKey);
    if (raw == null) return [];
    return (raw as List).map((e) => ChatSession.fromMap(Map.from(e))).toList();
  }
}
