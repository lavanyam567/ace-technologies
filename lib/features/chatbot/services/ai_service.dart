import 'dart:async';

import '../models/chat_message.dart';

/// Local-only AI service for Ace Technologies chatbot.
/// Provides intelligent responses using local fallback logic.
class AiService {
  AiService();

  /// Sends a user message and returns a local bot response.
  Future<String> sendMessage(
    List<ChatMessage> history,
    String newMessage,
  ) async {
    final startedAt = DateTime.now();

    try {
      // Simulate slight delay for natural response
      final response = _generateLocalResponse(newMessage);
      await _ensureMinimumDelay(startedAt, const Duration(milliseconds: 500));
      return response;
    } catch (_) {
      await _ensureMinimumDelay(startedAt, const Duration(milliseconds: 500));
      return "I'm here to help! Try asking about our products, services, or orders.";
    }
  }

  Future<void> _ensureMinimumDelay(DateTime startedAt, Duration minimum) async {
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed < minimum) {
      await Future.delayed(minimum - elapsed);
    }
  }

  /// Generate smart local responses based on user input
  String _generateLocalResponse(String message) {
    final lower = message.toLowerCase();

    // Service booking queries
    if (lower.contains('book') ||
        lower.contains('service') ||
        lower.contains('cctv') ||
        lower.contains('quote')) {
      return 'Let me open the booking page for you! CCTV installation and IT services usually start from ₹2,500 and vary by scope. [NAVIGATE:services] What service are you planning?';
    }

    // Product/Shopping queries
    if (lower.contains('buy') ||
        lower.contains('cart') ||
        lower.contains('laptop') ||
        lower.contains('processor') ||
        lower.contains('product')) {
      return "I'll take you to that product right away! We can help with laptops, processors, networking devices, and printers across common business budgets. [NAVIGATE:products] What budget range should I filter for?";
    }

    // Order tracking queries
    if (lower.contains('order') || lower.contains('track')) {
      return 'You can track active orders from the Orders section. If you share your order ID, I can guide you to the right tracking page. Would you like to open orders?';
    }

    // Support/Contact queries
    if (lower.contains('support') ||
        lower.contains('contact') ||
        lower.contains('help')) {
      return 'Ace Technologies support is available Mon-Sat, 9 AM-6 PM IST at support@acetechnologies.in. We specialize in IT products, CCTV systems, and networking solutions. How can I assist you?';
    }

    // Price inquiries
    if (lower.contains('price') ||
        lower.contains('cost') ||
        lower.contains('how much')) {
      return 'Our products range from affordable processors at ₹18,999 to premium laptops over ₹70,000. Services start from ₹2,500. Would you like to browse our catalog? [NAVIGATE:products]';
    }

    // General greeting/fallback
    return 'I can help with IT products, CCTV installation, networking solutions, service bookings, and tech support. What would you like to explore today?';
  }
}
