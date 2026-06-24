import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/home_screen.dart';
import '../../features/home/screens/search_results_screen.dart';
import '../../features/home/screens/notifications_screen.dart';
import '../../features/home/screens/featured_deals_screen.dart';
import '../../features/about/about_screen.dart';
import '../../features/products/products_screen.dart';
import '../../features/products/screens/product_detail_screen.dart';
import '../../features/products/screens/image_gallery_screen.dart';
import '../../features/products/screens/reviews_screen.dart';
import '../../features/products/screens/write_review_screen.dart';
import '../../features/products/screens/wishlist_screen.dart';
import '../../features/products/screens/compare_products_screen.dart';
import '../../features/products/screens/recently_viewed_screen.dart';
import '../../features/products/screens/filter_sort_screen.dart';
import '../../features/services/services_screen.dart';
import '../../features/services/screens/service_detail_screen.dart';
import '../../features/services/screens/book_service_screen.dart';
import '../../features/services/screens/schedule_slot_screen.dart';
import '../../features/services/screens/booking_confirmation_screen.dart';
import '../../features/services/screens/service_history_screen.dart';
import '../../features/cart/screens/cart_screen.dart';
import '../../features/cart/screens/checkout_screen.dart';
import '../../features/cart/screens/address_selection_screen.dart';
import '../../features/cart/screens/add_edit_address_screen.dart';
import '../../features/cart/screens/payment_method_screen.dart';
import '../../features/cart/screens/order_success_screen.dart';
import '../../features/orders/screens/my_orders_screen.dart';
import '../../features/orders/screens/order_detail_screen.dart';
import '../../features/orders/screens/track_order_screen.dart';
import '../../features/account/screens/account_screen.dart';
import '../../features/account/screens/login_screen.dart';
import '../../features/account/screens/signup_screen.dart';
import '../../features/account/screens/profile_screen.dart';
import '../../features/account/screens/settings_screen.dart';
import '../../features/admin/screens/admin_orders_screen.dart';
import '../../features/support/noupe_chat_screen.dart';
import '../responsive/responsive_config.dart';
import '../responsive/adaptive_navigation.dart';

/// Route names
class AppRoutes {
  static const String home = '/';
  static const String searchResults = '/search';
  static const String notifications = '/notifications';
  static const String featuredDeals = '/deals';
  static const String about = '/about';

  static const String products = '/products';
  static const String productDetail = '/product/:id';
  static const String imageGallery = '/product/:id/gallery';
  static const String reviews = '/product/:id/reviews';
  static const String writeReview = '/product/:id/write-review';
  static const String wishlist = '/wishlist';
  static const String compareProducts = '/compare';
  static const String recentlyViewed = '/recent';
  static const String filterSort = '/products/filter';

  static const String services = '/services';
  static const String serviceDetail = '/service/:id';
  static const String bookService = '/service/:id/book';
  static const String scheduleSlot = '/service/:id/schedule';
  static const String serviceConfirmation = '/service/:id/confirmation';
  static const String serviceHistory = '/service-history';

  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String addressSelection = '/checkout/address';
  static const String addEditAddress = '/checkout/address/:addressId';
  static const String paymentMethod = '/checkout/payment';
  static const String orderSuccess = '/order-success/:orderId';

  static const String myOrders = '/orders';
  static const String orderDetail = '/order/:orderId';
  static const String trackOrder = '/order/:orderId/track';

  static const String account = '/account';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String adminOrders = '/admin/orders';
  static const String noupeChat = '/noupe-chat';
}

/// Navigation shell with responsive navigation (bottom nav for mobile, sidebar for web)
class MainNavigationShell extends StatefulWidget {
  final Widget child;
  final int currentIndex;

  const MainNavigationShell({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late bool _sidebarExpanded;

  @override
  void initState() {
    super.initState();
    _sidebarExpanded = true;
  }

  @override
  Widget build(BuildContext context) {
    final isWebLayout = context.isWebLayout;
    final currentRoute = GoRouterState.of(context).uri.toString();

    final navItems = [
      NavItem(
        label: 'Home',
        icon: Icons.home_outlined,
        route: AppRoutes.home,
        isActive: currentRoute == '/',
      ),
      NavItem(
        label: 'Products',
        icon: Icons.shopping_bag_outlined,
        route: AppRoutes.products,
        isActive: currentRoute.startsWith('/products'),
      ),
      NavItem(
        label: 'Services',
        icon: Icons.build_outlined,
        route: AppRoutes.services,
        isActive: currentRoute.startsWith('/services'),
      ),
      NavItem(
        label: 'About Us',
        icon: Icons.info_outline,
        route: AppRoutes.about,
        isActive: currentRoute.startsWith('/about'),
      ),
      NavItem(
        label: 'Cart',
        icon: Icons.shopping_cart_outlined,
        route: AppRoutes.cart,
        isActive: currentRoute.startsWith('/cart'),
      ),
      NavItem(
        label: 'Account',
        icon: Icons.person_outline,
        route: AppRoutes.account,
        isActive: currentRoute.startsWith('/account'),
      ),
    ];

    if (isWebLayout) {
      // Desktop/Tablet Layout with Sidebar
      return Scaffold(
        body: Row(
          children: [
            DesktopSidebarNav(
              isExpanded: _sidebarExpanded,
              onToggle: () {
                setState(() => _sidebarExpanded = !_sidebarExpanded);
              },
              items: navItems,
              currentRoute: currentRoute,
              onNavigate: (route) {
                context.go(route);
              },
            ),
            Expanded(child: widget.child),
          ],
        ),
      );
    } else {
      // Mobile Layout with Bottom Navigation
      return Scaffold(
        body: widget.child,
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(AppRoutes.noupeChat),
          tooltip: 'Chat with Ace AI',
          child: const Icon(Icons.chat_bubble_outline),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: widget.currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go(AppRoutes.home);
                break;
              case 1:
                context.go(AppRoutes.products);
                break;
              case 2:
                context.go(AppRoutes.services);
                break;
              case 3:
                context.go(AppRoutes.about);
                break;
              case 4:
                context.go(AppRoutes.cart);
                break;
              case 5:
                context.go(AppRoutes.account);
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              activeIcon: Icon(Icons.shopping_bag),
              label: 'Products',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.build_outlined),
              activeIcon: Icon(Icons.build),
              label: 'Services',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info_outline),
              activeIcon: Icon(Icons.info),
              label: 'About Us',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Account',
            ),
          ],
        ),
      );
    }
  }
}

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  final router = _createRouter();
  ref.onDispose(router.dispose);
  return router;
});

GoRouter _createRouter() {
  return GoRouter(
    redirect: (context, state) {
      // Clean Supabase OAuth callback parameters from the URL
      if (state.uri.queryParameters.containsKey('code') ||
          state.uri.queryParameters.containsKey('error') ||
          state.uri.queryParameters.containsKey('error_description')) {
        final queryParams = Map<String, String>.from(state.uri.queryParameters);
        queryParams.remove('code');
        queryParams.remove('error');
        queryParams.remove('error_description');

        final newUri = state.uri.replace(
          queryParameters: queryParams.isEmpty ? null : queryParams,
        );
        return newUri.toString();
      }
      return null;
    },
    routes: [
      // Shell route for bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationShell(
            currentIndex: _calculateIndex(state.uri.path),
            child: child,
          );
        },
        routes: [
          // Home tab
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
            routes: [
              GoRoute(
                path: 'search',
                builder: (context, state) => SearchResultsScreen(
                  query: state.uri.queryParameters['q'] ?? '',
                ),
              ),
              GoRoute(
                path: 'notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
              GoRoute(
                path: 'deals',
                builder: (context, state) => const FeaturedDealsScreen(),
              ),
            ],
          ),
          // Products tab
          GoRoute(
            path: AppRoutes.products,
            pageBuilder: (context, state) => NoTransitionPage(
              child: ProductsScreen(
                initialCategory: state.uri.queryParameters['category'],
                initialSearch: state.uri.queryParameters['search'],
              ),
            ),
            routes: [
              GoRoute(
                path: 'filter',
                builder: (context, state) => const FilterSortScreen(),
              ),
            ],
          ),
          // Services tab
          GoRoute(
            path: AppRoutes.services,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ServicesScreen()),
          ),
          // About tab
          GoRoute(
            path: AppRoutes.about,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AboutScreen()),
          ),
          // Cart tab
          GoRoute(
            path: AppRoutes.cart,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CartScreen()),
          ),
          // Account tab
          GoRoute(
            path: AppRoutes.account,
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AccountScreen()),
          ),
        ],
      ),

      // Product routes (outside shell)
      GoRoute(
        path: '/product/:id',
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'gallery',
            builder: (context, state) => ImageGalleryScreen(
              productId: state.pathParameters['id']!,
              initialIndex:
                  int.tryParse(state.uri.queryParameters['index'] ?? '0') ?? 0,
            ),
          ),
          GoRoute(
            path: 'reviews',
            builder: (context, state) =>
                ReviewsScreen(productId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'write-review',
            builder: (context, state) =>
                WriteReviewScreen(productId: state.pathParameters['id']!),
          ),
        ],
      ),

      // Service routes
      GoRoute(
        path: '/service/:id',
        builder: (context, state) =>
            ServiceDetailScreen(serviceId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'book',
            builder: (context, state) =>
                BookServiceScreen(serviceId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'schedule',
            builder: (context, state) =>
                ScheduleSlotScreen(serviceId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'confirmation',
            builder: (context, state) => BookingConfirmationScreen(
              bookingId: state.uri.queryParameters['bookingId'] ?? '',
            ),
          ),
        ],
      ),

      // Wishlist & Compare
      GoRoute(
        path: AppRoutes.wishlist,
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: AppRoutes.compareProducts,
        builder: (context, state) => const CompareProductsScreen(),
      ),
      GoRoute(
        path: AppRoutes.recentlyViewed,
        builder: (context, state) => const RecentlyViewedScreen(),
      ),
      GoRoute(
        path: AppRoutes.noupeChat,
        builder: (context, state) => const NoupeChatScreen(),
      ),

      // Checkout flow
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.addressSelection,
        builder: (context, state) => const AddressSelectionScreen(),
      ),
      GoRoute(
        path: '/checkout/address/:addressId',
        builder: (context, state) =>
            AddEditAddressScreen(addressId: state.pathParameters['addressId']),
      ),
      GoRoute(
        path: AppRoutes.paymentMethod,
        builder: (context, state) => const PaymentMethodScreen(),
      ),
      GoRoute(
        path: '/order-success/:orderId',
        builder: (context, state) =>
            OrderSuccessScreen(orderId: state.pathParameters['orderId']!),
      ),

      // Order routes
      GoRoute(
        path: AppRoutes.myOrders,
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: '/order/:orderId',
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: '/order/:orderId/track',
        builder: (context, state) =>
            TrackOrderScreen(orderId: state.pathParameters['orderId']!),
      ),

      // Service history
      GoRoute(
        path: AppRoutes.serviceHistory,
        builder: (context, state) => const ServiceHistoryScreen(),
      ),

      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminOrders,
        builder: (context, state) => const AdminOrdersScreen(),
      ),
    ],
  );
}

int _calculateIndex(String path) {
  if (path.startsWith('/products')) return 1;
  if (path.startsWith('/services')) return 2;
  if (path.startsWith('/about')) return 3;
  if (path.startsWith('/cart')) return 4;
  if (path.startsWith('/account')) return 5;
  return 0;
}
