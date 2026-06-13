import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/product_card.dart';
import '../../widgets/category_item.dart';
import '../../widgets/service_card.dart';
import '../../widgets/login_card.dart';
import '../products/providers/product_providers.dart';
import '../providers/cart_provider.dart';
import '../services/providers/service_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final Function(int)? onNavigate;

  const HomeScreen({super.key, this.onNavigate});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white,
            elevation: 0,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/ace_technologies_logo.jpeg',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Ace Technologies',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: () => context.go('/notifications'),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Section
                _buildHeroSection(),

                // Stats Row
                _buildStatsRow(),

                // Search Bar
                _buildSearchBar(),

                // Login Card
                const LoginCard(),

                // Browse Categories (Products)
                _buildCategories(),

                // Peripherals Section
                _buildPeripherals(),

                // Security & Infrastructure Section
                _buildSecurityInfrastructure(),

                // Services Section
                _buildServicesSection(),

                // Featured Products
                _buildFeaturedProducts(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppConstants.appTagline,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppConstants.appSubtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go('/products'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Shop Products'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go('/services'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Explore Services'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatItem(AppConstants.clientsCount, AppConstants.clientsLabel),
          _buildStatItem(
            AppConstants.productsCount,
            AppConstants.productsLabel,
          ),
          _buildStatItem(AppConstants.yearsCount, AppConstants.yearsLabel),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.trim().isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Search',
                  onPressed: _submitSearch,
                ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        textInputAction: TextInputAction.search,
        onChanged: (value) => ref
            .read(productFilterProvider.notifier)
            .setSearchQuery(value.trim()),
        onSubmitted: (_) => _submitSearch(),
      ),
    );
  }

  void _submitSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    ref.read(productFilterProvider.notifier).setCategory('All');
    ref.read(productFilterProvider.notifier).setSearchQuery(query);
    context.go('/products?search=${Uri.encodeQueryComponent(query)}');
  }

  Widget _buildCategories() {
    final categories = [
      {'name': 'All', 'icon': Icons.apps},
      {'name': 'Processors', 'icon': Icons.memory},
      {'name': 'Laptops', 'icon': Icons.laptop},
      {'name': 'Networking', 'icon': Icons.router},
      {'name': 'Printers', 'icon': Icons.print},
      {'name': 'CCTV Cameras', 'icon': Icons.videocam},
      {'name': 'Fire Alarms', 'icon': Icons.notifications_active},
      {'name': 'Door Access', 'icon': Icons.door_sliding},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Browse Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = _selectedCategory == category['name'];
              return CategoryItem(
                title: category['name'] as String,
                icon: category['icon'] as IconData,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCategory = category['name'] as String;
                  });
                  // Navigate to Products screen with pre-selected category
                  final catName = category['name'] as String;
                  if (catName != 'All') {
                    context.go('/products?category=$catName');
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPeripherals() {
    final peripherals = [
      {'name': 'RAM', 'icon': Icons.memory},
      {'name': 'Hard Disk', 'icon': Icons.storage},
      {'name': 'Keyboard', 'icon': Icons.keyboard},
      {'name': 'Mouse', 'icon': Icons.mouse},
      {'name': 'Monitor', 'icon': Icons.monitor},
      {'name': 'Pendrive', 'icon': Icons.usb},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Peripherals',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: peripherals.length,
            itemBuilder: (context, index) {
              final peripheral = peripherals[index];
              return CategoryItem(
                title: peripheral['name'] as String,
                icon: peripheral['icon'] as IconData,
                isSelected: false,
                onTap: () {
                  // Navigate to Products screen with pre-selected peripheral category
                  final catName = peripheral['name'] as String;
                  context.go('/products?category=$catName');
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityInfrastructure() {
    final items = [
      {'name': 'TV', 'icon': Icons.tv},
      {'name': 'DVR', 'icon': Icons.video_library},
      {'name': 'NVR', 'icon': Icons.sd_card},
      {'name': 'Projector', 'icon': Icons.adjust},
      {'name': 'Cables (3+1)', 'icon': Icons.cable},
      {'name': 'Telephoning Solutions', 'icon': Icons.phone},
      {'name': 'Access Point', 'icon': Icons.router},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Security & Infrastructure',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return CategoryItem(
                title: item['name'] as String,
                icon: item['icon'] as IconData,
                isSelected: false,
                onTap: () {
                  // Navigate to Products screen with pre-selected category
                  final catName = item['name'] as String;
                  context.go('/products?category=$catName');
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    final services = ref.watch(servicesProvider).take(2).toList();
    final isLoading = ref.watch(servicesLoadingProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Our Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/services'),
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        if (isLoading && services.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (services.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'No services available',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              return ServiceCard(
                service: services[index],
                onBookNow: () =>
                    context.go('/service/${services[index].id}/book'),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFeaturedProducts() {
    final allProducts = ref.watch(productsProvider);
    final isLoading = ref.watch(productsLoadingProvider);
    final products =
        (_selectedCategory == 'All'
                ? allProducts
                : allProducts.where((p) => p.category == _selectedCategory))
            .take(4)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Featured Products',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/products'),
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        if (isLoading && products.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (products.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'No products available',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 2 : 2,
                  mainAxisExtent: isWide ? 310 : null,
                  childAspectRatio: isWide ? 1 : 0.5,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: products[index],
                    onAddToCart: () async {
                      try {
                        await ref
                            .read(cartProvider.notifier)
                            .addToCart(products[index]);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${products[index].name} added to cart!',
                            ),
                            action: SnackBarAction(
                              label: 'VIEW CART',
                              onPressed: () => context.go('/cart'),
                            ),
                          ),
                        );
                      } catch (error) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
