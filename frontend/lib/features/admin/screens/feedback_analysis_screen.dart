import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/recommendation_model.dart';
import '../../products/providers/sentiment_provider.dart';

// Shared sentiment palette
const _kPositive = Color(0xFF43A047);
const _kNeutral = Color(0xFFFFA726);
const _kNegative = Color(0xFFE53935);

/// Admin Feedback Analysis Dashboard
/// NLP-powered sentiment breakdown across all reviewed products.
class FeedbackAnalysisScreen extends ConsumerStatefulWidget {
  const FeedbackAnalysisScreen({super.key});

  @override
  ConsumerState<FeedbackAnalysisScreen> createState() =>
      _FeedbackAnalysisScreenState();
}

class _FeedbackAnalysisScreenState
    extends ConsumerState<FeedbackAnalysisScreen> {
  String _sortBy = 'negative'; // 'negative' | 'positive' | 'total'
  final TextEditingController _filterController = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminAsync = ref.watch(adminSentimentProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Feedback Analysis'),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminSentimentProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: adminAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (e, _) => _ErrorState(
          error: e.toString(),
          onRetry: () => ref.invalidate(adminSentimentProvider),
        ),
        data: (rows) => RefreshIndicator(
          color: AppTheme.primaryColor,
          onRefresh: () async => ref.invalidate(adminSentimentProvider),
          child: _buildContent(rows),
        ),
      ),
    );
  }

  Widget _buildContent(List<AdminSentimentRow> rows) {
    if (rows.isEmpty) {
      return const _EmptyState();
    }

    // Aggregate totals
    final totalPositive = rows.fold<int>(0, (s, r) => s + r.positiveCount);
    final totalNeutral = rows.fold<int>(0, (s, r) => s + r.neutralCount);
    final totalNegative = rows.fold<int>(0, (s, r) => s + r.negativeCount);
    final grandTotal = totalPositive + totalNeutral + totalNegative;
    final flaggedCount =
        rows.where((r) => r.negativeCount > r.positiveCount).length;

    final pctPositive =
        grandTotal == 0 ? 0 : (totalPositive * 100 / grandTotal).round();
    final pctNegative =
        grandTotal == 0 ? 0 : (totalNegative * 100 / grandTotal).round();

    // Filter + sort
    final visible = rows.where((r) {
      if (_filter.isEmpty) return true;
      return r.productName.toLowerCase().contains(_filter.toLowerCase());
    }).toList();

    switch (_sortBy) {
      case 'positive':
        visible.sort((a, b) => b.positiveCount.compareTo(a.positiveCount));
        break;
      case 'negative':
        visible.sort((a, b) => b.negativeCount.compareTo(a.negativeCount));
        break;
      default:
        visible.sort((a, b) => b.total.compareTo(a.total));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── KPI row ───────────────────────────────────────────────
        Row(
          children: [
            _KpiCard(
              label: 'Reviews Analyzed',
              value: '$grandTotal',
              color: AppTheme.primaryColor,
              icon: Icons.reviews_rounded,
            ),
            const SizedBox(width: 10),
            _KpiCard(
              label: '% Positive',
              value: '$pctPositive%',
              color: _kPositive,
              icon: Icons.thumb_up_rounded,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _KpiCard(
              label: '% Negative',
              value: '$pctNegative%',
              color: _kNegative,
              icon: Icons.thumb_down_rounded,
            ),
            const SizedBox(width: 10),
            _KpiCard(
              label: 'Products Flagged',
              value: '$flaggedCount',
              color: const Color(0xFFEF6C00),
              icon: Icons.flag_rounded,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Donut chart ───────────────────────────────────────────
        if (grandTotal > 0)
          _DonutCard(
            positive: totalPositive,
            neutral: totalNeutral,
            negative: totalNegative,
            total: grandTotal,
          ),

        const SizedBox(height: 16),

        // ── Sort + filter ─────────────────────────────────────────
        const Text(
          'Product Breakdown',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _filterController,
          onChanged: (v) => setState(() => _filter = v),
          decoration: InputDecoration(
            hintText: 'Filter by product name…',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _filter.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _filterController.clear();
                      setState(() => _filter = '');
                    },
                  ),
            isDense: true,
            filled: true,
            fillColor: AppTheme.cardColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _SortChip(
              label: 'Most Negative',
              isActive: _sortBy == 'negative',
              onTap: () => setState(() => _sortBy = 'negative'),
            ),
            const SizedBox(width: 6),
            _SortChip(
              label: 'Most Positive',
              isActive: _sortBy == 'positive',
              onTap: () => setState(() => _sortBy = 'positive'),
            ),
            const SizedBox(width: 6),
            _SortChip(
              label: 'Total',
              isActive: _sortBy == 'total',
              onTap: () => setState(() => _sortBy = 'total'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                'No products match "$_filter"',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...visible.map(
            (row) => _ProductBarRow(
              row: row,
              onTap: () => _openDrillDown(row),
            ),
          ),
      ],
    );
  }

  void _openDrillDown(AdminSentimentRow row) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DrillDownSheet(row: row),
    );
  }
}

// ────────────────────────────────────────────────────────────
// KPI card
// ────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Donut chart card (fl_chart)
// ────────────────────────────────────────────────────────────

class _DonutCard extends StatelessWidget {
  final int positive;
  final int neutral;
  final int negative;
  final int total;

  const _DonutCard({
    required this.positive,
    required this.neutral,
    required this.negative,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Sentiment',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 44,
                        startDegreeOffset: -90,
                        sections: [
                          if (positive > 0)
                            PieChartSectionData(
                              value: positive.toDouble(),
                              color: _kPositive,
                              radius: 24,
                              showTitle: false,
                            ),
                          if (neutral > 0)
                            PieChartSectionData(
                              value: neutral.toDouble(),
                              color: _kNeutral,
                              radius: 24,
                              showTitle: false,
                            ),
                          if (negative > 0)
                            PieChartSectionData(
                              value: negative.toDouble(),
                              color: _kNegative,
                              radius: 24,
                              showTitle: false,
                            ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Text(
                          'reviews',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LegendChip(
                      color: _kPositive,
                      label: 'Positive',
                      count: positive,
                      total: total,
                    ),
                    const SizedBox(height: 8),
                    _LegendChip(
                      color: _kNeutral,
                      label: 'Neutral',
                      count: neutral,
                      total: total,
                    ),
                    const SizedBox(height: 8),
                    _LegendChip(
                      color: _kNegative,
                      label: 'Negative',
                      count: negative,
                      total: total,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;

  const _LegendChip({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (count * 100 / total).round();
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        Text(
          '$count · $pct%',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// Sort chip
// ────────────────────────────────────────────────────────────

class _SortChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Per-product stacked bar row
// ────────────────────────────────────────────────────────────

class _ProductBarRow extends StatelessWidget {
  final AdminSentimentRow row;
  final VoidCallback onTap;

  const _ProductBarRow({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final flagged = row.negativeCount > row.positiveCount;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
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
                if (flagged) ...[
                  const Icon(Icons.flag_rounded, size: 14, color: _kNegative),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    row.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${row.total} total',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    size: 18, color: AppTheme.textSecondary),
              ],
            ),
            const SizedBox(height: 10),
            _StackedBar(
              positive: row.positiveCount,
              neutral: row.neutralCount,
              negative: row.negativeCount,
            ),
          ],
        ),
      ),
    );
  }
}

class _StackedBar extends StatelessWidget {
  final int positive;
  final int neutral;
  final int negative;

  const _StackedBar({
    required this.positive,
    required this.neutral,
    required this.negative,
  });

  @override
  Widget build(BuildContext context) {
    final total = positive + neutral + negative;
    if (total == 0) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Row(
        children: [
          if (positive > 0)
            Expanded(
              flex: positive,
              child: Container(height: 10, color: _kPositive),
            ),
          if (neutral > 0)
            Expanded(
              flex: neutral,
              child: Container(height: 10, color: _kNeutral),
            ),
          if (negative > 0)
            Expanded(
              flex: negative,
              child: Container(height: 10, color: _kNegative),
            ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Drill-down bottom sheet
// ────────────────────────────────────────────────────────────

class _DrillDownSheet extends ConsumerWidget {
  final AdminSentimentRow row;

  const _DrillDownSheet({required this.row});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(sentimentSummaryProvider(row.productId));
    final flagged = row.negativeCount > row.positiveCount;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                row.productName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${row.total} review${row.total == 1 ? '' : 's'} analysed',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Counts
              Row(
                children: [
                  _CountPill(
                      label: 'Positive',
                      count: row.positiveCount,
                      color: _kPositive),
                  const SizedBox(width: 8),
                  _CountPill(
                      label: 'Neutral',
                      count: row.neutralCount,
                      color: _kNeutral),
                  const SizedBox(width: 8),
                  _CountPill(
                      label: 'Negative',
                      count: row.negativeCount,
                      color: _kNegative),
                ],
              ),

              const SizedBox(height: 20),

              // Average score bar
              const Text(
                'Average Sentiment Score',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _ScoreBar(score: row.averageScore),

              const SizedBox(height: 20),

              // Top keywords (from per-product sentiment summary)
              const Text(
                'Top Keywords',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              summaryAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (_, _) => const Text(
                  'Keywords unavailable',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                data: (summary) {
                  if (summary.topKeywords.isEmpty) {
                    return const Text(
                      'No keywords extracted yet',
                      style:
                          TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    );
                  }
                  // Colour by the product's dominant sentiment.
                  final positiveLean = !flagged;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: summary.topKeywords.take(12).map((kw) {
                      final color = positiveLean ? _kPositive : _kNegative;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: color.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          kw,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 24),

              // View reviews
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/product/${row.productId}/reviews');
                  },
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  label: const Text(
                    'View reviews',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CountPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountPill({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final double score; // 0.0 – 1.0

  const _ScoreBar({required this.score});

  @override
  Widget build(BuildContext context) {
    final clamped = score.clamp(0.0, 1.0);
    final color = clamped >= 0.6
        ? _kPositive
        : clamped >= 0.4
            ? _kNeutral
            : _kNegative;
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: clamped,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${(clamped * 100).round()}%',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// Empty / error states
// ────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      // ListView so RefreshIndicator still works when empty.
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sentiment_satisfied_alt,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text(
                'No feedback analysed yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Reviews will appear here once customers\nsubmit feedback on products.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Failed to load feedback',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
