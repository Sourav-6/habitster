import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../models/chat_message.dart';
import '../../../services/chat_history_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final api = ApiService();

  List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    messages = ChatHistoryService.getMessages();
  }

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

    ChatHistoryService.addMessage(userMsg);

    setState(() {
      messages.add(userMsg);
    });

    // -------- CONTEXT (last 20 messages) --------
    final allMessages = ChatHistoryService.getMessages();
    final contextMessages = allMessages.length <= 20
        ? allMessages
        : allMessages.sublist(allMessages.length - 20);

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

    ChatHistoryService.addMessage(agentMsg);

    setState(() {
      messages.add(agentMsg);
    });
  }

  // -------- CLEAR CHAT (UI ONLY) --------
  void clearChat() {
    ChatHistoryService.clearCurrentChat();
    setState(() {
      messages.clear();
    });
  }

  // -------- NEW CHAT --------
  void newChat() {
    ChatHistoryService.startNewChat();
    setState(() {
      messages = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Coach"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: newChat,
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: clearChat,
          ),
        ],
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
