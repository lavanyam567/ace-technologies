/// Currency formatting utilities
class CurrencyUtils {
  static const String _currencySymbol = '₹';

  /// Format price with proper currency symbol
  /// Handles null prices safely - never shows ₹NaN
  static String formatPrice(double? price) {
    if (price == null || price.isNaN || price.isInfinite) {
      return 'Contact for price';
    }
    return '$_currencySymbol${price.toStringAsFixed(0)}';
  }

  /// Format price with decimal places
  static String formatPriceWithDecimal(double? price, {int decimals = 2}) {
    if (price == null || price.isNaN || price.isInfinite) {
      return 'Contact for price';
    }
    return '$_currencySymbol${price.toStringAsFixed(decimals)}';
  }

  /// Get price label - returns "Contact for price" if null
  static String getPriceLabel(double? price) {
    if (price == null || price <= 0) {
      return 'Contact for price';
    }
    return 'Starting from ${formatPrice(price)}';
  }

  /// Calculate discount percentage
  static int calculateDiscount(double originalPrice, double currentPrice) {
    if (originalPrice <= 0) return 0;
    return ((originalPrice - currentPrice) / originalPrice * 100).round();
  }

  /// Format large numbers with K/M suffix
  static String formatCompactNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// Date formatting utilities
class DateUtils {
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

/// Validation utilities
class ValidationUtils {
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhone(String phone) {
    return RegExp(r'^[6-9]\d{9}$').hasMatch(phone);
  }

  static bool isValidName(String name) {
    return name.trim().length >= 2;
  }
}

/// String extensions
extension StringExtensions on String {
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String get titleCase {
    return split(' ').map((word) => word.capitalize).join(' ');
  }
}
