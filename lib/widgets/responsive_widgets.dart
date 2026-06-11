import 'package:flutter/material.dart';

import '../core/responsive/responsive_config.dart';
import '../core/theme/app_theme.dart';
import './cached_image.dart';

/// Responsive Category Item with adaptive layout
class ResponsiveCategoryItem extends StatefulWidget {
  final String categoryName;
  final String imageUrl;
  final VoidCallback onTap;
  final bool isSelected;

  const ResponsiveCategoryItem({
    super.key,
    required this.categoryName,
    required this.imageUrl,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  State<ResponsiveCategoryItem> createState() => _ResponsiveCategoryItemState();
}

class _ResponsiveCategoryItemState extends State<ResponsiveCategoryItem> {
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
          duration: const Duration(milliseconds: 200),
          transform: _isHovered && isWebLayout
              ? (Matrix4.identity()..scaleByDouble(1.05, 1.05, 1.0, 1.0))
              : Matrix4.identity(),
          child: Column(
            children: [
              Container(
                width: isDesktop ? 120 : 100,
                height: isDesktop ? 120 : 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isSelected
                        ? AppTheme.primaryColor
                        : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: _isHovered ? 0.15 : 0.08,
                      ),
                      blurRadius: _isHovered ? 12 : 8,
                      offset: Offset(0, _isHovered ? 4 : 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      AceImage(
                        url: widget.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      if (_isHovered && isWebLayout)
                        Container(color: Colors.black.withValues(alpha: 0.1)),
                      // Selection Indicator
                      if (widget.isSelected)
                        Center(
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: isDesktop ? 120 : 100,
                child: Text(
                  widget.categoryName,
                  style: TextStyle(
                    fontSize: isDesktop ? 13 : 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive search bar with adaptive width
class ResponsiveSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onSearch;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged;
  final List<String>? suggestions;
  final bool showSuggestions;

  const ResponsiveSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search products, services...',
    this.onSearch,
    this.onClear,
    this.onChanged,
    this.suggestions,
    this.showSuggestions = false,
  });

  @override
  State<ResponsiveSearchBar> createState() => _ResponsiveSearchBarState();
}

class _ResponsiveSearchBarState extends State<ResponsiveSearchBar> {
  bool _showDropdown = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop || context.isLargeDesktop;

    return Column(
      children: [
        Container(
          height: isDesktop ? 48 : 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 12),
                child: Icon(
                  Icons.search_rounded,
                  color: AppTheme.textSecondary,
                  size: isDesktop ? 20 : 18,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  onChanged: (value) {
                    widget.onChanged?.call(value);
                    setState(() {
                      _showDropdown =
                          widget.showSuggestions && value.isNotEmpty;
                    });
                  },
                  onSubmitted: (_) => widget.onSearch?.call(),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: isDesktop ? 14 : 13,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (widget.controller.text.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(right: isDesktop ? 8 : 4),
                  child: IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onClear?.call();
                      setState(() => _showDropdown = false);
                    },
                    iconSize: isDesktop ? 20 : 18,
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 8 : 4),
                child: IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: widget.onSearch,
                  iconSize: isDesktop ? 20 : 18,
                ),
              ),
            ],
          ),
        ),
        // Suggestions dropdown
        if (_showDropdown &&
            widget.suggestions != null &&
            widget.suggestions!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.suggestions!.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.history_rounded, size: 16),
                  title: Text(widget.suggestions![index]),
                  onTap: () {
                    widget.controller.text = widget.suggestions![index];
                    setState(() => _showDropdown = false);
                    widget.onSearch?.call();
                  },
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 16 : 12,
                    vertical: 8,
                  ),
                  dense: true,
                );
              },
            ),
          ),
      ],
    );
  }
}
