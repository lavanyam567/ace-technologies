import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/chatbot_constants.dart';

/// Horizontal animated quick reply suggestions for Ace AI.
class QuickReplyChips extends StatefulWidget {
  final ValueChanged<String> onSelected;

  const QuickReplyChips({super.key, required this.onSelected});

  @override
  State<QuickReplyChips> createState() => _QuickReplyChipsState();
}

class _QuickReplyChipsState extends State<QuickReplyChips>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);
    return FadeTransition(
      opacity: disabled ? const AlwaysStoppedAnimation(1) : _controller,
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            final reply = kQuickReplies[index];
            return ActionChip(
              side: const BorderSide(color: Color(0xFF1D9E75)),
              backgroundColor: Colors.transparent,
              label: Text(
                reply,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
              ),
              onPressed: () => widget.onSelected(reply),
            );
          },
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemCount: kQuickReplies.length,
        ),
      ),
    );
  }
}
