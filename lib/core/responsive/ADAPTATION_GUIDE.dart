// ignore_for_file: dangling_library_doc_comments, file_names

/// RESPONSIVE SCREEN ADAPTATION GUIDE
///
/// This file provides patterns and best practices for adapting existing screens
/// to be fully responsive for web, tablet, and mobile layouts.
///
/// KEY CONCEPTS:
/// 1. Use ResponsiveHelper.isWebLayout to detect desktop/tablet vs mobile
/// 2. Use ResponsiveSliverGrid for product/service listings
/// 3. Implement hover effects only on web layouts (check context.isWebLayout)
/// 4. Use ResponsiveContainer to handle max-width constraints on desktop
/// 5. Replace ProductCard with ResponsiveProductCard for web enhancements
/// 6. Use ResponsiveSideBySide for two-column layouts on desktop
/// 7. Implement lazy loading with CachedNetworkImage
/// 8. Use SkeletonLoader for content placeholders

// PATTERN 1: Adapt HomeScreen with responsive layouts
/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/responsive/responsive_config.dart';
import '../../core/responsive/responsive_widgets.dart';
import '../../core/responsive/responsive_layouts.dart';
import '../../models/product_model.dart';
import '../../models/service_model.dart';
import '../../widgets/responsive_product_card.dart';
import '../../widgets/responsive_service_card.dart';
import '../../widgets/responsive_widgets.dart';

class ResponsiveHomeScreen extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;

  const ResponsiveHomeScreen({super.key, this.onNavigate});

  @override
  ConsumerState<ResponsiveHomeScreen> createState() => _ResponsiveHomeScreenState();
}

class _ResponsiveHomeScreenState extends ConsumerState<ResponsiveHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final isWebLayout = context.isWebLayout;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: context.isWebLayout
          ? _buildDesktopLayout()
          : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return CustomScrollView(
      slivers: [
        // Desktop AppBar at top
        SliverAppBar(
          floating: true,
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.computer, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Ace Technologies',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        // Content wrapped in center with max width
        SliverToBoxAdapter(
          child: ResponsiveContainer(
            maxWidth: 1400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroSection(),
                _buildStatsRow(),
                _buildSearchBar(),
                _buildCategories(),
                _buildFeaturedProducts(),
                _buildFeaturedServices(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(floating: true, /* ... mobile config ... */),
        SliverToBoxAdapter(
          child: Column(
            children: [
              _buildHeroSection(),
              _buildStatsRow(),
              _buildSearchBar(),
              _buildCategories(),
              _buildFeaturedProducts(),
              _buildFeaturedServices(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return ResponsiveHeroSection(
      title: 'Welcome to Ace Technologies',
      subtitle: 'Your trusted IT & Security Solutions Partner',
      backgroundImageUrl: 'https://...',
      minHeight: context.isWebLayout ? 400 : 250,
      actions: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.shopping_cart),
          label: const Text('Start Shopping'),
        ),
      ],
    );
  }

  Widget _buildFeaturedProducts() {
    return ResponsiveSection(
      title: 'Featured Products',
      content: ResponsiveSliverGrid(
        children: products.map((p) => ResponsiveProductCard(product: p)).toList(),
      ),
    );
  }

  Widget _buildFeaturedServices() {
    return ResponsiveSection(
      title: 'Our Services',
      content: ResponsiveSliverGrid(
        mobileColumns: 1,
        tabletColumns: 2,
        desktopColumns: 3,
        children: services.map((s) => ResponsiveServiceCard(service: s)).toList(),
      ),
    );
  }
}
*/

// PATTERN 2: Update ProductsScreen for responsive grid
/*
Widget _buildProductsGrid() {
  return ResponsiveContainer(
    child: ResponsiveGridView(
      mobileColumns: 2,
      tabletColumns: 3,
      desktopColumns: 4,
      spacing: context.responsiveSpacing,
      children: products
          .map((product) => ResponsiveProductCard(
            product: product,
            onTap: () => context.go('/product/${product.id}'),
            onAddToCart: () => cartProvider.addItem(product),
          ))
          .toList(),
    ),
  );
}
*/

// PATTERN 3: Responsive detail screen with side-by-side layout
/*
Widget _buildProductDetailLayout() {
  return ResponsiveContainer(
    child: ResponsiveSideBySide(
      forceVertical: context.isMobile,
      left: _buildProductImage(),
      right: _buildProductInfo(),
    ),
  );
}
*/

// PATTERN 4: Add lazy loading and skeleton loaders
/*
if (isLoading) {
  return SkeletonGrid(
    itemCount: 6,
    crossAxisCount: context.gridColumns,
  );
} else if (products.isEmpty) {
  return Center(
    child: Text('No products found'),
  );
} else {
  return _buildProductsGrid();
}
*/

// PATTERN 5: Desktop navigation with hover effects
/*
InkWell(
  onHover: (isHovered) {
    if (context.isWebLayout) {
      setState(() => _hoveredIndex = isHovered ? index : -1);
    }
  },
  onTap: () => context.go(route),
  child: AnimatedContainer(
    duration: Duration(milliseconds: 200),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: _hoveredIndex == index 
          ? AppTheme.primaryColor.withValues(alpha: 0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(item.label),
  ),
)
*/

// PATTERN 6: Responsive form layout
/*
ResponsiveFormLayout(
  columns: context.isWebLayout ? 2 : 1,
  fields: [
    _buildTextField('First Name'),
    _buildTextField('Last Name'),
    _buildTextField('Email'),
    _buildTextField('Phone'),
  ],
)
*/

// PATTERN 7: Adaptive bottom sheet for mobile, dialog for web
/*
void _showPicker(BuildContext context) {
  if (context.isWebLayout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Option'),
        content: _buildPickerContent(),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildPickerContent(),
    );
  }
}
*/

// PATTERN 8: Responsive list with proper spacing
/*
ResponsiveListView(
  spacing: context.responsiveSpacing,
  children: items.map((item) => ListTile(
    title: Text(item.name),
    trailing: context.isWebLayout ? Icon(Icons.arrow_forward) : null,
  )).toList(),
)
*/

// BEST PRACTICES:
// 1. Always wrap grid/list views with ResponsiveContainer on web
// 2. Use context.gridColumns instead of hardcoded column counts
// 3. Apply hover effects only in if (context.isWebLayout) blocks
// 4. Use ResponsiveText for automatic font scaling
// 5. Implement lazy loading for large lists
// 6. Use SkeletonLoader instead of spinners
// 7. Test on multiple screen sizes (480px, 768px, 1024px, 1440px+)
// 8. Maintain consistent spacing using context.responsiveSpacing
// 9. Use ResponsivePadding for screen-aware padding
// 10. Always provide touch-friendly tap targets (44x44px minimum)
