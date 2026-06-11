import 'package:ace_technologies/features/chatbot/models/chat_message.dart';
import 'package:ace_technologies/features/chatbot/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MessageBubble renders user message variant', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0D1B2A),
          body: MessageBubble(
            message: ChatMessage(
              id: '1',
              text: 'Hello Ace AI',
              isUser: true,
              timestamp: DateTime(2026, 5, 5, 10),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hello Ace AI'), findsOneWidget);
    expect(find.text('A'), findsNothing);
  });

  testWidgets('MessageBubble renders bot message variant', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0D1B2A),
          body: MessageBubble(
            message: ChatMessage(
              id: '2',
              text: 'Hi, I can help with IT products.',
              isUser: false,
              timestamp: DateTime(2026, 5, 5, 10),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hi, I can help with IT products.'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });
}
