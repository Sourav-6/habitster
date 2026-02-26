import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../models/chat_message.dart';
import '../../../services/chat_history_service.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ChatSession? session;
  final controller = TextEditingController();
  final api = ApiService();

  List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    session = ChatHistoryService.createNewSession();
    messages = [];
    maybeTriggerProactive();
  }

  void openSession(ChatSession s) {
    ChatHistoryService.setActiveSession(s);
    setState(() {
      session = s;
      messages = List.from(s.messages);
    });
  }

// Start a new chat session......

  void startNewChat() {
    if (messages.isNotEmpty && ChatHistoryService.isMeaningfulChat(messages)) {
      final title = ChatHistoryService.generateTitle(messages);

      final finishedSession = ChatSession(
        id: session!.id,
        title: title,
        messages: List.from(messages),
        createdAt: session!.createdAt,
      );

      ChatHistoryService.saveSession(finishedSession);
    }

    session = ChatHistoryService.createNewSession();
    setState(() {
      messages = [];
    });
  }

// Clear chat messages in the current session......

  void clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Clear chat?"),
        content: const Text("This will clear the current chat only."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Clear"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        messages.clear();
      });

      // reset active session messages (do NOT save)
      ChatHistoryService.updateActiveSessionMessages([]);
    }
  }

// Trigger proactive message if chat is empty......

  void maybeTriggerProactive() async {
    if (messages.isNotEmpty) return;

    final res = await api.getProactiveMessage();
    if (res == null) return;

    final agentMsg = ChatMessage(
      role: "agent",
      text: res,
      time: DateTime.now(),
    );

    setState(() {
      messages.add(agentMsg);
    });

    ChatHistoryService.updateActiveSessionMessages(messages);
  }

// Send message to AI agent with context......

  void send() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    controller.clear();

    // -------- USER MESSAGE --------
    final userMsg = ChatMessage(
      role: "user",
      text: text,
      time: DateTime.now(),
    );

    setState(() {
      messages.add(userMsg);
    });

    // -------- CONTEXT (last 20 messages from current session) --------
    final List<ChatMessage> contextMessages = messages.length <= 20
        ? List<ChatMessage>.from(messages)
        : List<ChatMessage>.from(
            messages.sublist(messages.length - 20),
          );

    // -------- AGENT RESPONSE --------
    final res = await api.sendMessageToAgentWithContext(
      text,
      contextMessages,
    );

    final agentMsg = ChatMessage(
      role: "agent",
      text: res,
      time: DateTime.now(),
    );

    setState(() {
      messages.add(agentMsg);
    });

    // -------- UPDATE ACTIVE SESSION --------
    ChatHistoryService.updateActiveSessionMessages(messages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text("AI Coach"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: clearChat,
            tooltip: "Clear Chat",
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: startNewChat,
            tooltip: "New Chat",
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Chats",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView(
                  children: ChatHistoryService.getSessions().map((s) {
                    return ListTile(
                      title: Text(
                        s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        DateFormat('MMM d, HH:mm').format(s.createdAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(context); // close drawer
                        openSession(s);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Type here...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: send, child: const Text("Send")),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  return Align(
                    alignment: msg.role == "user"
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: msg.role == "user"
                            ? Colors.blue.withAlpha(40)
                            : Colors.grey.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(msg.text),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
