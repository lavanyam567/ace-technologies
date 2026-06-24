class ProductReview {
  final String id;
  final String userId;
  final String productId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const ProductReview({
    required this.id,
    required this.userId,
    required this.productId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  String get title {
    final parts = _commentParts;
    if (parts.length > 1 && parts.first.trim().isNotEmpty) {
      return parts.first.trim();
    }
    return 'Product review';
  }

  String get content {
    final parts = _commentParts;
    if (parts.length > 1) {
      return parts.skip(1).join('\n\n').trim();
    }
    return comment.trim();
  }

  List<String> get _commentParts => comment.split(RegExp(r'\n\s*\n'));

  factory ProductReview.fromSupabase(
    Map<String, dynamic> json, {
    String? userName,
  }) {
    return ProductReview(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      userName: userName?.trim().isNotEmpty == true
          ? userName!.trim()
          : 'Customer',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
