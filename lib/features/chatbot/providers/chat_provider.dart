import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/chatbot_constants.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';

/// Provider for Ace AI chat messages, persistence, loading, and retry state.
class ChatProvider extends ChangeNotifier {
  final AiService _aiService;
  final Uuid _uuid;
  final List<ChatMessage> _messages = [];

  bool _isTyping = false;
  String? _errorMessage;

  ChatProvider({AiService? aiService, Uuid? uuid})
    : _aiService = aiService ?? AiService(),
      _uuid = uuid ?? const Uuid() {
    _loadHistory();
  }

  /// Current ordered chat messages.
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// Whether Ace AI is typing.
  bool get isTyping => _isTyping;

  /// Last user-facing error message, if any.
  String? get errorMessage => _errorMessage;

  /// Whether the chat has an active error.
  bool get hasError => _errorMessage != null;

  /// True when at least one bot message has been added.
  bool get hasUnreadBotMessages => _messages.any((message) => !message.isUser);

  /// Loads local history or adds the welcome message on first open.
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(kAceAiChatHistoryKey);
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _messages
          ..clear()
          ..addAll(
            list.map(
              (item) => ChatMessage.fromJson(item as Map<String, dynamic>),
            ),
          );
      }
    } catch (error) {
      _messages.clear();
      _errorMessage = 'Could not load saved chat history.';
    }
    if (_messages.isEmpty) {
      _messages.add(
        ChatMessage(
          id: _uuid.v4(),
          text:
              "Hi! I'm Ace AI, your IT assistant from Ace Technologies. I can help you find products, get service quotes, track orders, or answer any IT questions. What can I help you with today?",
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
      try {
        await _saveHistory();
      } catch (_) {
        _errorMessage = 'Could not save chat history.';
      }
    }
    notifyListeners();
  }

  /// Sends a message to Ace AI and appends the response.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isTyping) return;
    final capped = trimmed.length > 500 ? trimmed.substring(0, 500) : trimmed;

    _errorMessage = null;
    final userMessage = ChatMessage(
      id: _uuid.v4(),
      text: capped,
      isUser: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );
    _messages.add(userMessage);
    _isTyping = true;
    notifyListeners();
    try {
      await _saveHistory();
    } catch (_) {
      _errorMessage = 'Could not save chat history.';
    }

    try {
      final reply = await _aiService.sendMessage(_messages, capped);
      _messages.add(
        ChatMessage(
          id: _uuid.v4(),
          text: reply,
          isUser: false,
          timestamp: DateTime.now(),
        ),
      );
    } catch (error) {
      _errorMessage = error.toString().isEmpty
          ? 'No internet connection. Please check your network.'
          : error.toString();
      _messages.add(userMessage.copyWith(status: MessageStatus.error));
    } finally {
      _isTyping = false;
      notifyListeners();
      try {
        await _saveHistory();
      } catch (_) {
        _errorMessage = 'Could not save chat history.';
      }
    }
  }

  /// Clears persisted and in-memory chat history.
  Future<void> clearChat() async {
    _messages.clear();
    _errorMessage = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kAceAiChatHistoryKey);
    } catch (error) {
      _errorMessage = 'Could not clear saved chat history.';
    }
    _messages.add(
      ChatMessage(
        id: _uuid.v4(),
        text:
            "Hi! I'm Ace AI, your IT assistant from Ace Technologies. I can help you find products, get service quotes, track orders, or answer any IT questions. What can I help you with today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
    try {
      await _saveHistory();
    } catch (_) {
      _errorMessage = 'Could not save chat history.';
    }
  }

  /// Retries the latest failed user message.
  Future<void> retryLastMessage() async {
    ChatMessage? failed;
    for (final message in _messages.reversed) {
      if (message.isUser && message.status == MessageStatus.error) {
        failed = message;
        break;
      }
    }
    if (failed == null) return;
    final failedMessage = failed;
    _messages.removeWhere((message) => message.id == failedMessage.id);
    notifyListeners();
    await sendMessage(failedMessage.text);
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = _messages
        .where((message) => message.status != MessageStatus.error)
        .toList()
        .reversed
        .take(50)
        .toList()
        .reversed
        .map((message) => message.toJson())
        .toList();
    await prefs.setString(kAceAiChatHistoryKey, jsonEncode(saved));
  }
}
