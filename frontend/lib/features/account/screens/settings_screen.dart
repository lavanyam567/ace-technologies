import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../products/providers/product_providers.dart';
import '../../services/providers/service_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final notifications = ref.watch(notificationSettingsProvider);
    final selectedLanguage = ref.watch(selectedLanguageProvider);
    final selectedRegion = ref.watch(selectedRegionProvider);
    final selectedCurrency = ref.watch(selectedCurrencyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance Section
            _buildSectionTitle('Appearance'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: AppTheme.primaryColor,
                  ),
                ),
                title: const Text('Dark Mode'),
                subtitle: Text(isDarkMode ? 'Enabled' : 'Disabled'),
                value: isDarkMode,
                onChanged: (value) {
                  ref.read(themeProvider.notifier).toggleTheme();
                },
              ),
            ),
            const SizedBox(height: 16),

            // Notifications Section
            _buildSectionTitle('Notifications'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: const Text('Push Notifications'),
                    value: notifications['push'] ?? true,
                    onChanged: (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .updateSetting('push', value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.email,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: const Text('Email Notifications'),
                    value: notifications['email'] ?? true,
                    onChanged: (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .updateSetting('email', value);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.sms,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: const Text('SMS Notifications'),
                    value: notifications['sms'] ?? false,
                    onChanged: (value) {
                      ref
                          .read(notificationSettingsProvider.notifier)
                          .updateSetting('sms', value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Privacy Section
            _buildSectionTitle('Privacy & Security'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    onTap: () => _showChangePasswordDialog(context, ref),
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    icon: Icons.delete_outline,
                    title: 'Delete Account',
                    onTap: () => _showDeleteAccountDialog(context, ref),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Language Section
            _buildSectionTitle('Language & Region'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: selectedLanguage,
                    onTap: () => _showSelectionDialog(
                      context,
                      ref,
                      'Language',
                      ['English', 'Hindi', 'Tamil', 'Spanish'],
                      selectedLanguage,
                      selectedLanguageProvider,
                    ),
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    icon: Icons.location_on_outlined,
                    title: 'Region',
                    subtitle: selectedRegion,
                    onTap: () => _showSelectionDialog(
                      context,
                      ref,
                      'Region',
                      ['India', 'United States', 'Singapore', 'United Kingdom'],
                      selectedRegion,
                      selectedRegionProvider,
                    ),
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    icon: Icons.attach_money,
                    title: 'Currency',
                    subtitle: selectedCurrency,
                    onTap: () => _showCurrencySelectionDialog(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // About Section
            _buildSectionTitle('About'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.info_outline,
                    title: 'App Version',
                    subtitle: '1.0.0',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ace Technologies version 1.0.0 is up-to-date.')),
                    ),
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () => _showDocumentDialog(
                      context,
                      'Terms of Service',
                      'Welcome to Ace Technologies. By accessing our services and products, you agree to comply with and be bound by the following terms of use:\n\n1. Sales & Warranty: All hardware products come with standard manufacturer warranty.\n2. Installation Services: CCTV and Biometric configurations require scheduled onsite access. Ensure clear site access.\n3. Payments: Transactions are processed securely via registered gateways.\n4. Liability: Ace Technologies is not liable for data loss during hardware upgrades. Please back up your data.',
                    ),
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    onTap: () => _showDocumentDialog(
                      context,
                      'Privacy Policy',
                      'Ace Technologies respects your privacy. We collect minimal personal data necessary to manage your orders, user accounts, and service bookings:\n\n1. Personal Information: Email, address, and name are stored securely in Supabase with strict RLS protections.\n2. Payment Details: Card details are never stored locally and are processed through secure external gateways.\n3. Data Deletion: Users can request complete profile and account deletion directly from Settings.',
                    ),
                  ),
                  const Divider(height: 1),
                  _buildSettingsItem(
                    icon: Icons.policy_outlined,
                    title: 'Return Policy',
                    onTap: () => _showDocumentDialog(
                      context,
                      'Return Policy',
                      'We offer returns for hardware products within 7 days of purchase:\n\n1. Hardware: Items must be in original, unopened packaging for a full refund.\n2. Services: Service fees are non-refundable once site installation has commenced.\n3. Defective Items: Defective products will be replaced under warranty terms.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Clear Cache
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _showClearCacheDialog(context, ref),
                  icon: const Icon(Icons.delete_sweep),
                  label: const Text('Clear Cache'),
                ),
              ),
            ),
            const SizedBox(height: 32),
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

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? AppTheme.errorColor.withValues(alpha: 0.1)
              : AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? AppTheme.errorColor : null,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and will erase all profile data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId != null) {
                try {
                  await Supabase.instance.client.from('profiles').delete().eq('id', userId);
                } catch (_) {}
              }
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deleted successfully')),
                );
                context.go('/home');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Reset dynamic providers
              ref.read(selectedLanguageProvider.notifier).state = 'English';
              ref.read(selectedRegionProvider.notifier).state = 'India';
              ref.read(selectedCurrencyProvider.notifier).state = 'INR (₹)';
              CurrencyUtils.updateCurrency('INR (₹)');
              
              // Re-fetch database lists
              ref.read(productsProvider.notifier).loadProducts();
              ref.read(servicesProvider.notifier).loadServices();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared and data synchronized successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final auth = ref.watch(authProvider);

            return AlertDialog(
              title: const Text('Change Password'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => obscurePassword = !obscurePassword),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Password is required';
                          if (val.length < 6) return 'Password must be 6+ characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmController,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please confirm your password';
                          if (val != passwordController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                      if (auth.error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          auth.error!,
                          style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: auth.isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          final success = await ref.read(authProvider.notifier).changePassword(passwordController.text.trim());
                          if (success && context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password updated successfully')),
                            );
                          }
                        },
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSelectionDialog(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<String> options,
    String current,
    StateProvider<String> provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            return RadioListTile<String>(
              title: Text(opt),
              value: opt,
              groupValue: current,
              onChanged: (val) {
                if (val != null) {
                  ref.read(provider.notifier).state = val;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$title updated to $val')),
                  );
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCurrencySelectionDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(selectedCurrencyProvider);
    final options = ['INR (₹)', 'USD (\$)', 'SGD (\$)', 'GBP (£)'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            return RadioListTile<String>(
              title: Text(opt),
              value: opt,
              groupValue: current,
              onChanged: (val) {
                if (val != null) {
                  ref.read(selectedCurrencyProvider.notifier).state = val;
                  CurrencyUtils.updateCurrency(opt);
                  
                  // Reload dynamic pricing lists
                  ref.read(productsProvider.notifier).loadProducts();
                  ref.read(servicesProvider.notifier).loadServices();
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Currency updated to $val')),
                  );
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showDocumentDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

final selectedLanguageProvider = StateProvider<String>((ref) => 'English');
final selectedRegionProvider = StateProvider<String>((ref) => 'India');
final selectedCurrencyProvider = StateProvider<String>((ref) => 'INR (₹)');

class NotificationSettingsNotifier extends StateNotifier<Map<String, bool>> {
  NotificationSettingsNotifier()
    : super({'push': true, 'email': true, 'sms': false});

  void updateSetting(String key, bool value) {
    state = {...state, key: value};
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, Map<String, bool>>((
      ref,
    ) {
      return NotificationSettingsNotifier();
    });
