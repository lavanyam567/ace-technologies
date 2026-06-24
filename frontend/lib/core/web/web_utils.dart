// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'package:flutter/material.dart';

/// Web-specific utilities for the Ace Technologies platform
class WebUtils {
  /// Update the page title
  static void setPageTitle(String title) {
    html.document.title = title;
  }

  /// Get the current page title
  static String getPageTitle() {
    return html.document.title;
  }

  /// Update the page meta description
  static void setMetaDescription(String description) {
    final meta = html.document.querySelector('meta[name="description"]');
    if (meta != null) {
      meta.setAttribute('content', description);
    }
  }

  /// Add keyboard shortcut listener
  static void addKeyboardShortcut({
    required String key,
    required VoidCallback callback,
    bool ctrlKey = false,
    bool shiftKey = false,
    bool altKey = false,
  }) {
    html.document.addEventListener('keydown', (event) {
      if (event is html.KeyboardEvent) {
        if (event.key == key &&
            event.ctrlKey == ctrlKey &&
            event.shiftKey == shiftKey &&
            event.altKey == altKey) {
          event.preventDefault();
          callback();
        }
      }
    });
  }

  /// Check if running on web
  static bool isWeb() {
    try {
      return identical(0, 0.0); // Trick to detect web
    } catch (e) {
      return false;
    }
  }

  /// Get the current URL path
  static String getCurrentPath() {
    return html.window.location.pathname ?? '/';
  }

  /// Get URL query parameters
  static Map<String, String> getQueryParameters() {
    final params = <String, String>{};
    final uri = Uri.parse(html.window.location.href);
    uri.queryParameters.forEach((key, value) {
      params[key] = value;
    });
    return params;
  }

  /// Share content (if supported)
  static Future<void> shareContent({
    required String title,
    required String text,
    String? url,
  }) async {
    try {
      await html.window.navigator.share({
        'title': title,
        'text': text,
        'url': url ?? html.window.location.href,
      });
    } catch (e) {
      debugPrint('Share failed: $e');
    }
  }

  /// Copy text to clipboard
  static Future<void> copyToClipboard(String text) async {
    try {
      await html.window.navigator.clipboard?.writeText(text);
    } catch (e) {
      debugPrint('Copy to clipboard failed: $e');
    }
  }

  /// Get clipboard content
  static Future<String?> getClipboardContent() async {
    try {
      return await html.window.navigator.clipboard?.readText();
    } catch (e) {
      debugPrint('Get clipboard content failed: $e');
      return null;
    }
  }

  /// Check if device supports touch
  static bool supportsTouchInput() {
    final navigator = html.window.navigator;
    return (navigator.maxTouchPoints ?? 0) > 0;
  }

  /// Detect preferred color scheme (light/dark)
  static bool prefersDarkMode() {
    try {
      final media = html.window.matchMedia('(prefers-color-scheme: dark)');
      return media.matches;
    } catch (e) {
      return false;
    }
  }

  /// Listen to color scheme changes
  static void onColorSchemeChange(ValueChanged<bool> callback) {
    try {
      final media = html.window.matchMedia('(prefers-color-scheme: dark)');
      media.addEventListener('change', (event) {
        if (event is html.MediaQueryListEvent) {
          callback(event.matches ?? false);
        }
      });
    } catch (e) {
      debugPrint('Color scheme listener failed: $e');
    }
  }

  /// Get device pixel ratio (for retina displays)
  static double getDevicePixelRatio() {
    return html.window.devicePixelRatio.toDouble();
  }

  /// Check if browser supports specific feature
  static bool supportsFeature(String feature) {
    try {
      final css = html.document.body?.style;
      return css?.getPropertyValue(feature) != '';
    } catch (e) {
      return false;
    }
  }

  /// Print the page
  static void print() {
    html.window.print();
  }

  /// Download file
  static void downloadFile(String url, String fileName) {
    html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
  }

  /// Open URL in new tab
  static void openNewTab(String url) {
    html.window.open(url, '_blank');
  }

  /// Get browser information
  static String getBrowserInfo() {
    return html.window.navigator.userAgent;
  }

  /// Check if PWA is installed
  static bool isPWAInstalled() {
    try {
      return html.window.matchMedia('(display-mode: standalone)').matches ||
          html.window.matchMedia('(display-mode: fullscreen)').matches;
    } catch (e) {
      return false;
    }
  }

  /// Request fullscreen
  static Future<void> requestFullscreen(html.Element element) async {
    try {
      await element.requestFullscreen();
    } catch (e) {
      debugPrint('Fullscreen request failed: $e');
    }
  }

  /// Exit fullscreen
  static Future<void> exitFullscreen() async {
    try {
      html.document.exitFullscreen();
    } catch (e) {
      debugPrint('Exit fullscreen failed: $e');
    }
  }

  /// Request notification permission
  static Future<bool> requestNotificationPermission() async {
    try {
      final permission = await html.Notification.requestPermission();
      return permission == 'granted';
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
      return false;
    }
  }

  /// Show notification
  static void showNotification(String title, {String? body, String? icon}) {
    try {
      html.Notification(title, body: body, icon: icon);
    } catch (e) {
      debugPrint('Show notification failed: $e');
    }
  }

  /// Get viewport dimensions
  static Size getViewportSize() {
    final width = html.window.innerWidth ?? 0;
    final height = html.window.innerHeight ?? 0;
    return Size(width.toDouble(), height.toDouble());
  }

  /// Listen to viewport resize
  static void onViewportResize(VoidCallback callback) {
    html.window.onResize.listen((_) => callback());
  }

  /// Disable context menu (right-click)
  static void disableContextMenu() {
    html.document.onContextMenu.listen((event) {
      event.preventDefault();
    });
  }

  /// Get local storage value
  static String? getLocalStorage(String key) {
    return html.window.localStorage[key];
  }

  /// Set local storage value
  static void setLocalStorage(String key, String value) {
    html.window.localStorage[key] = value;
  }

  /// Remove local storage value
  static void removeLocalStorage(String key) {
    html.window.localStorage.remove(key);
  }

  /// Clear all local storage
  static void clearLocalStorage() {
    html.window.localStorage.clear();
  }

  /// Get session storage value
  static String? getSessionStorage(String key) {
    return html.window.sessionStorage[key];
  }

  /// Set session storage value
  static void setSessionStorage(String key, String value) {
    html.window.sessionStorage[key] = value;
  }
}

/// Web-aware image optimization
class WebImageOptimizer {
  /// Load image with webp fallback
  static String getOptimizedImageUrl(String imageUrl, {int? width}) {
    // If URL ends with common image extensions, add webp version
    if (imageUrl.endsWith('.jpg') || imageUrl.endsWith('.jpeg')) {
      // This would typically be handled by your backend
      // For now, just return original URL
      return imageUrl;
    }
    return imageUrl;
  }

  /// Get responsive image srcset
  static String getSrcSet(String baseUrl) {
    return '$baseUrl?w=480 480w, $baseUrl?w=768 768w, $baseUrl?w=1024 1024w';
  }

  /// Lazy load image data attribute
  static String lazyLoadDataAttribute(String imageUrl) {
    return 'data-src="$imageUrl"';
  }
}

/// Web performance utilities
class WebPerformance {
  /// Measure operation time
  static Future<T> measureTime<T>(
    String label,
    Future<T> Function() operation,
  ) async {
    final startTime = DateTime.now();
    try {
      return await operation();
    } finally {
      final duration = DateTime.now().difference(startTime);
      debugPrint('$label took ${duration.inMilliseconds}ms');
    }
  }

  /// Report Core Web Vitals
  static void reportWebVitals({
    required double lcp, // Largest Contentful Paint
    required double fid, // First Input Delay
    required double cls, // Cumulative Layout Shift
  }) {
    final vitals = 'LCP: ${lcp}ms, FID: ${fid}ms, CLS: $cls';
    debugPrint('Core Web Vitals: $vitals');
  }
}
