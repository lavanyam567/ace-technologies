import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/supabase_service.dart';
import '../../../models/recommendation_model.dart';

// ──────────────────────────────────────────────────────────────
// Sentiment summary for a single product (used on product detail)
// ──────────────────────────────────────────────────────────────

final sentimentSummaryProvider =
    FutureProvider.family<SentimentSummary, String>((ref, productId) async {
  return SupabaseService.instance.fetchProductSentimentSummary(productId);
});

// ──────────────────────────────────────────────────────────────
// Admin: sentiment summary for ALL products
// ──────────────────────────────────────────────────────────────

final adminSentimentProvider =
    FutureProvider<List<AdminSentimentRow>>((ref) async {
  return SupabaseService.instance.fetchAllSentimentsSummary();
});
