import 'package:flutter/material.dart';

import '../core/responsive/responsive_config.dart';
import '../core/responsive/modern_effects.dart';
import '../core/theme/app_theme.dart';
import '../models/service_model.dart';
import './cached_image.dart';

/// Responsive Service Card with hover effects
class ResponsiveServiceCard extends StatefulWidget {
  final Service service;
  final VoidCallback? onTap;
  final VoidCallback? onBook;
  final bool showBookButton;

  const ResponsiveServiceCard({
    super.key,
    required this.service,
    this.onTap,
    this.onBook,
    this.showBookButton = true,
  });

  @override
  State<ResponsiveServiceCard> createState() => _ResponsiveServiceCardState();
}

class _ResponsiveServiceCardState extends State<ResponsiveServiceCard> {
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
          child: Container(
            decoration: ModernDecoration.modernCard(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
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
                              url: widget.service.image,
                              width: double.infinity,
                              height: isDesktop ? 180 : 140,
                              fit: BoxFit.cover,
                            ),
                            if (_isHovered && isWebLayout)
                              Container(
                                color: Colors.black.withValues(alpha: 0.15),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Category Badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 10 : 8,
                          vertical: isDesktop ? 6 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Text(
                          widget.service.category,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isDesktop ? 11 : 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    // Rating Badge
                    if (widget.service.rating > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 10 : 8,
                            vertical: isDesktop ? 6 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star_half_rounded,
                                size: isDesktop ? 14 : 12,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.service.rating}',
                                style: TextStyle(
                                  fontSize: isDesktop ? 11 : 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                // Content Section
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 14 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service Name
                        Text(
                          widget.service.name,
                          style: TextStyle(
                            fontSize: isDesktop ? 15 : 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Description
                        Text(
                          widget.service.description,
                          style: TextStyle(
                            fontSize: isDesktop ? 12 : 11,
                            color: AppTheme.textSecondary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        // Price and Button Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Starting from',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 10 : 9,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    'Rs. ${widget.service.price}',
                                    style: TextStyle(
                                      fontSize: isDesktop ? 15 : 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.showBookButton && widget.onBook != null)
                              Tooltip(
                                message: 'Book Service',
                                child: GestureDetector(
                                  onTap: widget.onBook,
                                  child: AnimatedScale(
                                    scale: _isHovered && isWebLayout
                                        ? 1.08
                                        : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        isDesktop ? 10 : 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          if (_isHovered && isWebLayout)
                                            BoxShadow(
                                              color: AppTheme.primaryColor
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 8,
                                            ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.arrow_forward_rounded,
                                        size: isDesktop ? 18 : 16,
                                        color: Colors.white,
                                      ),
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
