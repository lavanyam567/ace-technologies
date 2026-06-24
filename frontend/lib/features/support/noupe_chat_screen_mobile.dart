import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NoupeChatScreen extends StatefulWidget {
  const NoupeChatScreen({super.key});

  @override
  State<NoupeChatScreen> createState() => _NoupeChatScreenState();
}

class _NoupeChatScreenState extends State<NoupeChatScreen> {
  static const _chatUrl = 'https://myapp-liart-five.vercel.app/noupe-chat.html';

  late final WebViewController _controller;
  var _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF4F7FB))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _error = null;
            });
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame == false) return;
            setState(() {
              _isLoading = false;
              _error = 'Unable to load Ace AI. Check your internet connection.';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_chatUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ace AI Support'),
        actions: [
          IconButton(
            onPressed: () => _controller.reload(),
            tooltip: 'Reload chat',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 56),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _controller.reload(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
