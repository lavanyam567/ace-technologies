import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/quick_reply_chips.dart';
import '../widgets/typing_indicator.dart';

/// Full-page Ace AI chat experience.
class ChatScreen extends StatefulWidget {
  final String? initialMessage;

  const ChatScreen({super.key, this.initialMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sentInitialMessage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initial = widget.initialMessage?.trim();
      if (!_sentInitialMessage && initial != null && initial.isNotEmpty) {
        _sentInitialMessage = true;
        context.read<ChatProvider>().sendMessage(initial);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: MediaQuery.viewInsetsOf(context).bottom == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) FocusScope.of(context).unfocus();
      },
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ).apply(bodyColor: Colors.white, displayColor: Colors.white),
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: const Color(0xFF0D1B2A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0D1B2A),
            foregroundColor: Colors.white,
            titleSpacing: 0,
            title: const Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFF1D9E75),
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                _ChatTitle(),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Clear chat',
                onPressed: _confirmClear,
              ),
            ],
          ),
          body: Consumer<ChatProvider>(
            builder: (context, provider, child) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollToBottom(),
              );
              final showQuickReplies =
                  provider.messages.length <= 1 ||
                  (provider.messages.isNotEmpty &&
                      !provider.messages.last.isUser);
              return Column(
                children: [
                  Expanded(child: _buildMessages(provider)),
                  if (showQuickReplies && !provider.isTyping)
                    QuickReplyChips(onSelected: (text) => _send(text)),
                  if (provider.hasError && provider.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Text(
                        provider.errorMessage!,
                        style: GoogleFonts.poppins(
                          color: Colors.red.shade200,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  _buildInput(provider),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMessages(ChatProvider provider) {
    final entries = <Widget>[];
    DateTime? lastDate;
    for (final message in provider.messages) {
      final date = DateTime(
        message.timestamp.year,
        message.timestamp.month,
        message.timestamp.day,
      );
      if (lastDate == null || date != lastDate) {
        entries.add(_DateSeparator(date: message.timestamp));
        lastDate = date;
      }
      entries.add(
        MessageBubble(
          message: message,
          onRetry: provider.retryLastMessage,
          onNavigateProducts: () => context.go('/products'),
          onNavigateServices: () => context.go('/services'),
        ),
      );
    }
    if (provider.isTyping) entries.add(const TypingIndicator());

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      children: entries,
    );
  }

  Widget _buildInput(ChatProvider provider) {
    final length = _controller.text.characters.length;
    final canSend = _controller.text.trim().isNotEmpty && !provider.isTyping;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        color: const Color(0xFF0D1B2A),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: 4,
                minLines: 1,
                maxLength: length >= 400 ? 500 : null,
                textInputAction: TextInputAction.send,
                style: GoogleFonts.poppins(color: Colors.white),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => canSend ? _send(_controller.text) : null,
                decoration: InputDecoration(
                  counterStyle: GoogleFonts.poppins(color: Colors.white54),
                  hintText: 'Ask me anything about IT...',
                  hintStyle: GoogleFonts.poppins(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1E2A3A),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Color(0xFF1D9E75)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: canSend
                    ? const Color(0xFF1D9E75)
                    : Colors.grey.shade700,
              ),
              onPressed: canSend ? () => _send(_controller.text) : null,
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _controller.clear();
    setState(() {});
    await context.read<ChatProvider>().sendMessage(trimmed);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _confirmClear() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear chat?'),
        content: const Text('This will remove your saved Ace AI chat history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (shouldClear == true && mounted) {
      await context.read<ChatProvider>().clearChat();
    }
  }
}

class _ChatTitle extends StatelessWidget {
  const _ChatTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ace AI',
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'IT Assistant • Online',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final current = DateTime(date.year, date.month, date.day);
    final label = current == today
        ? 'Today'
        : current == today.subtract(const Duration(days: 1))
        ? 'Yesterday'
        : DateFormat('dd MMM yyyy').format(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
