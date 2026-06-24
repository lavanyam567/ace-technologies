# Quick Start: Converting Screens to Responsive Design

This guide helps you quickly convert existing screens to work responsively across mobile, tablet, and desktop.

## 5-Minute Overview

The Ace Technologies app now supports:
- **Mobile** (≤480px): Bottom navigation, single-column layouts
- **Tablet** (481-768px): Bottom navigation, 2-column layouts
- **Desktop** (769-1024px): Sidebar navigation, 3-4 column layouts
- **Large Desktop** (>1024px): Sidebar navigation, 4-6 column layouts

**No API or backend changes needed!** All existing services work as before.

## Step 1: Import Responsive Utilities

```dart
import 'package:flutter/material.dart';
import '../../core/responsive/index.dart';  // Import all responsive utilities
```

## Step 2: Use Context Extensions

In any `build()` method, you can now use:

```dart
@override
Widget build(BuildContext context) {
  // Check device type
  if (context.isWebLayout) {
    // Desktop/Tablet layout
  } else {
    // Mobile layout
  }

  // Get responsive values
  final padding = context.responsivePadding;  // Auto-adjusted padding
  final spacing = context.responsiveSpacing;  // Auto-adjusted spacing
  final gridCols = context.gridColumns;       // 2-6 columns based on screen
  final maxWidth = context.maxContentWidth;   // 1400px on large desktop

  // Check specific breakpoints
  if (context.isMobile) { }
  if (context.isTablet) { }
  if (context.isDesktop) { }
  if (context.isLargeDesktop) { }
}
```

## Step 3: Adapt Your Screen

### Option A: Simple Conditional Layout

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: context.isWebLayout
          ? _buildDesktopLayout(context)
          : _buildMobileLayout(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return ResponsiveContainer(
      maxWidth: 1400,
      child: Column(
        children: [
          _buildHeader(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildContent(),
      ],
    );
  }
}
```

### Option B: Responsive Widgets (Recommended)

```dart
class MyProductsScreen extends StatelessWidget {
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveContainer(  // Auto-handles web centering
        child: ResponsiveGridView(  // Auto-adjusts columns
          mobileColumns: 2,
          tabletColumns: 3,
          desktopColumns: 4,
          children: products
              .map((p) => ResponsiveProductCard(product: p))
              .toList(),
        ),
      ),
    );
  }
}
```

## Common Patterns

### Pattern 1: Product/Service Listing

```dart
ResponsiveGridView(
  mobileColumns: 2,
  tabletColumns: 3,
  desktopColumns: 4,
  spacing: context.responsiveSpacing,
  children: items
      .map((item) => ResponsiveProductCard(
        product: item,
        onTap: () => handleTap(item),
      ))
      .toList(),
)
```

### Pattern 2: Two-Column Layout

```dart
ResponsiveSideBySide(
  left: _buildLeftColumn(),
  right: _buildRightColumn(),
  forceVertical: context.isMobile,  // Stack on mobile
)
```

### Pattern 3: Form with Responsive Fields

```dart
ResponsiveFormLayout(
  columns: context.isWebLayout ? 2 : 1,
  fields: [
    TextField(
      decoration: InputDecoration(hintText: 'First Name'),
    ),
    TextField(
      decoration: InputDecoration(hintText: 'Last Name'),
    ),
    // More fields...
  ],
)
```

### Pattern 4: List with Sections

```dart
ResponsiveListView(
  spacing: context.responsiveSpacing,
  children: [
    ResponsiveSection(
      title: 'Featured Products',
      content: _buildProductGrid(),
    ),
    ResponsiveSection(
      title: 'Our Services',
      content: _buildServiceGrid(),
    ),
  ],
)
```

## Replace Component Widgets

### Old → New

| Old Widget | New Widget | Benefits |
|------------|-----------|----------|
| `ProductCard` | `ResponsiveProductCard` | Hover effects, size adaptation |
| `ServiceCard` | `ResponsiveServiceCard` | Modern styling, responsive sizing |
| `CategoryItem` | `ResponsiveCategoryItem` | Adaptive size, selection effects |
| `GridView.count` | `ResponsiveGridView` | Auto column count |
| `FlatButton` | `ResponsiveButton` | Adaptive sizing |
| Generic card | `ResponsiveCard` | Hover lift effect |
| Generic text | `ResponsiveText` | Auto font scaling |

### Example: Before and After

**Before:**
```dart
GridView.count(
  crossAxisCount: 2,
  children: products.map((p) => ProductCard(product: p)).toList(),
)
```

**After:**
```dart
ResponsiveGridView(
  children: products
      .map((p) => ResponsiveProductCard(product: p))
      .toList(),
)
```

## Add Modern Effects

### Hover Effects (Desktop Only)

```dart
MouseRegion(
  onEnter: (_) => setState(() => _isHovered = true),
  onExit: (_) => setState(() => _isHovered = false),
  child: AnimatedContainer(
    duration: Duration(milliseconds: 200),
    transform: _isHovered && context.isWebLayout
        ? Matrix4.identity()..translate(0, -8)  // Lift up
        : Matrix4.identity(),
    child: YourCard(),
  ),
)
```

### Loading States

```dart
// Instead of CircularProgressIndicator
if (isLoading) {
  return SkeletonGrid(
    itemCount: 6,
    crossAxisCount: context.gridColumns,
  );
} else {
  return _buildContent();
}
```

### Responsive Hero Section

```dart
ResponsiveHeroSection(
  title: 'Welcome to Ace Technologies',
  subtitle: 'Your IT & Security Solutions Partner',
  backgroundImageUrl: 'https://...',
  minHeight: context.isWebLayout ? 400 : 250,
  actions: [
    ElevatedButton(
      onPressed: () => context.go('/products'),
      child: Text('Shop Now'),
    ),
  ],
)
```

## Navigation Adaptation

**You don't need to change anything!** The navigation automatically adapts:
- Mobile: Bottom navigation bar
- Desktop: Collapsible sidebar

The `MainNavigationShell` handles this automatically in `app_router.dart`.

## Testing Your Changes

### 1. Test on Multiple Screen Sizes

```bash
flutter run -d chrome

# Then in Chrome DevTools:
# Ctrl+Shift+M (or Cmd+Shift+M on Mac) to open Device Toolbar
# Test breakpoints: 480px, 768px, 1024px, 1440px
```

### 2. Checklist

- [ ] **Mobile (480px)**: Layouts stack vertically, touch-friendly
- [ ] **Tablet (768px)**: 2-3 column grid, bottom nav visible
- [ ] **Desktop (1024px)**: Sidebar visible, 3-4 columns
- [ ] **Large Desktop (1440px)**: Full sidebar, wide content
- [ ] **Hover**: Desktop cards lift on hover (if implemented)
- [ ] **Images**: Load correctly and scale appropriately
- [ ] **Forms**: All fields are accessible and aligned
- [ ] **Buttons**: Touch targets ≥44x44px on mobile

### 3. Debug Responsive Values

```dart
// Add to any build method
debugPrint('Screen width: ${context.screenWidth}');
debugPrint('Device type: ${context.deviceType}');
debugPrint('Is web layout: ${context.isWebLayout}');
debugPrint('Grid columns: ${context.gridColumns}');
```

## Performance Tips

1. **Use ListView.builder** for large lists
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => _buildItem(items[index]),
)
```

2. **Add Images with Caching**
```dart
CachedNetworkImage(
  imageUrl: imageUrl,
  placeholder: (context, url) => SkeletonLoader(height: 200),
  fit: BoxFit.cover,
)
```

3. **Implement Pagination**
```dart
// Load more items as user scrolls
if (_scrollController.position.pixels >=
    _scrollController.position.maxScrollExtent - 500) {
  _loadMore();
}
```

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Sidebar doesn't show on desktop | Ensure `context.isWebLayout` is true, check screen width |
| Grid has too many columns | Use `ResponsiveGridView` instead of `GridView.count` |
| Cards don't have hover effect | Add `ResponsiveProductCard` instead of `ProductCard` |
| Layout breaks at tablet size | Adjust column counts in `ResponsiveGridView` |
| Forms don't wrap properly | Use `ResponsiveFormLayout` |
| Images distorted on desktop | Use `fit: BoxFit.cover` with CachedNetworkImage |

## Full Example: Product List Screen

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/index.dart';
import '../../models/product_model.dart';
import '../../widgets/responsive_product_card.dart';

class ProductsScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: products.when(
        loading: () => SkeletonGrid(
          itemCount: 6,
          crossAxisCount: context.gridColumns,
        ),
        error: (err, stack) => Center(
          child: Text('Error: $err'),
        ),
        data: (productList) => ResponsiveContainer(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(context.responsiveSpacing),
                  child: Text(
                    'Products',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
              ),
              // Grid
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.responsiveSpacing,
                ),
                sliver: ResponsiveSliverGrid(
                  children: productList
                      .map(
                        (product) => ResponsiveProductCard(
                          product: product,
                          onTap: () =>
                              context.go('/product/${product.id}'),
                          onAddToCart: () =>
                              ref
                                  .read(cartProvider)
                                  .addItem(product),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Next Steps

1. **Choose a screen** to start with (e.g., HomeScreen)
2. **Follow the patterns** from ADAPTATION_GUIDE.dart
3. **Test** on multiple screen sizes
4. **Iterate** based on how it looks
5. **Submit PR** with changes

## Resources

- **Main Guide**: `WEB_RESPONSIVENESS_GUIDE.md`
- **Adaptation Patterns**: `lib/core/responsive/ADAPTATION_GUIDE.dart`
- **Performance Tips**: `lib/core/performance/performance_guide.dart`
- **Example Widgets**: `lib/widgets/responsive_*.dart`

## Questions?

Refer to:
1. The comprehensive `WEB_RESPONSIVENESS_GUIDE.md`
2. Code comments in responsive utility files
3. Examples in widget files

Happy coding! 🚀
