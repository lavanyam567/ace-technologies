// Models for NLP Recommendations and Sentiment Analysis features.

// ────────────────────────────────────────────────────────────
// Sentiment
// ────────────────────────────────────────────────────────────

enum SentimentType {
  positive,
  neutral,
  negative;

  static SentimentType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'positive':
        return SentimentType.positive;
      case 'negative':
        return SentimentType.negative;
      default:
        return SentimentType.neutral;
    }
  }

  String get label {
    switch (this) {
      case SentimentType.positive:
        return 'Positive';
      case SentimentType.neutral:
        return 'Neutral';
      case SentimentType.negative:
        return 'Negative';
    }
  }

  String get emoji {
    switch (this) {
      case SentimentType.positive:
        return '😊';
      case SentimentType.neutral:
        return '😐';
      case SentimentType.negative:
        return '😞';
    }
  }
}

class SentimentResult {
  final String id;
  final String reviewId;
  final String productId;
  final SentimentType sentiment;
  final double score;
  final List<String> keywords;
  final DateTime processedAt;

  const SentimentResult({
    required this.id,
    required this.reviewId,
    required this.productId,
    required this.sentiment,
    required this.score,
    required this.keywords,
    required this.processedAt,
  });

  factory SentimentResult.fromSupabase(Map<String, dynamic> json) {
    return SentimentResult(
      id: json['id'] as String,
      reviewId: json['review_id'] as String,
      productId: json['product_id'] as String,
      sentiment: SentimentType.fromString(json['sentiment'] as String? ?? 'neutral'),
      score: (json['score'] as num?)?.toDouble() ?? 0.5,
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      processedAt:
          DateTime.tryParse(json['processed_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class SentimentSummary {
  final int positiveCount;
  final int neutralCount;
  final int negativeCount;
  final double averageScore;
  final List<String> topKeywords;

  const SentimentSummary({
    required this.positiveCount,
    required this.neutralCount,
    required this.negativeCount,
    required this.averageScore,
    required this.topKeywords,
  });

  int get totalCount => positiveCount + neutralCount + negativeCount;
  bool get isEmpty => totalCount == 0;

  double get positivePercent =>
      totalCount == 0 ? 0 : positiveCount / totalCount;
  double get neutralPercent =>
      totalCount == 0 ? 0 : neutralCount / totalCount;
  double get negativePercent =>
      totalCount == 0 ? 0 : negativeCount / totalCount;

  /// The dominant sentiment for this product
  SentimentType get dominant {
    if (positiveCount >= neutralCount && positiveCount >= negativeCount) {
      return SentimentType.positive;
    } else if (negativeCount >= neutralCount) {
      return SentimentType.negative;
    }
    return SentimentType.neutral;
  }

  factory SentimentSummary.empty() {
    return const SentimentSummary(
      positiveCount: 0,
      neutralCount: 0,
      negativeCount: 0,
      averageScore: 0.5,
      topKeywords: [],
    );
  }

  factory SentimentSummary.fromSupabase(Map<String, dynamic> json) {
    return SentimentSummary(
      positiveCount: (json['positive_count'] as num?)?.toInt() ?? 0,
      neutralCount: (json['neutral_count'] as num?)?.toInt() ?? 0,
      negativeCount: (json['negative_count'] as num?)?.toInt() ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.5,
      topKeywords: (json['top_keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

// ────────────────────────────────────────────────────────────
// Admin Sentiment Row (per-product summary for admin dashboard)
// ────────────────────────────────────────────────────────────

class AdminSentimentRow {
  final String productId;
  final String productName;
  final int positiveCount;
  final int neutralCount;
  final int negativeCount;
  final double averageScore;

  const AdminSentimentRow({
    required this.productId,
    required this.productName,
    required this.positiveCount,
    required this.neutralCount,
    required this.negativeCount,
    required this.averageScore,
  });

  int get total => positiveCount + neutralCount + negativeCount;

  factory AdminSentimentRow.fromSupabase(Map<String, dynamic> json) {
    return AdminSentimentRow(
      productId: json['product_id'] as String,
      productName: json['product_name'] as String? ?? 'Unknown',
      positiveCount: (json['positive_count'] as num?)?.toInt() ?? 0,
      neutralCount: (json['neutral_count'] as num?)?.toInt() ?? 0,
      negativeCount: (json['negative_count'] as num?)?.toInt() ?? 0,
      averageScore: (json['average_score'] as num?)?.toDouble() ?? 0.5,
    );
  }
}
