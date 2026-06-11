import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: auth.isAuthenticated
          ? _buildProfile(context, ref, auth)
          : _buildLogin(context, ref, auth),
    );
  }

  Widget _buildLogin(BuildContext context, WidgetRef ref, AuthState auth) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_outline,
              size: 72,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Login to your account',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'View orders, wishlist, addresses, and settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outlined),
              ),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Text(
                _friendlyError(auth.error!),
                style: const TextStyle(color: AppTheme.errorColor),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.isLoading
                    ? null
                    : () => _loginFromAccount(context),
                child: Text(auth.isLoading ? 'Logging in...' : 'Login'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/signup'),
              child: const Text('Create account'),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => context.push('/chat'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 10),
                    Expanded(child: Text('Have questions? Chat with Ace AI →')),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loginFromAccount(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter email and password')));
      return;
    }

    await ref.read(authProvider.notifier).login(email, password);
  }

  String _friendlyError(String error) {
    if (error.toLowerCase().contains('invalid login')) {
      return 'Invalid email or password.';
    }
    return error
        .replaceFirst('AuthException(message: ', '')
        .replaceFirst(')', '');
  }

  Widget _buildProfile(BuildContext context, WidgetRef ref, AuthState auth) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.primaryColor,
                backgroundImage: auth.avatarUrl.isNotEmpty
                    ? NetworkImage(auth.avatarUrl)
                    : null,
                child: auth.avatarUrl.isEmpty
                    ? Text(
                        auth.name.isNotEmpty ? auth.name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      auth.name.isNotEmpty ? auth.name : 'User',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.email.isNotEmpty ? auth.email : 'user@example.com',
                    ),
                    const SizedBox(height: 2),
                    if (auth.phone.isNotEmpty)
                      Text(
                        auth.phone,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (auth.isAdmin) ...[
          _MenuItem(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Admin Orders',
            onTap: () => context.go('/admin/orders'),
          ),
          const SizedBox(height: 8),
        ],
        _MenuItem(
          icon: Icons.shopping_bag_outlined,
          title: 'Orders',
          onTap: () => context.go('/orders'),
        ),
        _MenuItem(
          icon: Icons.favorite_outline,
          title: 'Wishlist',
          onTap: () => context.go('/wishlist'),
        ),
        _MenuItem(
          icon: Icons.location_on_outlined,
          title: 'Address',
          onTap: () => context.go('/checkout/address'),
        ),
        _MenuItem(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          onTap: () => context.go('/notifications'),
        ),
        _MenuItem(
          icon: Icons.settings_outlined,
          title: 'Settings',
          onTap: () => context.go('/settings'),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => ref.read(authProvider.notifier).logout(),
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
