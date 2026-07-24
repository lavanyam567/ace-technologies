import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../providers/admin_order_provider.dart';
import '../../services/providers/booking_providers.dart';
import '../../../core/services/supabase_service.dart';
import '../../../features/products/providers/product_providers.dart';
import '../../../features/services/providers/service_providers.dart';
import '../utils/image_uploader.dart';

final adminCategoriesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final categories = await SupabaseService.instance.fetchCategories();
    if (categories.isEmpty) throw Exception("Empty categories");
    return categories;
  } catch (_) {
    return [
      'Processors',
      'Laptops',
      'Networking',
      'Printers',
      'CCTV Cameras',
      'Fire Alarms',
      'Door Access',
      'RAM',
      'Hard Disk',
      'Keyboard',
      'Mouse',
      'Monitor',
      'Pendrive',
      'TV',
      'DVR',
      'NVR',
      'Projector',
      'Cables (3+1)',
      'Telephoning Solutions',
      'Access Point'
    ];
  }
});

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  int _activePushCatalogTab = 0; // 0 for Product, 1 for Service

  // Product Form Controllers
  final _productFormKey = GlobalKey<FormState>();
  final _prodIdController = TextEditingController();
  final _prodNameController = TextEditingController();
  final _prodBrandController = TextEditingController();
  final _prodPriceController = TextEditingController();
  final _prodOrigPriceController = TextEditingController();
  final _prodStockController = TextEditingController();
  final _prodDescriptionController = TextEditingController();
  final _prodImageController = TextEditingController();
  String? _selectedCategory;
  bool _isPushingProduct = false;
  bool _isUploadingImage = false;

  // Service Form Controllers
  final _serviceFormKey = GlobalKey<FormState>();
  final _svcIdController = TextEditingController();
  final _svcTitleController = TextEditingController();
  final _svcDescriptionController = TextEditingController();
  final _svcPriceController = TextEditingController();
  final _svcImageController = TextEditingController();
  final _svcFeaturesController = TextEditingController(); // Comma separated
  bool _isPushingService = false;

  // Payment Search and Filters
  final _paymentSearchController = TextEditingController();
  String _paymentStatusFilter = 'All'; // All, Paid, Pending, Failed

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _paymentSearchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _prodIdController.dispose();
    _prodNameController.dispose();
    _prodBrandController.dispose();
    _prodPriceController.dispose();
    _prodOrigPriceController.dispose();
    _prodStockController.dispose();
    _prodDescriptionController.dispose();
    _prodImageController.dispose();
    
    _svcIdController.dispose();
    _svcTitleController.dispose();
    _svcDescriptionController.dispose();
    _svcPriceController.dispose();
    _svcImageController.dispose();
    _svcFeaturesController.dispose();

    _paymentSearchController.dispose();
    super.dispose();
  }

  void _generateMockProductData() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    setState(() {
      if (_selectedCategory == 'Laptops') {
        _prodIdController.text = 'lap_hp15_$timestamp';
        _prodNameController.text = 'HP 15 Laptop';
        _prodBrandController.text = 'HP';
        _prodPriceController.text = '38999';
        _prodOrigPriceController.text = '49999';
        _prodStockController.text = '15';
        _prodDescriptionController.text = 'HP 15, AMD Ryzen 5 7520U (8GB LPDDR5, 512GB SSD) FHD, Anti-Glare, Micro-Edge, 15.6\'\'/39.6cm, Win11, M365 Basic(1yr), Office 24, Silver, 1.59kg, fc0805AU, FHD Camera w/Privacy Shutter, Backlit Laptop. Visit the HP Store.';
        _prodImageController.text = 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=600&q=80';
      } else {
        _prodIdController.text = 'prod_$timestamp';
        _prodNameController.text = 'Super Premium SSD Gaming Storage v$timestamp';
        _prodBrandController.text = 'Crucial';
        _prodPriceController.text = '8999';
        _prodOrigPriceController.text = '12999';
        _prodStockController.text = '25';
        _prodDescriptionController.text = 'Ultra-high-speed PCIe Gen4 NVMe M.2 SSD for pro gamers, offering up to 7400MB/s read speeds, smart thermal control, and a sleek heatsink design. Perfect for extending storage on next-gen consoles and PC gaming rigs.';
        _prodImageController.text = 'https://images.unsplash.com/photo-1562976540-1502c2145186?w=600&q=80';
        _selectedCategory = 'Hard Disk';
      }
    });
  }

  void _generateMockServiceData() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    setState(() {
      _svcIdController.text = 'svc_$timestamp';
      _svcTitleController.text = 'Premium Smart Home CCTV Setup';
      _svcDescriptionController.text = 'Complete smart home security network configuration including outdoor wireless dome cameras, hybrid Cloud and local storage configuration, and live synchronization onto all personal mobile devices.';
      _svcPriceController.text = '5999';
      _svcImageController.text = 'https://images.unsplash.com/photo-1557597774-9d273605dfa9?w=800&q=80';
      _svcFeaturesController.text = '4K Dome Cameras, Smart Motion Zones, Remote Live Stream, 1TB Local Storage, Free 1-Year Maintenance';
    });
  }

  Future<void> _uploadImage() async {
    setState(() => _isUploadingImage = true);
    try {
      final url = await pickAndUploadImage();
      if (url != null) {
        setState(() {
          _prodImageController.text = url;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image uploaded and URL updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _submitProduct() async {
    if (!_productFormKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product category')),
      );
      return;
    }

    setState(() => _isPushingProduct = true);

    try {
      final id = _prodIdController.text.trim().toLowerCase().replaceAll(' ', '_');
      final name = _prodNameController.text.trim();
      final brand = _prodBrandController.text.trim();
      final cleanPriceStr = _prodPriceController.text.trim().replaceAll(RegExp(r'[^\d\.]'), '');
      final price = double.parse(cleanPriceStr);
      final cleanOrigPriceStr = _prodOrigPriceController.text.trim().replaceAll(RegExp(r'[^\d\.]'), '');
      final originalPrice = cleanOrigPriceStr.isNotEmpty ? double.parse(cleanOrigPriceStr) : null;
      final cleanStockStr = _prodStockController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
      final stock = int.parse(cleanStockStr);
      final description = _prodDescriptionController.text.trim();
      final imageUrl = _prodImageController.text.trim().isNotEmpty
          ? _prodImageController.text.trim()
          : 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=600&q=80';

      int discount = 0;
      if (originalPrice != null && originalPrice > price) {
        discount = (((originalPrice - price) / originalPrice) * 100).round();
      }

      await SupabaseService.instance.addProduct(
        id: id,
        name: name,
        brand: brand,
        price: price,
        originalPrice: originalPrice,
        stock: stock,
        category: _selectedCategory!,
        description: description,
        imageUrl: imageUrl,
        discount: discount,
      );

      // Invalidate products provider to sync shop screen
      ref.invalidate(productsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product successfully pushed to client catalog!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear Form
      _prodIdController.clear();
      _prodNameController.clear();
      _prodBrandController.clear();
      _prodPriceController.clear();
      _prodOrigPriceController.clear();
      _prodStockController.clear();
      _prodDescriptionController.clear();
      _prodImageController.clear();
      setState(() {
        _selectedCategory = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to push product: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isPushingProduct = false);
    }
  }

  Future<void> _submitService() async {
    if (!_serviceFormKey.currentState!.validate()) return;

    setState(() => _isPushingService = true);

    try {
      final id = _svcIdController.text.trim().toLowerCase().replaceAll(' ', '_');
      final title = _svcTitleController.text.trim();
      final description = _svcDescriptionController.text.trim();
      final priceText = _svcPriceController.text.trim();
      final price = priceText.isNotEmpty ? double.parse(priceText) : null;
      final imageUrl = _svcImageController.text.trim().isNotEmpty
          ? _svcImageController.text.trim()
          : 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=800&q=80';

      final features = _svcFeaturesController.text
          .split(',')
          .map((f) => f.trim())
          .where((f) => f.isNotEmpty)
          .toList();

      await SupabaseService.instance.addService(
        id: id,
        title: title,
        description: description,
        price: price,
        imageUrl: imageUrl,
        features: features,
      );

      // Invalidate services provider to sync services screen
      ref.invalidate(servicesProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service successfully pushed to client catalog!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear Form
      _svcIdController.clear();
      _svcTitleController.clear();
      _svcDescriptionController.clear();
      _svcPriceController.clear();
      _svcImageController.clear();
      _svcFeaturesController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to push service: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() => _isPushingService = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 72, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              const Text(
                'Admin Access Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in with an administrator account to view dashboard.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/account'),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Admin Console',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        actions: [
          // Feedback Analysis shortcut
          IconButton(
            onPressed: () => context.push('/admin/feedback'),
            icon: const Icon(Icons.psychology_rounded, color: AppTheme.primaryColor),
            tooltip: 'Feedback Analysis (NLP)',
          ),
          IconButton(
            onPressed: () {
              ref.invalidate(adminOrdersFutureProvider);
              ref.invalidate(adminServiceBookingsFutureProvider);
              ref.invalidate(adminCategoriesProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Database data reloaded')),
              );
            },
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryColor),
            tooltip: 'Reload database cache',
          ),
        ],
        bottom: TabBar(
          controller: _mainTabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Orders & Bookings'),
            Tab(icon: Icon(Icons.account_balance_wallet_outlined), text: 'Transactions'),
            Tab(icon: Icon(Icons.cloud_upload_outlined), text: 'Push Catalog'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          _buildOrdersAndBookingsTab(),
          _buildTransactionsTab(),
          _buildPushCatalogTab(),
        ],
      ),
    );
  }

  // --- TAB 1: ORDERS & BOOKINGS ---
  Widget _buildOrdersAndBookingsTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppTheme.primaryColor,
              tabs: [
                Tab(text: 'Product Orders'),
                Tab(text: 'Service Bookings'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildProductOrdersList(),
                _buildServiceBookingsList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductOrdersList() {
    final ordersAsync = ref.watch(adminOrdersFutureProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${error.toString()}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(adminOrdersFutureProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (orders) => orders.isEmpty
          ? const Center(child: Text('No orders found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return _AdminOrderCard(
                  key: ValueKey('${orders[index].id}-${orders[index].status.name}'),
                  order: orders[index],
                );
              },
            ),
    );
  }

  Widget _buildServiceBookingsList() {
    final bookingsAsync = ref.watch(adminServiceBookingsFutureProvider);

    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${error.toString()}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.invalidate(adminServiceBookingsFutureProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (bookings) => bookings.isEmpty
          ? const Center(child: Text('No service bookings found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                return _AdminServiceBookingCard(
                  key: ValueKey('${bookings[index].id}-${bookings[index].status.name}'),
                  booking: bookings[index],
                );
              },
            ),
    );
  }

  // --- TAB 2: TRANSACTIONS ---
  Widget _buildTransactionsTab() {
    final ordersAsync = ref.watch(adminOrdersFutureProvider);

    return ordersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error loading payments: $error')),
      data: (orders) {
        // Calculate Statistics
        double totalRevenue = 0;
        double pendingRevenue = 0;
        int successfulPayments = 0;
        int codOrders = 0;

        for (final order in orders) {
          final isPaid = order.paymentStatus.toLowerCase() == 'paid' || 
                         order.paymentStatus.toLowerCase() == 'success' ||
                         order.status == OrderStatus.delivered;
          if (isPaid) {
            totalRevenue += order.totalAmount;
            successfulPayments++;
          } else if (order.paymentStatus.toLowerCase() == 'pending') {
            pendingRevenue += order.totalAmount;
          }

          if (order.paymentMethod.toLowerCase().contains('cod') ||
              order.paymentMethod.toLowerCase().contains('cash')) {
            codOrders++;
          }
        }

        // Apply search & status filter
        final query = _paymentSearchController.text.toLowerCase().trim();
        final filteredOrders = orders.where((order) {
          // Status filter
          if (_paymentStatusFilter != 'All') {
            final matchesStatus = order.paymentStatus.toLowerCase() == _paymentStatusFilter.toLowerCase();
            if (!matchesStatus) return false;
          }

          // Search query
          if (query.isNotEmpty) {
            final matchesId = order.id.toLowerCase().contains(query);
            final matchesRef = order.paymentReference?.toLowerCase().contains(query) ?? false;
            final matchesAddress = order.shippingAddress?.name.toLowerCase().contains(query) ?? false;
            return matchesId || matchesRef || matchesAddress;
          }

          return true;
        }).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Stats Panel Row
            LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth;
                final bool isWeb = width > 700;
                
                return GridView.count(
                  crossAxisCount: isWeb ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isWeb ? 1.6 : 1.3,
                  children: [
                    _buildStatCard(
                      'Total Revenue',
                      CurrencyUtils.formatPrice(totalRevenue),
                      Icons.trending_up_rounded,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Paid Transactions',
                      '$successfulPayments',
                      Icons.check_circle_outline_rounded,
                      AppTheme.primaryColor,
                    ),
                    _buildStatCard(
                      'Pending Balance',
                      CurrencyUtils.formatPrice(pendingRevenue),
                      Icons.hourglass_empty_rounded,
                      Colors.amber.shade700,
                    ),
                    _buildStatCard(
                      'COD Placements',
                      '$codOrders',
                      Icons.payments_outlined,
                      Colors.teal,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Filters and Search Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaction Records',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _paymentSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Order ID, Reference, or Name...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', 'Paid', 'Pending', 'Failed'].map((status) {
                      final isSelected = _paymentStatusFilter == status;
                      return FilterChip(
                        label: Text(status),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _paymentStatusFilter = status;
                            });
                          }
                        },
                        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Records List
            filteredOrders.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Text(
                      'No matching transaction records found.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      final isPaid = order.paymentStatus.toLowerCase() == 'paid' || 
                                     order.paymentStatus.toLowerCase() == 'success';
                      final isFailed = order.paymentStatus.toLowerCase() == 'failed';
                      
                      Color statusColor = Colors.amber.shade700;
                      IconData statusIcon = Icons.hourglass_top_rounded;
                      if (isPaid) {
                        statusColor = Colors.green;
                        statusIcon = Icons.check_circle_rounded;
                      } else if (isFailed) {
                        statusColor = AppTheme.errorColor;
                        statusIcon = Icons.cancel_rounded;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        color: Colors.white,
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withValues(alpha: 0.1),
                            child: Icon(statusIcon, color: statusColor),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'ID: ${order.id}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                CurrencyUtils.formatPrice(order.totalAmount),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'Method: ${order.paymentMethod.toUpperCase()} | Date: ${_formatDate(order.orderDate)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: CrossSectionTransactionDetails(order: order),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --- TAB 3: PUSH CATALOG ---
  Widget _buildPushCatalogTab() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Push New Product'),
                selected: _activePushCatalogTab == 0,
                onSelected: (val) {
                  if (val) setState(() => _activePushCatalogTab = 0);
                },
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 16),
              ChoiceChip(
                label: const Text('Push New Service'),
                selected: _activePushCatalogTab == 1,
                onSelected: (val) {
                  if (val) setState(() => _activePushCatalogTab = 1);
                },
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _activePushCatalogTab == 0
                  ? _buildPushProductForm()
                  : _buildPushServiceForm(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPushProductForm() {
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Form(
        key: _productFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Product to Database',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                TextButton.icon(
                  onPressed: _generateMockProductData,
                  icon: const Icon(Icons.bolt, color: Colors.amber),
                  label: const Text('Autofill Mock Data'),
                ),
              ],
            ),
            const Divider(height: 24),
            
            // ID Field
            TextFormField(
              controller: _prodIdController,
              decoration: const InputDecoration(
                labelText: 'Product ID (Slug)',
                hintText: 'e.g., proc_002, lap_004',
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Product ID is required' : null,
            ),
            const SizedBox(height: 16),

            // Name Field
            TextFormField(
              controller: _prodNameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                hintText: 'e.g., Intel Core i7-14700K',
                prefixIcon: Icon(Icons.shopping_bag_outlined),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            // Brand & Stock row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prodBrandController,
                    decoration: const InputDecoration(
                      labelText: 'Brand',
                      hintText: 'Intel, Dell, Hikvision',
                      prefixIcon: Icon(Icons.copyright_rounded),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Brand is required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _prodStockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Initial Stock',
                      hintText: 'e.g., 10',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Stock is required';
                      if (int.tryParse(val.trim()) == null) return 'Must be integer';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Price & Original Price row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prodPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Selling Price (₹)',
                      hintText: 'e.g., 34999',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Price is required';
                      final cleaned = val.replaceAll(RegExp(r'[^\d\.]'), '');
                      if (double.tryParse(cleaned) == null) return 'Must be numeric';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _prodOrigPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'MSRP / Original Price (₹)',
                      hintText: 'e.g., 39999 (Optional)',
                      prefixIcon: Icon(Icons.money_off_csred_outlined),
                    ),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty) {
                        final cleaned = val.replaceAll(RegExp(r'[^\d\.]'), '');
                        if (double.tryParse(cleaned) == null) {
                          return 'Must be numeric';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            categoriesAsync.when(
              loading: () => const Center(child: LinearProgressIndicator()),
              error: (error, _) => _buildStaticCategoryDropdown(),
              data: (categories) {
                return DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Image URL
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prodImageController,
                    decoration: const InputDecoration(
                      labelText: 'Image URL',
                      hintText: 'Unsplash or local asset path (Optional)',
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingImage ? null : _uploadImage,
                    icon: _isUploadingImage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.upload_file),
                    label: const Text('Upload'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _prodDescriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Product Description',
                hintText: 'Enter full specifications and features...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.description_outlined),
                ),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Description is required' : null,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isPushingProduct ? null : _submitProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isPushingProduct
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Push Product live', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticCategoryDropdown() {
    final staticCats = [
      'Processors',
      'Laptops',
      'Networking',
      'Printers',
      'CCTV Cameras',
      'RAM',
      'Hard Disk'
    ];
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category (Offline)',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: staticCats.map((cat) {
        return DropdownMenuItem<String>(
          value: cat,
          child: Text(cat),
        );
      }).toList(),
      onChanged: (val) {
        setState(() {
          _selectedCategory = val;
        });
      },
    );
  }

  Widget _buildPushServiceForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Form(
        key: _serviceFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Service to Database',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                TextButton.icon(
                  onPressed: _generateMockServiceData,
                  icon: const Icon(Icons.bolt, color: Colors.amber),
                  label: const Text('Autofill Mock Data'),
                ),
              ],
            ),
            const Divider(height: 24),

            // ID Field
            TextFormField(
              controller: _svcIdController,
              decoration: const InputDecoration(
                labelText: 'Service ID (Slug)',
                hintText: 'e.g., svc_networking, svc_009',
                prefixIcon: Icon(Icons.tag),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Service ID is required' : null,
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _svcTitleController,
              decoration: const InputDecoration(
                labelText: 'Service Title',
                hintText: 'e.g., Access Control Installation',
                prefixIcon: Icon(Icons.build_circle_outlined),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Service title is required' : null,
            ),
            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _svcPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Starting Price (₹)',
                hintText: 'Leave empty for "Contact for price"',
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              validator: (val) {
                if (val != null && val.trim().isNotEmpty && double.tryParse(val.trim()) == null) {
                  return 'Must be numeric';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Image URL
            TextFormField(
              controller: _svcImageController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                hintText: 'Service backdrop image path',
                prefixIcon: Icon(Icons.image_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Features (Comma Separated)
            TextFormField(
              controller: _svcFeaturesController,
              decoration: const InputDecoration(
                labelText: 'Features (Comma separated)',
                hintText: 'e.g. 24/7 Monitoring, Mobile alerts, HD Quality',
                prefixIcon: Icon(Icons.featured_play_list_outlined),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Include at least one feature' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _svcDescriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Service Description',
                hintText: 'Explain the installation process, labor included, and SLA...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.description_outlined),
                ),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Service description is required' : null,
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isPushingService ? null : _submitService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isPushingService
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Push Service live', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Inner widgets to clean up the code
class CrossSectionTransactionDetails extends StatelessWidget {
  const CrossSectionTransactionDetails({super.key, required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Gateway Reference ID:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            Text(
              order.paymentReference ?? 'N/A (Cash / Unassigned)',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: order.paymentReference != null ? Colors.blue.shade900 : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Payment Status Code:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(order.paymentStatus).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                order.paymentStatus.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(order.paymentStatus),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Customer Profile Name:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            Text(
              order.shippingAddress?.name ?? 'Guest User',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Method of Checkout:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            Text(
              order.paymentMethod.toUpperCase(),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Divider(height: 20),
        const Text(
          'Purchased Products Summary:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 4),
        ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '• ${item.name} (x${item.quantity})',
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    CurrencyUtils.formatPrice(item.price * item.quantity),
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'success':
        return Colors.green;
      case 'pending':
        return Colors.amber.shade800;
      case 'failed':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }
}

// _AdminError removed because error handling is implemented inline.

class _AdminOrderCard extends ConsumerWidget {
  const _AdminOrderCard({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ID and Price
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order ID: ${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                CurrencyUtils.formatPrice(order.totalAmount),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          
          // Shipping Details
          if (order.shippingAddress != null) ...[
            Row(
              children: const [
                Icon(Icons.local_shipping_outlined, size: 18, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Shipping Address',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.shippingAddress!.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text('Phone: ${order.shippingAddress!.phone}', style: const TextStyle(fontSize: 12)),
                  Text(order.shippingAddress!.fullAddress, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                ],
              ),
            ),
            const Divider(height: 20),
          ],

          // Order Items Details
          Row(
            children: const [
              Icon(Icons.list_alt, size: 18, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Items Ordered',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Column(
              children: order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} x${item.quantity}',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        CurrencyUtils.formatPrice(item.price * item.quantity),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 20),

          // Status & Update Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Status: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(order.status),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.statusText,
                      style: TextStyle(
                        color: _getStatusTextColor(order.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              DropdownButton<OrderStatus>(
                value: order.status,
                items: OrderStatus.values.map((status) {
                  return DropdownMenuItem<OrderStatus>(
                    value: status,
                    child: Text(
                      status.name[0].toUpperCase() + status.name.substring(1),
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (newStatus) {
                  if (newStatus != null && newStatus != order.status) {
                    ref.read(adminOrdersProvider.notifier).updateStatus(order.id, newStatus).then((_) {
                      ref.invalidate(adminOrdersFutureProvider);
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusBgColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.amber.shade50;
      case OrderStatus.confirmed:
        return Colors.blue.shade50;
      case OrderStatus.processing:
        return Colors.indigo.shade50;
      case OrderStatus.shipped:
        return Colors.orange.shade50;
      case OrderStatus.delivered:
        return Colors.green.shade50;
      case OrderStatus.cancelled:
        return Colors.red.shade50;
    }
  }

  Color _getStatusTextColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.amber.shade800;
      case OrderStatus.confirmed:
        return Colors.blue.shade800;
      case OrderStatus.processing:
        return Colors.indigo.shade800;
      case OrderStatus.shipped:
        return Colors.orange.shade800;
      case OrderStatus.delivered:
        return Colors.green.shade800;
      case OrderStatus.cancelled:
        return Colors.red.shade800;
    }
  }
}

class _AdminServiceBookingCard extends ConsumerWidget {
  const _AdminServiceBookingCard({super.key, required this.booking});

  final ServiceBooking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title and Price
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.serviceName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (booking.totalPrice != null)
                Text(
                  CurrencyUtils.formatPrice(booking.totalPrice!),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
          const Divider(height: 20),

          // Client Details
          Row(
            children: const [
              Icon(Icons.person_outline, size: 18, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Customer Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text('Phone: ${booking.customerPhone}', style: const TextStyle(fontSize: 12)),
                Text('Email: ${booking.customerEmail}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const Divider(height: 20),

          // Schedule Details
          Row(
            children: const [
              Icon(Icons.calendar_today_outlined, size: 18, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Schedule Time',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Row(
              children: [
                Text(
                  _formatDate(booking.bookingDate),
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    booking.timeSlot,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),

          // Notes
          if (booking.notes != null && booking.notes!.trim().isNotEmpty) ...[
            Row(
              children: const [
                Icon(Icons.notes, size: 18, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Service Notes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(
                booking.notes!,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
            const Divider(height: 20),
          ],

          // Status & Update Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Status: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getBookingBgColor(booking.status),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      booking.statusText,
                      style: TextStyle(
                        color: _getBookingTextColor(booking.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              DropdownButton<BookingStatus>(
                value: booking.status,
                items: BookingStatus.values.map((status) {
                  return DropdownMenuItem<BookingStatus>(
                    value: status,
                    child: Text(
                      status.name[0].toUpperCase() + status.name.substring(1),
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (newStatus) {
                  if (newStatus != null && newStatus != booking.status) {
                    ref.read(adminServiceBookingsProvider.notifier).updateStatus(booking.id, newStatus).then((_) {
                      ref.invalidate(adminServiceBookingsFutureProvider);
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getBookingBgColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.amber.shade50;
      case BookingStatus.confirmed:
        return Colors.blue.shade50;
      case BookingStatus.inProgress:
        return Colors.indigo.shade50;
      case BookingStatus.completed:
        return Colors.green.shade50;
      case BookingStatus.cancelled:
        return Colors.red.shade50;
    }
  }

  Color _getBookingTextColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.amber.shade800;
      case BookingStatus.confirmed:
        return Colors.blue.shade800;
      case BookingStatus.inProgress:
        return Colors.indigo.shade800;
      case BookingStatus.completed:
        return Colors.green.shade800;
      case BookingStatus.cancelled:
        return Colors.red.shade800;
    }
  }
}
