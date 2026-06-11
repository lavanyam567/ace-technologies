import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../responsive/responsive_config.dart';

/// Adaptive navigation item
class NavItem {
  final String label;
  final IconData icon;
  final String route;
  final bool isActive;

  NavItem({
    required this.label,
    required this.icon,
    required this.route,
    this.isActive = false,
  });
}

/// Desktop Sidebar Navigation
class DesktopSidebarNav extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<NavItem> items;
  final String currentRoute;
  final ValueChanged<String> onNavigate;

  const DesktopSidebarNav({
    super.key,
    required this.isExpanded,
    required this.onToggle,
    required this.items,
    required this.currentRoute,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isExpanded ? 280 : 80,
      color: Colors.white,
      child: Column(
        children: [
          // Logo/Header
          Container(
            height: 80,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.computer,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                if (isExpanded)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ace',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            'Technologies',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Nav Items
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: Colors.grey.shade100,
                indent: isExpanded ? 0 : 16,
                endIndent: isExpanded ? 0 : 16,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                final isActive = currentRoute.startsWith(item.route);

                return Tooltip(
                  message: item.label,
                  child: InkWell(
                    onTap: () => onNavigate(item.route),
                    hoverColor: Colors.grey.shade100,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: isActive
                          ? BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              border: Border(
                                left: BorderSide(
                                  color: AppTheme.primaryColor,
                                  width: 3,
                                ),
                              ),
                            )
                          : null,
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            color: isActive
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                            size: 24,
                          ),
                          if (isExpanded) ...[
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: isActive
                                      ? AppTheme.primaryColor
                                      : AppTheme.textPrimary,
                                  fontWeight: isActive
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Toggle Button
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: IconButton(
              icon: Icon(
                isExpanded ? Icons.chevron_left : Icons.chevron_right,
                color: AppTheme.textSecondary,
              ),
              onPressed: onToggle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Desktop Top App Bar
class DesktopTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuPressed;
  final List<Widget>? actions;

  const DesktopTopAppBar({
    super.key,
    required this.onMenuPressed,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded, color: AppTheme.textPrimary),
        onPressed: onMenuPressed,
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.computer, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
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
      actions: actions,
    );
  }
}

/// Adaptive Navigation Shell for responsive layouts
class AdaptiveNavigationShell extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onNavigationChanged;
  final List<NavItem> navItems;

  const AdaptiveNavigationShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.navItems,
  });

  @override
  State<AdaptiveNavigationShell> createState() =>
      _AdaptiveNavigationShellState();
}

class _AdaptiveNavigationShellState extends State<AdaptiveNavigationShell> {
  bool _sidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    final isWebLayout = context.isWebLayout;
    final currentRoute = GoRouterState.of(context).uri.toString();

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
              items: widget.navItems,
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
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: widget.currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: widget.onNavigationChanged,
          items: widget.navItems
              .map(
                (item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.icon),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      );
    }
  }
}
