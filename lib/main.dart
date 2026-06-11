import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/responsive/responsive_provider.dart';
import 'features/providers/theme_provider.dart';
import 'features/providers/address_provider.dart' as riverpod_address;
import 'features/providers/cart_provider.dart' as riverpod_cart;
import 'features/products/providers/wishlist_provider.dart'
    as riverpod_wishlist;
import 'package:provider/provider.dart' as prov;
import 'features/chatbot/providers/chat_provider.dart';
import 'features/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.validate();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const ProviderScope(child: AceTechnologiesApp()));
}

class AceTechnologiesApp extends ConsumerWidget {
  const AceTechnologiesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(riverpod_cart.cartProvider);
    ref.watch(riverpod_address.savedAddressesProvider);
    ref.watch(riverpod_wishlist.wishlistProvider);
    ref.watch(authProvider);

    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return prov.ChangeNotifierProvider(
      create: (_) => ChatProvider(),
      child: ResponsiveObserver(
        child: MaterialApp.router(
          title: 'Ace Technologies - IT & Security Solutions',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
        ),
      ),
    );
  }
}
