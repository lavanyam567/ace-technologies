import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileSheet(context, ref, auth),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (auth.isProfileLoading) const LinearProgressIndicator(),
            if (auth.error != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  auth.error!,
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              ),
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryColor,
                    backgroundImage: auth.avatarUrl.isNotEmpty
                        ? NetworkImage(auth.avatarUrl)
                        : null,
                    child: auth.avatarUrl.isEmpty
                        ? Text(
                            auth.name.isNotEmpty
                                ? auth.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.email.isNotEmpty
                              ? auth.email
                              : 'user@example.com',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 4),
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

            // Account Section
            _buildSectionTitle('Account'),
            _buildMenuItem(
              icon: Icons.shopping_bag_outlined,
              title: 'My Orders',
              subtitle: 'View all your orders',
              onTap: () => context.go('/orders'),
            ),
            _buildMenuItem(
              icon: Icons.calendar_today_outlined,
              title: 'Service Bookings',
              subtitle: 'View your service history',
              onTap: () => context.go('/service-history'),
            ),
            _buildMenuItem(
              icon: Icons.favorite_outline,
              title: 'Wishlist',
              subtitle: 'Your saved products',
              onTap: () => context.go('/wishlist'),
            ),
            _buildMenuItem(
              icon: Icons.history,
              title: 'Recently Viewed',
              subtitle: 'Products you viewed',
              onTap: () => context.go('/recent'),
            ),
            const SizedBox(height: 16),

            // Addresses Section
            _buildSectionTitle('Addresses'),
            _buildMenuItem(
              icon: Icons.location_on_outlined,
              title: 'Saved Addresses',
              subtitle: 'Manage delivery addresses',
              onTap: () => context.go('/checkout/address'),
            ),
            const SizedBox(height: 16),

            // Support Section
            _buildSectionTitle('Support'),
            _buildMenuItem(
              icon: Icons.help_outline,
              title: 'Help Center',
              subtitle: 'FAQs and support',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.chat_outlined,
              title: 'Chat with Us',
              subtitle: 'Get quick support',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.phone_outlined,
              title: 'Contact Us',
              subtitle: 'Reach our support team',
              onTap: () {},
            ),
            const SizedBox(height: 16),

            // Legal Section
            _buildSectionTitle('Legal'),
            _buildMenuItem(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              subtitle: 'View terms',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'View privacy policy',
              onTap: () {},
            ),
            _buildMenuItem(
              icon: Icons.policy_outlined,
              title: 'Return Policy',
              subtitle: 'View return policy',
              onTap: () {},
            ),
            const SizedBox(height: 16),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                  icon: const Icon(Icons.logout, color: AppTheme.errorColor),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.errorColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App Version
            Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    AuthState auth,
  ) {
    final nameController = TextEditingController(text: auth.name);
    final phoneController = TextEditingController(text: auth.phone);
    final imageController = TextEditingController(text: auth.avatarUrl);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final currentAuth = ref.watch(authProvider);
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: imageController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Profile image URL',
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                  ),
                  if (currentAuth.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      currentAuth.error!,
                      style: const TextStyle(color: AppTheme.errorColor),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: currentAuth.isLoading
                          ? null
                          : () async {
                              final success = await ref
                                  .read(authProvider.notifier)
                                  .updateProfile(
                                    name: nameController.text.trim(),
                                    phone: phoneController.text.trim(),
                                    profileImageUrl:
                                        imageController.text.trim().isEmpty
                                        ? null
                                        : imageController.text.trim(),
                                  );
                              if (!context.mounted) return;
                              if (success) Navigator.of(sheetContext).pop();
                            },
                      child: Text(
                        currentAuth.isLoading ? 'Saving...' : 'Save Profile',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      phoneController.dispose();
      imageController.dispose();
    });
  }
}
