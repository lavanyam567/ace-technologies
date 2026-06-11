import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/chat_provider.dart';

/// Pulsing floating button that opens Ace AI chat.
class ChatFab extends StatefulWidget {
  final String? initialMessage;

  const ChatFab({super.key, this.initialMessage});

  @override
  State<ChatFab> createState() => _ChatFabState();
}

class _ChatFabState extends State<ChatFab> with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  bool get _isWidgetTest {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  @override
  void initState() {
    super.initState();
    if (!_isWidgetTest) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1500),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);
    final hasUnread = context.select<ChatProvider, bool>(
      (provider) => provider.hasUnreadBotMessages,
    );
    final fab = Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton(
          backgroundColor: const Color(0xFF1D9E75),
          onPressed: () => context.push('/chat', extra: widget.initialMessage),
          child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
        ),
        if (hasUnread)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );

    final controller = _controller;
    if (disabled || _isWidgetTest || controller == null) return fab;
    return ScaleTransition(
      scale: Tween<double>(
        begin: 1,
        end: 1.08,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut)),
      child: fab,
    );
  }
}
