import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/recommendation_model.dart';
import '../../products/providers/sentiment_provider.dart';

/// Admin Feedback Analysis Screen
/// Shows NLP-powered sentiment breakdown across all reviewed products.
class FeedbackAnalysisScreen extends ConsumerStatefulWidget {
  const FeedbackAnalysisScreen({super.key});

  @override
  ConsumerState<FeedbackAnalysisScreen> createState() =>
      _FeedbackAnalysisScreenState();
}

class _FeedbackAnalysisScreenState
    extends ConsumerState<FeedbackAnalysisScreen> {
  String _sortBy = 'negative'; // 'negative' | 'positive' | 'total'

  @override
  Widget build(BuildContext context) {
    final adminAsync = ref.watch(adminSentimentProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Feedback Analysis'),
        backgroundColor: Colors.white,
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
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load: $e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
        data: (rows) => _buildContent(rows),
      ),
    );
  }

  Widget _buildContent(List<AdminSentimentRow> rows) {
    if (rows.isEmpty) {
      return Center(
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
                  color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Reviews will appear here once customers\nsubmit feedback on products.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    // Aggregate totals for the summary cards
    final totalPositive = rows.fold<int>(0, (s, r) => s + r.positiveCount);
    final totalNeutral = rows.fold<int>(0, (s, r) => s + r.neutralCount);
    final totalNegative = rows.fold<int>(0, (s, r) => s + r.negativeCount);
    final grandTotal = totalPositive + totalNeutral + totalNegative;

    // Sort rows
    final sorted = [...rows];
    switch (_sortBy) {
      case 'positive':
        sorted.sort((a, b) => b.positiveCount.compareTo(a.positiveCount));
        break;
      case 'negative':
        sorted.sort((a, b) => b.negativeCount.compareTo(a.negativeCount));
        break;
      default:
        sorted.sort((a, b) => b.total.compareTo(a.total));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Summary stats ─────────────────────────────────────────
        Row(
          children: [
            _StatCard(
              label: 'Positive',
              count: totalPositive,
              total: grandTotal,
              color: const Color(0xFF43A047),
              icon: Icons.thumb_up_rounded,
            ),
            const SizedBox(width: 10),
            _StatCard(
              label: 'Neutral',
              count: totalNeutral,
              total: grandTotal,
              color: const Color(0xFFFFA726),
              icon: Icons.thumbs_up_down_rounded,
            ),
            const SizedBox(width: 10),
            _StatCard(
              label: 'Negative',
              count: totalNegative,
              total: grandTotal,
              color: const Color(0xFFE53935),
              icon: Icons.thumb_down_rounded,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ── Visual sentiment donut ────────────────────────────────
        if (grandTotal > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Overall Sentiment',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                _SentimentDonut(
                  positive: totalPositive,
                  neutral: totalNeutral,
                  negative: totalNegative,
                  total: grandTotal,
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // ── Sort + Table ──────────────────────────────────────────
        Row(
          children: [
            const Text('Product Breakdown',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const Spacer(),
            _SortButton(
              label: 'Most Negative',
              isActive: _sortBy == 'negative',
              onTap: () => setState(() => _sortBy = 'negative'),
            ),
            const SizedBox(width: 6),
            _SortButton(
              label: 'Most Positive',
              isActive: _sortBy == 'positive',
              onTap: () => setState(() => _sortBy = 'positive'),
            ),
          ],
        ),

        const SizedBox(height: 10),

        ...sorted.map((row) => _ProductSentimentRow(row: row)),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// Sub-widgets
// ────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (count * 100 ~/ total);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.8),
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SentimentDonut extends StatelessWidget {
  final int positive;
  final int neutral;
  final int negative;
  final int total;

  const _SentimentDonut({
    required this.positive,
    required this.neutral,
    required this.negative,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Bar(
          label: 'Positive',
          count: positive,
          total: total,
          color: const Color(0xFF43A047),
        ),
        const SizedBox(height: 8),
        _Bar(
          label: 'Neutral',
          count: neutral,
          total: total,
          color: const Color(0xFFFFA726),
        ),
        const SizedBox(height: 8),
        _Bar(
          label: 'Negative',
          count: negative,
          total: total,
          color: const Color(0xFFE53935),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _Bar(
      {required this.label,
      required this.count,
      required this.total,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 36,
          child: Text(
            '${(pct * 100).toInt()}%',
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color),
          ),
        ),
      ],
    );
  }
}

class _SortButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SortButton(
      {required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
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

class _ProductSentimentRow extends StatelessWidget {
  final AdminSentimentRow row;

  const _ProductSentimentRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                ),
              ),
              Text(
                '${row.total} reviews',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniStat(
                  count: row.positiveCount,
                  color: const Color(0xFF43A047),
                  icon: Icons.thumb_up_rounded),
              const SizedBox(width: 12),
              _MiniStat(
                  count: row.neutralCount,
                  color: const Color(0xFFFFA726),
                  icon: Icons.thumbs_up_down_rounded),
              const SizedBox(width: 12),
              _MiniStat(
                  count: row.negativeCount,
                  color: const Color(0xFFE53935),
                  icon: Icons.thumb_down_rounded),
              const Spacer(),
              // Dominant sentiment badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: row.positiveCount >= row.negativeCount
                      ? const Color(0xFFE6F4EA)
                      : const Color(0xFFFCE8E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  row.positiveCount >= row.negativeCount
                      ? '😊 Positive'
                      : '😞 Needs Attention',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: row.positiveCount >= row.negativeCount
                        ? const Color(0xFF1E7E34)
                        : const Color(0xFFD32F2F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Mini stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                if (row.positiveCount > 0)
                  Flexible(
                    flex: row.positiveCount,
                    child: Container(
                        height: 5, color: const Color(0xFF43A047)),
                  ),
                if (row.neutralCount > 0)
                  Flexible(
                    flex: row.neutralCount,
                    child: Container(
                        height: 5, color: const Color(0xFFFFA726)),
                  ),
                if (row.negativeCount > 0)
                  Flexible(
                    flex: row.negativeCount,
                    child: Container(
                        height: 5, color: const Color(0xFFE53935)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final int count;
  final Color color;
  final IconData icon;

  const _MiniStat(
      {required this.count, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          count.toString(),
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
