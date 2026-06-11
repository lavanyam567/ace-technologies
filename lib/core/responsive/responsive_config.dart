import 'package:flutter/material.dart';

/// Screen size breakpoints for responsive design
class ResponsiveBreakpoints {
  // Mobile: <= 480px
  static const double mobile = 480;

  // Tablet: 481px - 768px
  static const double tablet = 768;

  // Desktop: > 769px
  static const double desktop = 1024;

  // Large Desktop: > 1440px
  static const double largeDesktop = 1440;
}

/// Device type classification
enum DeviceType { mobile, tablet, desktop, largeDesktop }

/// Responsive helper class to detect screen size and adapt UI
class ResponsiveHelper {
  /// Get device type based on screen width
  static DeviceType getDeviceType(double width) {
    if (width <= ResponsiveBreakpoints.mobile) {
      return DeviceType.mobile;
    } else if (width <= ResponsiveBreakpoints.tablet) {
      return DeviceType.tablet;
    } else if (width <= ResponsiveBreakpoints.desktop) {
      return DeviceType.tablet; // Treat small desktops as tablets
    } else if (width <= ResponsiveBreakpoints.largeDesktop) {
      return DeviceType.desktop;
    } else {
      return DeviceType.largeDesktop;
    }
  }

  /// Check if device is mobile
  static bool isMobile(double width) => width <= ResponsiveBreakpoints.mobile;

  /// Check if device is tablet
  static bool isTablet(double width) =>
      width > ResponsiveBreakpoints.mobile &&
      width <= ResponsiveBreakpoints.tablet;

  /// Check if device is desktop
  static bool isDesktop(double width) =>
      width > ResponsiveBreakpoints.tablet &&
      width <= ResponsiveBreakpoints.desktop;

  /// Check if device is large desktop
  static bool isLargeDesktop(double width) =>
      width > ResponsiveBreakpoints.desktop;

  /// Check if device is desktop or larger
  static bool isWebLayout(double width) => width > ResponsiveBreakpoints.tablet;

  /// Get responsive padding based on screen width
  static EdgeInsets getResponsivePadding(double width) {
    if (isMobile(width)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(width)) {
      return const EdgeInsets.all(24);
    } else if (isDesktop(width)) {
      return const EdgeInsets.all(32);
    } else {
      return const EdgeInsets.all(40);
    }
  }

  /// Get responsive font size based on screen width
  static double getResponsiveFontSize(double width, double mobileSize) {
    if (isMobile(width)) {
      return mobileSize;
    } else if (isTablet(width)) {
      return mobileSize * 1.1;
    } else if (isDesktop(width)) {
      return mobileSize * 1.2;
    } else {
      return mobileSize * 1.3;
    }
  }

  /// Get responsive spacing based on screen width
  static double getResponsiveSpacing(double width) {
    if (isMobile(width)) {
      return 8;
    } else if (isTablet(width)) {
      return 12;
    } else if (isDesktop(width)) {
      return 16;
    } else {
      return 20;
    }
  }

  /// Get max content width for desktop layouts
  static double getMaxContentWidth(double width) {
    if (isLargeDesktop(width)) {
      return 1400;
    } else if (isDesktop(width)) {
      return 1200;
    } else if (isTablet(width)) {
      return 900;
    } else {
      return width;
    }
  }

  /// Get number of columns for grid layouts
  static int getGridColumns(double width) {
    if (isMobile(width)) {
      return 2;
    } else if (isTablet(width)) {
      return 3;
    } else if (isDesktop(width)) {
      return 4;
    } else {
      return 6;
    }
  }

  /// Get sidebar width for desktop layouts
  static double getSidebarWidth(double width) {
    if (isDesktop(width)) {
      return 280;
    } else if (isLargeDesktop(width)) {
      return 320;
    }
    return 0;
  }
}

/// Context extension for responsive helpers
extension ResponsiveContext on BuildContext {
  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get device type
  DeviceType get deviceType => ResponsiveHelper.getDeviceType(screenWidth);

  /// Check if is mobile
  bool get isMobile => ResponsiveHelper.isMobile(screenWidth);

  /// Check if is tablet
  bool get isTablet => ResponsiveHelper.isTablet(screenWidth);

  /// Check if is desktop
  bool get isDesktop => ResponsiveHelper.isDesktop(screenWidth);

  /// Check if is large desktop
  bool get isLargeDesktop => ResponsiveHelper.isLargeDesktop(screenWidth);

  /// Check if is web layout (tablet or larger)
  bool get isWebLayout => ResponsiveHelper.isWebLayout(screenWidth);

  /// Get responsive padding
  EdgeInsets get responsivePadding =>
      ResponsiveHelper.getResponsivePadding(screenWidth);

  /// Get responsive spacing
  double get responsiveSpacing =>
      ResponsiveHelper.getResponsiveSpacing(screenWidth);

  /// Get max content width
  double get maxContentWidth =>
      ResponsiveHelper.getMaxContentWidth(screenWidth);

  /// Get grid columns
  int get gridColumns => ResponsiveHelper.getGridColumns(screenWidth);

  /// Get sidebar width
  double get sidebarWidth => ResponsiveHelper.getSidebarWidth(screenWidth);
}
