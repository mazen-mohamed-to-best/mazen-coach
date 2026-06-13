import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/app_localizations.dart';
import '../../models/version_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/version_provider.dart';
import '../../services/sync_service.dart';
import '../../features/update/screens/update_screen.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final syncStatus = ref.watch(syncNotifierProvider);
    final versionState = ref.watch(versionProvider);
    final l10n = context.l10n;
    final location = GoRouterState.of(context).uri.toString();

    final navItems = _buildNavItems(l10n, user?.isAdminLike ?? false);
    final currentIndex = _indexFromPath(location);

    return Scaffold(
      body: Column(
        children: [
          // ── Update banner (optional update) ───────────────
          if (versionState.status == UpdateStatus.optional)
            const UpdateBanner(),

          // ── Offline banner ────────────────────────────────
          if (!_isOnline(syncStatus))
            Material(
              child: Container(
                color: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.offlineNote,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Main content ──────────────────────────────────
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex < 0 ? 0 : currentIndex,
        onDestinationSelected: (i) => context.go(navItems[i].path),
        destinations: navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(
                    item.activeIcon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }

  bool _isOnline(SyncStatus status) => status != SyncStatus.offline;

  int _indexFromPath(String path) {
    const navPaths = [
      '/home', '/workout', '/nutrition',
      '/attendance', '/progress', '/chat', '/settings',
    ];
    for (int i = 0; i < navPaths.length; i++) {
      if (path.startsWith(navPaths[i])) return i;
    }
    return 0;
  }

  List<_NavItem> _buildNavItems(AppLocalizations l10n, bool isAdmin) {
    return [
      _NavItem(l10n.home, '/home', Icons.home_outlined, Icons.home),
      _NavItem(l10n.workout, '/workout', Icons.fitness_center_outlined, Icons.fitness_center),
      _NavItem(l10n.nutrition, '/nutrition', Icons.restaurant_outlined, Icons.restaurant),
      _NavItem(l10n.attendance, '/attendance', Icons.calendar_month_outlined, Icons.calendar_month),
      _NavItem(l10n.progress, '/progress', Icons.bar_chart_outlined, Icons.bar_chart),
      _NavItem(l10n.chat, '/chat', Icons.chat_outlined, Icons.chat),
      _NavItem(l10n.settings, '/settings', Icons.settings_outlined, Icons.settings),
    ];
  }
}

class _NavItem {
  final String label;
  final String path;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem(this.label, this.path, this.icon, this.activeIcon);
}
