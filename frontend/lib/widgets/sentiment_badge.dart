import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recommendation_model.dart';
import '../features/products/providers/sentiment_provider.dart';
import '../core/theme/app_theme.dart';

// ────────────────────────────────────────────────────────────────────────────
// SentimentBadge
// A compact coloured pill showing Positive / Neutral / Negative label.
// ────────────────────────────────────────────────────────────────────────────

class SentimentBadge extends StatelessWidget {
  final SentimentType sentiment;
  final double? score;
  final bool showScore;
  final bool compact;

  const SentimentBadge({
    super.key,
    required this.sentiment,
    this.score,
    this.showScore = false,
    this.compact = false,
  });

  Color get _bgColor {
    switch (sentiment) {
      case SentimentType.positive:
        return const Color(0xFFE6F4EA);
      case SentimentType.negative:
        return const Color(0xFFFCE8E6);
      case SentimentType.neutral:
        return const Color(0xFFFFF8E1);
    }
  }

  Color get _textColor {
    switch (sentiment) {
      case SentimentType.positive:
        return const Color(0xFF1E7E34);
      case SentimentType.negative:
        return const Color(0xFFD32F2F);
      case SentimentType.neutral:
        return const Color(0xFFF57F17);
    }
  }

  IconData get _icon {
    switch (sentiment) {
      case SentimentType.positive:
        return Icons.sentiment_satisfied_alt_rounded;
      case SentimentType.negative:
        return Icons.sentiment_dissatisfied_rounded;
      case SentimentType.neutral:
        return Icons.sentiment_neutral_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _textColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: compact ? 12 : 14, color: _textColor),
          const SizedBox(width: 4),
          Text(
            sentiment.label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
          ),
          if (showScore && score != null) ...[
            const SizedBox(width: 4),
            Text(
              '${(score! * 100).toInt()}%',
              style: TextStyle(
                fontSize: compact ? 9 : 10,
                color: _textColor.withValues(alpha: 0.75),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// SentimentOverviewCard
// Shows the full breakdown (positive / neutral / negative bars) for a product.
// ────────────────────────────────────────────────────────────────────────────

class SentimentOverviewCard extends ConsumerWidget {
  final String productId;

  const SentimentOverviewCard({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(sentimentSummaryProvider(productId));

    return summaryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (summary) {
        if (summary.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology_rounded,
                      color: AppTheme.primaryColor, size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'AI Sentiment Analysis',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${summary.totalCount} review${summary.totalCount != 1 ? 's' : ''} analysed',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _SentimentBar(
                label: 'Positive',
                count: summary.positiveCount,
                total: summary.totalCount,
                color: const Color(0xFF43A047),
              ),
              const SizedBox(height: 6),
              _SentimentBar(
                label: 'Neutral',
                count: summary.neutralCount,
                total: summary.totalCount,
                color: const Color(0xFFFFA726),
              ),
              const SizedBox(height: 6),
              _SentimentBar(
                label: 'Negative',
                count: summary.negativeCount,
                total: summary.totalCount,
                color: const Color(0xFFE53935),
              ),
              if (summary.topKeywords.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Common keywords',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: summary.topKeywords
                      .take(8)
                      .map(
                        (kw) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            kw,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SentimentBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _SentimentBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 7,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: pct.clamp(0.0, 1.0),
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            count.toString(),
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
