import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    session = ChatHistoryService.createNewSession();
    messages = [];
    maybeTriggerProactive();
  }

  @override
  void dispose() {
    controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottomAfterFrame({bool force = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final position = _scrollController.position;
        // Only scroll if we are already near the bottom (within 100px) or forced
        final isNearBottom = position.pixels >= (position.maxScrollExtent - 100);
        if (isNearBottom || force) {
          _scrollController.animateTo(
            position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
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
    _scrollToBottomAfterFrame(force: true);
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
      _isLoading = true;
    });
    _scrollToBottomAfterFrame(force: true);

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
      _isLoading = false;
    });

    // -------- UPDATE ACTIVE SESSION --------
    ChatHistoryService.updateActiveSessionMessages(messages);
    // If it's a meaningful chat, auto-save it
    if (ChatHistoryService.isMeaningfulChat(messages)) {
      final title = messages.firstWhere((m) => m.role == "user").text;
      final finalTitle = title.length > 30 ? "${title.substring(0, 30)}..." : title;
      final updatedSession = ChatSession(
        id: session!.id,
        title: finalTitle,
        messages: List.from(messages),
        createdAt: session!.createdAt,
      );
      ChatHistoryService.saveSession(updatedSession);
      session = updatedSession;
    }
    _scrollToBottomAfterFrame(force: true);
  }

  void _renameSession(ChatSession s) async {
    final controller = TextEditingController(text: s.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF202123),
        title: Text("Rename Chat",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.poppins(color: Colors.white),
          decoration: const InputDecoration(
            enabledBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF0066))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Rename",
                style: TextStyle(
                    color: Color(0xFFFF0066), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty) {
      final updated = ChatSession(
        id: s.id,
        title: newTitle,
        messages: s.messages,
        createdAt: s.createdAt,
      );
      ChatHistoryService.saveSession(updated);
      setState(() {
        if (session?.id == s.id) session = updated;
      });
    }
  }

  void _deleteSession(ChatSession s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF202123),
        title: Text("Delete Chat?",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
        content: Text("Are you sure you want to delete this conversation?",
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete",
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ChatHistoryService.deleteSession(s.id);
      if (session?.id == s.id) {
        startNewChat();
      } else {
        setState(() {}); // refresh drawer
      }
    }
  }

  Widget _buildGlassmorphicBackground() {
    return Stack(
      children: [
        // Background gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [
                      const Color(0xFF121212),
                      const Color(0xFF1E1E2C),
                    ]
                  : [
                      const Color(0xFFF9F9FF), // Very light purple/white
                      const Color(0xFFF0F8FF), // Very light blue
                    ],
            ),
          ),
        ),

        // Static blobs for simplified chat background
        Positioned(
          top: -100,
          left: -80,
          child: _buildGradientBlob(
            [
              const Color(0xFFFF0066).withAlpha(40), // Pink
              const Color(0xFFFF9E80).withAlpha(30), // Light orange
            ],
            250,
          ),
        ),

        Positioned(
          bottom: -50,
          right: -80,
          child: _buildGradientBlob(
            [
              const Color(0xFF00CCFF).withAlpha(30), // Cyan
              const Color(0xFF2979FF).withAlpha(20), // Blue
            ],
            300,
          ),
        ),

        // Glassmorphic overlay
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withAlpha(150)
                : Colors.white.withAlpha(120),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientBlob(List<Color> colors, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor.withAlpha(200),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, 
                color: Theme.of(context).iconTheme.color),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Text(
          "AI Coach",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: Theme.of(context).iconTheme.color),
            onPressed: clearChat,
            tooltip: "Clear Chat",
          ),
          IconButton(
            icon: Icon(Icons.add, color: Theme.of(context).iconTheme.color),
            onPressed: startNewChat,
            tooltip: "New Chat",
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF171717), // Dark ChatGPT-style sidebar
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          startNewChat();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            border:
                                Border.all(color: Colors.white24, width: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.add,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                "New Chat",
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  "Recent Chats",
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: ChatHistoryService.getSessions().map((s) {
                    final isSelected = session?.id == s.id;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white12 : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        leading: const Icon(Icons.chat_bubble_outline,
                            color: Colors.white70, size: 16),
                        title: Text(
                          s.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontSize: 13),
                        ),
                        trailing: isSelected
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        color: Colors.white54, size: 14),
                                    onPressed: () => _renameSession(s),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.white54, size: 14),
                                    onPressed: () => _deleteSession(s),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context); // close drawer
                          openSession(s);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.settings_outlined,
                    color: Colors.white, size: 20),
                title: Text("Settings",
                    style:
                        GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildGlassmorphicBackground(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length && _isLoading) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(220),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                                bottomLeft: Radius.circular(5),
                                bottomRight: Radius.circular(20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(10),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildDot(0),
                                const SizedBox(width: 4),
                                _buildDot(150),
                                const SizedBox(width: 4),
                                _buildDot(300),
                              ],
                            ),
                          ).animate().fade().slideY(
                              begin: 0.1, end: 0, curve: Curves.easeOut),
                        );
                      }

                      final msg = messages[index];
                      final isUser = msg.role == "user";
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            gradient: isUser
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFF0066),
                                      Color(0xFFFF4081)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isUser ? null : Theme.of(context).cardColor.withAlpha(220),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isUser ? 20 : 5),
                              bottomRight: Radius.circular(isUser ? 5 : 20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isUser
                                    ? const Color(0xFFFF0066).withAlpha(40)
                                    : Colors.black.withAlpha(10),
                                blurRadius: 10,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: isUser
                              ? Text(
                                  msg.text,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                )
                              : _AnimatedMessageText(
                                  text: msg.text,
                                  onTick: _scrollToBottomAfterFrame,
                                ),
                        )
                            .animate()
                            .fade(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
                      );
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                  border: InputBorder.none,
                ),
                style: GoogleFonts.poppins(
                    color: Theme.of(context).textTheme.bodyLarge?.color),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => send(),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF0066), Color(0xFFFF4081)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
                onPressed: send,
              ),
            ),
          ],
        ),
      )
          .animate()
          .fade(duration: 600.ms)
          .slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack),
    );
  }

  Widget _buildDot(int delay) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFFFF0066),
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .scaleXY(
            begin: 0.5,
            end: 1.2,
            duration: 400.ms,
            curve: Curves.easeInOut,
            delay: delay.ms)
        .then(delay: 400.ms)
        .scaleXY(
            begin: 1.2, end: 0.5, duration: 400.ms, curve: Curves.easeInOut);
  }
}

class _AnimatedMessageText extends StatefulWidget {
  final String text;
  final VoidCallback onTick;

  const _AnimatedMessageText({
    required this.text,
    required this.onTick,
    Key? key,
  }) : super(key: key);

  @override
  State<_AnimatedMessageText> createState() => _AnimatedMessageTextState();
}

class _AnimatedMessageTextState extends State<_AnimatedMessageText>
    with SingleTickerProviderStateMixin {
  late List<String> _words;
  int _visibleCount = 0;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _words = RegExp(r'([ \t]+|\n|[^\s]+)')
        .allMatches(widget.text)
        .map((m) => m.group(0)!)
        .toList();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _words.length * 50),
    );

    _controller.addListener(() {
      final newCount = (_controller.value * _words.length).floor();
      if (newCount != _visibleCount) {
        setState(() {
          _visibleCount = newCount;
        });
        widget.onTick();
      }
    });

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedMessageText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _words = RegExp(r'([ \t]+|\n|[^\s]+)')
          .allMatches(widget.text)
          .map((m) => m.group(0)!)
          .toList();
      _visibleCount = 0;
      _controller.duration = Duration(milliseconds: _words.length * 50);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleWords = _words.take(_visibleCount).toList();

    return Wrap(
      children: visibleWords.map((word) {
        if (word == '\n') {
          return const SizedBox(width: double.infinity, height: 8);
        }
        return Text(
          word,
          style: GoogleFonts.poppins(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 15,
          ),
          // We can add a simple fade to each newly added word using flutter_animate
          // but since they are added dynamically, Animate on the widget works great.
        )
            .animate()
            .fade(duration: 200.ms)
            .slideX(begin: 0.2, end: 0, curve: Curves.easeOut);
      }).toList(),
    );
  }
}
