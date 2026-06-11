// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

void cleanAuthCallbackUrl() {
  final uri = Uri.base;
  final hasAuthCallback =
      uri.queryParameters.containsKey('code') ||
      uri.queryParameters.containsKey('error') ||
      uri.queryParameters.containsKey('error_description');
  if (!hasAuthCallback) return;

  final cleanUri = uri.replace(queryParameters: const {});
  html.window.history.replaceState(null, html.document.title, cleanUri.toString());
}
