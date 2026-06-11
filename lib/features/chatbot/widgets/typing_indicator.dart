import 'package:flutter/material.dart';

/// Left-aligned animated three-dot typing indicator for Ace AI.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: disabled ? Duration.zero : const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF1D9E75),
              child: Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2A3A),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (index) => _Dot(
                    controller: _controller,
                    offset: index * 0.16,
                    disabled: disabled,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final AnimationController controller;
  final double offset;
  final bool disabled;

  const _Dot({
    required this.controller,
    required this.offset,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    if (disabled) return const _StaticDot();
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = ((controller.value + offset) % 1.0);
        final y = -4 * (1 - (2 * t - 1).abs()).clamp(0.0, 1.0);
        return Transform.translate(offset: Offset(0, y), child: child);
      },
      child: const _StaticDot(),
    );
  }
}

class _StaticDot extends StatelessWidget {
  const _StaticDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: const BoxDecoration(
        color: Color(0xFF1D9E75),
        shape: BoxShape.circle,
      ),
    );
  }
}
