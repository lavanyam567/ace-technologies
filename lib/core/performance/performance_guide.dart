// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';

import '../responsive/responsive_widgets.dart';

/// Performance Optimization Guide for Web
///
/// This guide provides best practices for optimizing the Ace Technologies
/// Flutter web application for excellent performance across all devices.

class PerformanceOptimizationGuide {
  /// IMAGE OPTIMIZATION TIPS:
  ///
  /// 1. Use CachedNetworkImage with memory caching
  /// 2. Lazy load images below the fold
  /// 3. Use appropriate image dimensions for screen size
  /// 4. Enable caching in HTTP headers from backend
  /// 5. Use WebP format when possible (with PNG fallback)
  /// 6. Implement progressive image loading
  /// 7. Use placeholder images/skeletons while loading
  /// 8. Compress images before upload to backend

  static const String CACHED_IMAGE_EXAMPLE = '''
    CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder: (context, url) => SkeletonLoader(
        width: double.infinity,
        height: 200,
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: Icon(Icons.broken_image),
      ),
      fit: BoxFit.cover,
      memCacheWidth: isDesktop ? 800 : 400,
      memCacheHeight: isDesktop ? 600 : 300,
    )
  ''';

  /// WIDGET RENDERING OPTIMIZATION:
  ///
  /// 1. Use const constructors everywhere possible
  /// 2. Implement RepaintBoundary for complex widgets
  /// 3. Use ListView.builder instead of ListView
  /// 4. Implement shouldRebuild in custom painters
  /// 5. Use ChangeNotifier.notifyListeners() selectively
  /// 6. Implement proper key usage for lists
  /// 7. Use const dividers, spacers, and simple widgets
  /// 8. Avoid rebuilding entire screens on state changes

  static const String OPTIMIZED_LIST_EXAMPLE = '''
    ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(
          key: ValueKey(items[index].id), // Important for list updates
          title: Text(items[index].name),
        );
      },
    )
  ''';

  /// NETWORK OPTIMIZATION:
  ///
  /// 1. Implement request/response caching
  /// 2. Use pagination for large lists
  /// 3. Batch API requests when possible
  /// 4. Implement request deduplication
  /// 5. Use gzip compression for responses
  /// 6. Minimize payload size (only send needed fields)
  /// 7. Implement timeouts for network requests
  /// 8. Cache responses locally for offline support

  static const String PAGINATION_EXAMPLE = '''
    int _currentPage = 1;
    bool _isLoading = false;
    bool _hasMoreItems = true;
    
    Future<void> _loadMoreItems() async {
      if (_isLoading || !_hasMoreItems) return;
      
      setState(() => _isLoading = true);
      
      try {
        final newItems = await api.getProducts(page: _currentPage);
        setState(() {
          items.addAll(newItems);
          _hasMoreItems = newItems.length == PAGE_SIZE;
          _currentPage++;
        });
      } finally {
        setState(() => _isLoading = false);
      }
    }
    
    @override
    Widget build(BuildContext context) {
      return ListView.builder(
        itemCount: items.length + (_hasMoreItems ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            _loadMoreItems();
            return SkeletonLoader(height: 80);
          }
          return ListTile(title: Text(items[index].name));
        },
      );
    }
  ''';

  /// STATE MANAGEMENT OPTIMIZATION:
  ///
  /// 1. Use selective providers (watch only what you need)
  /// 2. Implement provider family for parameterized data
  /// 3. Use FutureProvider for async operations
  /// 4. Cache expensive computations
  /// 5. Implement StreamProvider for real-time data
  /// 6. Clean up subscriptions properly
  /// 7. Use select() to watch specific properties
  /// 8. Implement proper provider inheritance

  static const String OPTIMIZED_PROVIDER_EXAMPLE = '''
    // Only watch the isLoading state, not entire provider
    final isLoading = ref.watch(
      productsProvider.select((state) => state.isLoading)
    );
    
    // Use family for parameterized queries
    final productProvider = FutureProvider.family<Product, String>((ref, id) async {
      return await api.getProduct(id);
    });
    
    // Cache expensive computations
    final filteredProducts = ref.watch(
      productsProvider.select((state) => 
        state.items.where((p) => p.category == selectedCategory).toList()
      )
    );
  ''';

  /// DOM/BUILD OPTIMIZATION:
  ///
  /// 1. Minimize build() method complexity
  /// 2. Extract widgets to separate methods
  /// 3. Use CustomPainter for complex drawings
  /// 4. Implement shouldRebuild wisely
  /// 5. Use LayoutBuilder for responsive calculations
  /// 6. Avoid circular rebuilds
  /// 7. Use GlobalKey only when necessary
  /// 8. Profile with Dart DevTools regularly

  static const String EXTRACTED_WIDGET_EXAMPLE = '''
    class ProductList extends StatelessWidget {
      final List<Product> products;
      
      @override
      Widget build(BuildContext context) {
        return ResponsiveGridView(
          children: products.map((p) => _ProductCard(product: p)).toList(),
        );
      }
      
      // Extract complex widgets to separate classes
      Widget _buildHeader() => _Header();
      Widget _buildFilter() => _FilterBar();
      Widget _buildProducts() => _ProductGrid();
    }
    
    class _ProductCard extends StatelessWidget {
      final Product product;
      
      const _ProductCard({required this.product});
      
      @override
      Widget build(BuildContext context) {
        // Only this widget rebuilds on product change
        return ResponsiveProductCard(product: product);
      }
    }
  ''';

  /// RESPONSIVE OPTIMIZATION:
  ///
  /// 1. Use MediaQuery efficiently
  /// 2. Avoid excessive layout recalculations
  /// 3. Use appropriate widget sizes for screen
  /// 4. Implement adaptive layouts early
  /// 5. Use SingleChildScrollView only when needed
  /// 6. Implement proper scroll physics
  /// 7. Use LayoutBuilder for complex layouts
  /// 8. Cache responsive calculations

  static const String OPTIMIZED_RESPONSIVE_EXAMPLE = '''
    class ResponsiveLayout extends StatelessWidget {
      @override
      Widget build(BuildContext context) {
        // Calculate once at build time
        final isWebLayout = context.isWebLayout;
        final maxWidth = context.maxContentWidth;
        final columns = context.gridColumns;
        
        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: isWebLayout
              ? _buildDesktopLayout(columns)
              : _buildMobileLayout(),
        );
      }
      
      Widget _buildDesktopLayout(int columns) {
        // Desktop-specific layout
        return GridView.count(crossAxisCount: columns);
      }
      
      Widget _buildMobileLayout() {
        // Mobile-specific layout
        return ListView();
      }
    }
  ''';

  /// WEB-SPECIFIC OPTIMIZATIONS:
  ///
  /// 1. Enable CanvasKit renderer for better performance
  /// 2. Implement lazy loading for off-screen content
  /// 3. Use web fonts efficiently (preload critical fonts)
  /// 4. Implement Service Worker for offline support
  /// 5. Optimize JavaScript interop
  /// 6. Use CSS containment for better performance
  /// 7. Implement resource hints (preconnect, dns-prefetch)
  /// 8. Monitor Core Web Vitals (LCP, FID, CLS)

  static const String WEB_PERFORMANCE_TIPS = '''
    // In main.dart or web app initialization:
    
    // 1. Use CanvasKit for better performance on modern browsers
    // flutter build web --web-renderer=canvaskit
    
    // 2. Enable aggressive caching
    // Configure HTTP headers with max-age for static assets
    
    // 3. Implement Service Worker for offline support
    // flutter create --platforms=web enables service_worker.js
    
    // 4. Use preload for critical resources
    // <link rel="preload" href="fonts/GoogleFonts.woff2" as="font">
    
    // 5. Implement lazy loading for images
    // <img loading="lazy" src="...">
    
    // 6. Use web fonts sparingly
    // Only load needed weights and variants
    
    // 7. Implement resource hints
    // <link rel="preconnect" href="https://api.example.com">
    // <link rel="dns-prefetch" href="https://cdn.example.com">
    
    // 8. Monitor performance metrics
    // Use Google Analytics or similar
  ''';

  /// MEMORY OPTIMIZATION:
  ///
  /// 1. Dispose of controllers and listeners
  /// 2. Use weak references where appropriate
  /// 3. Clear image cache periodically
  /// 4. Implement memory-efficient data structures
  /// 5. Avoid memory leaks with streams
  /// 6. Use object pooling for frequently created objects
  /// 7. Monitor memory usage in DevTools
  /// 8. Implement garbage collection hints

  static const String MEMORY_EFFICIENT_EXAMPLE = '''
    class MyWidget extends StatefulWidget {
      @override
      State<MyWidget> createState() => _MyWidgetState();
    }
    
    class _MyWidgetState extends State<MyWidget> {
      late StreamSubscription _subscription;
      late TextEditingController _controller;
      
      @override
      void initState() {
        super.initState();
        _controller = TextEditingController();
        _subscription = stream.listen((_) {
          if (mounted) {
            setState(() {});
          }
        });
      }
      
      @override
      void dispose() {
        _subscription.cancel();
        _controller.dispose();
        super.dispose();
      }
      
      @override
      Widget build(BuildContext context) => Container();
    }
  ''';

  /// PROFILING AND MONITORING:
  ///
  /// 1. Use Dart DevTools for profiling
  /// 2. Monitor frame rate (60 FPS target)
  /// 3. Check memory usage regularly
  /// 4. Use Performance timeline in browser DevTools
  /// 5. Implement custom performance markers
  /// 6. Monitor API response times
  /// 7. Track error rates
  /// 8. Implement analytics for user experience

  static const String PROFILING_EXAMPLE = r'''
    // Add custom performance tracking
    Future<T> trackPerformance<T>(
      String label,
      Future<T> Function() operation,
    ) async {
      final stopwatch = Stopwatch()..start();
      try {
        return await operation();
      } finally {
        stopwatch.stop();
        print('$label: ${stopwatch.elapsedMilliseconds}ms');
        // Send to analytics
        analytics.log('performance', {
          'operation': label,
          'duration': stopwatch.elapsedMilliseconds,
        });
      }
    }
  ''';
}

/// Example: Optimized Product List Screen
class OptimizedProductListScreen extends StatefulWidget {
  const OptimizedProductListScreen({super.key});

  @override
  State<OptimizedProductListScreen> createState() =>
      _OptimizedProductListScreenState();
}

class _OptimizedProductListScreenState
    extends State<OptimizedProductListScreen> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    // Load more items
    setState(() => _isLoadingMore = false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContainer(
      child: ResponsiveGridView(
        controller: _scrollController,
        children: [
          // Product items here
        ],
      ),
    );
  }
}
