import 'package:flutter/material.dart';

import '../core/responsive/responsive_config.dart';
import '../core/theme/app_theme.dart';
import '../models/product_model.dart';
import './cached_image.dart';

/// Responsive and enhanced product card with hover effects and modern styling
class ResponsiveProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onAddToCart;
  final VoidCallback? onTap;
  final VoidCallback? onCompare;
  final VoidCallback? onWishlistToggle;
  final bool isWishlisted;

  const ResponsiveProductCard({
    super.key,
    required this.product,
    this.onAddToCart,
    this.onTap,
    this.onCompare,
    this.onWishlistToggle,
    this.isWishlisted = false,
  });

  @override
  State<ResponsiveProductCard> createState() => _ResponsiveProductCardState();
}

class _ResponsiveProductCardState extends State<ResponsiveProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop || context.isLargeDesktop;
    final isWebLayout = context.isWebLayout;

    return MouseRegion(
      onEnter: (_) {
        if (isWebLayout) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (isWebLayout) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: _isHovered && isWebLayout
              ? (Matrix4.identity()..translateByDouble(0, -8, 0, 1))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            boxShadow: [
              if (_isHovered && isWebLayout)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section with badges
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Container(
                        height: isDesktop ? 180 : 140,
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        child: Stack(
                          children: [
                            AceImage(
                              url: widget.product.safeImage,
                              width: double.infinity,
                              height: isDesktop ? 180 : 140,
                              fit: BoxFit.cover,
                            ),
                            // Hover overlay on desktop
                            if (_isHovered && isWebLayout)
                              Container(
                                color: Colors.black.withValues(alpha: 0.1),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Discount Badge
                    if (widget.product.hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          width: isDesktop ? 56 : 48,
                          height: isDesktop ? 56 : 48,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${widget.product.discount}%\nOFF',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isDesktop ? 11 : 9,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Wishlist Icon with hover effect
                    if (widget.onWishlistToggle != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: widget.onWishlistToggle,
                          child: AnimatedScale(
                            scale: _isHovered && isWebLayout ? 1.1 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.isWishlisted
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                                color: widget.isWishlisted
                                    ? AppTheme.errorColor
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Out of Stock Overlay
                    if (widget.product.isOutOfStock)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Out of Stock',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Content Section
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 14 : 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FOR BUSINESS USE tag
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 8 : 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'FOR BUSINESS USE',
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontSize: isDesktop ? 9 : 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Product Name
                        Text(
                          widget.product.name,
                          style: TextStyle(
                            fontSize: isDesktop ? 15 : 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Brand + Rating
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.product.brand,
                                style: TextStyle(
                                  fontSize: isDesktop ? 11 : 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (widget.product.rating > 0) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.star_half_rounded,
                                size: isDesktop ? 14 : 12,
                                color: Colors.amber,
                              ),
                              Text(
                                '${widget.product.rating}',
                                style: TextStyle(
                                  fontSize: isDesktop ? 11 : 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Spacer(),
                        // Price Section
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Rs. ${widget.product.price}',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 15 : 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  if (widget.product.hasDiscount)
                                    Text(
                                      'Rs. ${widget.product.originalPrice}',
                                      style: TextStyle(
                                        fontSize: isDesktop ? 11 : 9,
                                        decoration: TextDecoration.lineThrough,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (widget.onAddToCart != null)
                              Tooltip(
                                message: 'Add to Cart',
                                child: GestureDetector(
                                  onTap: widget.onAddToCart,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        if (_isHovered && isWebLayout)
                                          BoxShadow(
                                            color: AppTheme.primaryColor
                                                .withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.add_shopping_cart,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
