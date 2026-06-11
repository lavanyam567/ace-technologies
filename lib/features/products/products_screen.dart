import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product_model.dart';
import '../../widgets/product_card.dart';
import '../providers/cart_provider.dart';
import 'providers/product_providers.dart';
import 'providers/wishlist_provider.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  final String? initialSearch;

  const ProductsScreen({super.key, this.initialCategory, this.initialSearch});
  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _productCategories = [
    {'name': 'All', 'icon': Icons.apps},
    {'name': 'Processors', 'icon': Icons.memory},
    {'name': 'Laptops', 'icon': Icons.laptop},
    {'name': 'Networking', 'icon': Icons.router},
    {'name': 'Printers', 'icon': Icons.print},
    {'name': 'CCTV Cameras', 'icon': Icons.videocam},
    {'name': 'Fire Alarms', 'icon': Icons.notifications_active},
    {'name': 'Door Access', 'icon': Icons.door_sliding},
  ];

  final List<Map<String, dynamic>> _peripheralCategories = [
    {'name': 'RAM', 'icon': Icons.memory},
    {'name': 'Hard Disk', 'icon': Icons.storage},
    {'name': 'Keyboard', 'icon': Icons.keyboard},
    {'name': 'Mouse', 'icon': Icons.mouse},
    {'name': 'Monitor', 'icon': Icons.monitor},
    {'name': 'Pendrive', 'icon': Icons.usb},
  ];

  final List<Map<String, dynamic>> _securityCategories = [
    {'name': 'TV', 'icon': Icons.tv},
    {'name': 'DVR', 'icon': Icons.video_library},
    {'name': 'NVR', 'icon': Icons.sd_card},
    {'name': 'Projector', 'icon': Icons.adjust},
    {'name': 'Cables (3+1)', 'icon': Icons.cable},
    {'name': 'Telephoning Solutions', 'icon': Icons.phone},
    {'name': 'Access Point', 'icon': Icons.router},
  ];

  final List<String> _allBrands = [
    'Dell',
    'Lenovo',
    'HP',
    'Asus',
    'Acer',
    'Intel',
    'AMD',
    'Cisco',
    'TP-Link',
    'Epson',
    'Canon',
    'Hikvision',
    'CP Plus',
    'Honeywell',
    'Bosch',
    'ZKTeco',
    'HID',
    'Kingston',
    'Corsair',
    'Seagate',
    'WD',
    'Logitech',
    'HyperX',
    'Razer',
    'LG',
    'D-Link',
  ];

  final List<String> _sortOptions = [
    'Featured',
    'Price: Low to High',
    'Price: High to Low',
    'Top Rated',
    'Newest',
  ];

  final List<Map<String, dynamic>> _discountOptions = [
    {'label': 'All Discounts', 'value': 'All'},
    {'label': 'Below 15%', 'value': 'below15'},
    {'label': '15% and above', 'value': '15plus'},
    {'label': '30% and above', 'value': '30plus'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialCategory != null &&
          widget.initialCategory!.isNotEmpty) {
        ref
            .read(productFilterProvider.notifier)
            .setCategory(widget.initialCategory!);
      }
      if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
        _searchController.text = widget.initialSearch!;
        ref
            .read(productFilterProvider.notifier)
            .setSearchQuery(widget.initialSearch!.trim());
      }
      _searchController.text = ref.read(productFilterProvider).searchQuery;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    ref
        .read(productFilterProvider.notifier)
        .setSearchQuery(_searchController.text.trim());
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = ref.watch(filteredProductsProvider);
    final filterState = ref.watch(productFilterProvider);
    final totalCount = ref.watch(allProductsProvider).length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.backgroundColor,
      endDrawer: _buildFilterDrawer(filterState),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Products',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filters',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (value) => ref
                  .read(productFilterProvider.notifier)
                  .setSearchQuery(value.trim()),
            ),
          ),
          // Product Category Chips
          Container(
            color: Colors.white,
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _productCategories.length,
              itemBuilder: (context, index) {
                final cat = _productCategories[index];
                final name = cat['name'] as String;
                final isSelected = filterState.category == name;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      cat['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : AppTheme.primaryColor,
                    ),
                    label: Text(name),
                    selected: isSelected,
                    onSelected: (_) => ref
                        .read(productFilterProvider.notifier)
                        .setCategory(name),
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                    ),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          // Peripherals Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
            child: const Text(
              'Peripherals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Container(
            color: Colors.white,
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _peripheralCategories.length,
              itemBuilder: (context, index) {
                final cat = _peripheralCategories[index];
                final name = cat['name'] as String;
                final isSelected = filterState.category == name;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      cat['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : AppTheme.primaryColor,
                    ),
                    label: Text(name),
                    selected: isSelected,
                    onSelected: (_) => ref
                        .read(productFilterProvider.notifier)
                        .setCategory(name),
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                    ),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          // Security & Infrastructure Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
            child: const Text(
              'Security & Infrastructure',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Container(
            color: Colors.white,
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _securityCategories.length,
              itemBuilder: (context, index) {
                final cat = _securityCategories[index];
                final name = cat['name'] as String;
                final isSelected = filterState.category == name;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      cat['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : AppTheme.primaryColor,
                    ),
                    label: Text(name),
                    selected: isSelected,
                    onSelected: (_) => ref
                        .read(productFilterProvider.notifier)
                        .setCategory(name),
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                    ),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          // Results count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Displaying ${filtered.length} of $totalCount Results',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          // Products Grid
          Expanded(child: _buildProductsGrid(filtered)),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(List<Product> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No products found in this category',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon or explore other categories',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 1200
            ? 4
            : constraints.maxWidth >= 900
            ? 3
            : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: constraints.maxWidth >= 900 ? 310 : null,
            childAspectRatio: constraints.maxWidth >= 900 ? 1 : 0.52,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final isWishlisted = ref.watch(isInWishlistProvider(product.id));
            return ProductCard(
              product: product,
              isWishlisted: isWishlisted,
              onAddToCart: () {
                ref.read(cartProvider.notifier).addToCart(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.name} added to cart!')),
                );
              },
              onCompare: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.name} added to compare!')),
                );
              },
              onWishlistToggle: () async {
                try {
                  await ref
                      .read(wishlistProvider.notifier)
                      .toggleWishlist(product);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isWishlisted
                            ? '${product.name} removed from wishlist!'
                            : '${product.name} added to wishlist!',
                      ),
                    ),
                  );
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error.toString()),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFilterDrawer(ProductFilter filterState) {
    return Drawer(
      width: 300,
      child: SafeArea(
        child: StatefulBuilder(
          builder: (context, setDrawerState) {
            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(productFilterProvider.notifier).reset();
                        },
                        child: const Text(
                          'Reset',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Sort By
                      const Text(
                        'Sort By',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: filterState.sortBy,
                            items: _sortOptions
                                .map(
                                  (o) => DropdownMenuItem(
                                    value: o,
                                    child: Text(
                                      o,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              ref
                                  .read(productFilterProvider.notifier)
                                  .setSortBy(v!);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Price Range
                      const Text(
                        'Price Range',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${(filterState.minPrice ?? 0).toInt()} to ₹${(filterState.maxPrice ?? 200000).toInt()}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      RangeSlider(
                        values: RangeValues(
                          filterState.minPrice ?? 0,
                          filterState.maxPrice ?? 200000,
                        ),
                        min: 0,
                        max: 200000,
                        divisions: 40,
                        activeColor: AppTheme.primaryColor,
                        inactiveColor: AppTheme.primaryColor.withValues(
                          alpha: 0.2,
                        ),
                        labels: RangeLabels(
                          '₹${(filterState.minPrice ?? 0).toInt()}',
                          '₹${(filterState.maxPrice ?? 200000).toInt()}',
                        ),
                        onChanged: (v) {
                          ref
                              .read(productFilterProvider.notifier)
                              .setPriceRange(v.start, v.end);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Categories
                      _buildExpandableSection(
                        'Categories',
                        [
                          ..._productCategories.map((c) => c['name'] as String),
                          ..._peripheralCategories.map(
                            (c) => c['name'] as String,
                          ),
                        ].map((cat) {
                          final isSelected = filterState.category == cat;
                          return InkWell(
                            onTap: () {
                              ref
                                  .read(productFilterProvider.notifier)
                                  .setCategory(cat);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    size: 18,
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Brands
                      _buildExpandableSection(
                        'Brands',
                        _allBrands.map((brand) {
                          final isChecked = filterState.brands.contains(brand);
                          return InkWell(
                            onTap: () {
                              ref
                                  .read(productFilterProvider.notifier)
                                  .toggleBrand(brand);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: isChecked,
                                      onChanged: (v) {
                                        ref
                                            .read(
                                              productFilterProvider.notifier,
                                            )
                                            .toggleBrand(brand);
                                      },
                                      activeColor: AppTheme.primaryColor,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    brand,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Discounts
                      const Text(
                        'Discounts',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._discountOptions.map((opt) {
                        final isSelected =
                            filterState.discountFilter == opt['value'];
                        return InkWell(
                          onTap: () {
                            ref
                                .read(productFilterProvider.notifier)
                                .setDiscountFilter(opt['value'] as String);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  size: 18,
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  opt['label'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                // Apply Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildExpandableSection(String title, List<Widget> children) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(left: 8),
        initiallyExpanded: true,
        children: children,
      ),
    );
  }
}
