import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/chat_message.dart';

/// Displays a user or Ace AI message bubble.
class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;
  final VoidCallback? onNavigateProducts;
  final VoidCallback? onNavigateServices;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.onNavigateProducts,
    this.onNavigateServices,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.isUser;
    final isError = widget.message.status == MessageStatus.error;
    final cleanText = _cleanDisplayText(widget.message.text);
    final showReadMore = cleanText.length > 300;
    final displayedText = showReadMore && !_expanded
        ? '${cleanText.substring(0, 300)}...'
        : cleanText;
    final navigateProducts = widget.message.text.contains(
      '[NAVIGATE:products]',
    );
    final navigateServices = widget.message.text.contains(
      '[NAVIGATE:services]',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
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
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.75,
              ),
              child: GestureDetector(
                onLongPress: () async {
                  await Clipboard.setData(ClipboardData(text: cleanText));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message copied')),
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isError
                            ? const Color(0xFF5B1E24)
                            : isUser
                            ? const Color(0xFF1D9E75)
                            : const Color(0xFF1E2A3A),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isUser ? 18 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayedText,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                          if (showReadMore)
                            TextButton(
                              onPressed: () =>
                                  setState(() => _expanded = !_expanded),
                              child: Text(
                                _expanded ? 'Read less' : 'Read more',
                              ),
                            ),
                          if (isError)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Failed to send',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                  ),
                                  onPressed: widget.onRetry,
                                  tooltip: 'Retry',
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    if (navigateProducts || navigateServices)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: ActionChip(
                          label: Text(
                            navigateProducts
                                ? 'View Products →'
                                : 'View Services →',
                          ),
                          onPressed: navigateProducts
                              ? widget.onNavigateProducts
                              : widget.onNavigateServices,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('hh:mm a').format(widget.message.timestamp),
                        style: GoogleFonts.poppins(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _cleanDisplayText(String text) {
    return text.replaceAll(RegExp(r'\[NAVIGATE:[a-zA-Z_-]+\]'), '').trim();
  }
}
