import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/api_service.dart';
import '../../../services/sync_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final user = ref.watch(currentUserProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    child: Text(
                      user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? '', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        Text(user?.email ?? '', style: theme.textTheme.bodySmall),
                        Text(_getRoleLabel(user?.role ?? '', l10n),
                            style: TextStyle(fontSize: 11, color: _getRoleColor(user?.role ?? ''))),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _showEditProfile(context, ref)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Appearance
          _SectionHeader(l10n.appearance),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.dark_mode_outlined,
              title: l10n.theme,
              subtitle: settings.theme == 'dark' ? l10n.darkTheme : l10n.lightTheme,
              value: settings.theme == 'dark',
              onChanged: (v) => settingsNotifier.setTheme(v ? 'dark' : 'light'),
            ),
            _Divider(),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(l10n.accentColor),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 24, height: 24, decoration: BoxDecoration(color: settings.accentColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 16),
                ],
              ),
              onTap: () => _showColorPicker(context, ref),
            ),
          ]),
          const SizedBox(height: 12),

          // Language
          _SectionHeader(l10n.language),
          _SettingsCard(children: [
            RadioListTile<String>(
              value: 'ar',
              groupValue: settings.language,
              onChanged: (v) => settingsNotifier.setLanguage(v!),
              title: Text(l10n.arabic),
              secondary: const Text('🇸🇦'),
            ),
            RadioListTile<String>(
              value: 'en',
              groupValue: settings.language,
              onChanged: (v) => settingsNotifier.setLanguage(v!),
              title: Text(l10n.english),
              secondary: const Text('🇬🇧'),
            ),
          ]),
          const SizedBox(height: 12),

          // Workout settings
          _SectionHeader(l10n.workoutSettings),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(l10n.restTimerSound),
              subtitle: Text(settings.restTimerSound),
              trailing: const Icon(Icons.chevron_right, size: 16),
              onTap: () => _showSoundPicker(context, ref, settings),
            ),
            _Divider(),
            _SwitchTile(icon: Icons.visibility_outlined, title: l10n.showOldValues, value: settings.showOldValues, onChanged: settingsNotifier.setShowOldValues),
            _Divider(),
            _SwitchTile(icon: Icons.fitness_center, title: l10n.showEpley, value: settings.showEpley, onChanged: settingsNotifier.setShowEpley),
            _Divider(),
            _SwitchTile(icon: Icons.speed, title: l10n.showRPE, value: settings.showRpe, onChanged: settingsNotifier.setShowRpe),
            _Divider(),
            _SwitchTile(icon: Icons.bar_chart, title: l10n.showVolume, value: settings.showVolume, onChanged: settingsNotifier.setShowVolume),
            _Divider(),
            _SwitchTile(icon: Icons.screen_lock_portrait, title: l10n.wakeLock, value: settings.wakeLock, onChanged: settingsNotifier.setWakeLock),
          ]),
          const SizedBox(height: 12),

          // Connection
          _SectionHeader(l10n.connection),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: Text(l10n.webAppUrl),
              subtitle: Text(
                ApiService.instance.webAppUrl.isNotEmpty ? '✓ تم الإعداد' : 'غير محدد',
                style: TextStyle(color: ApiService.instance.webAppUrl.isNotEmpty ? AppColors.success : AppColors.error),
              ),
              trailing: const Icon(Icons.chevron_right, size: 16),
              onTap: () => _showConnectionSettings(context, ref),
            ),
            _Divider(),
            ListTile(
              leading: const Icon(Icons.sync),
              title: Text(l10n.syncNow),
              onTap: () async {
                final uid = ref.read(currentUserProvider)?.uid ?? '';
                await SyncService.instance.fullPull(uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.syncDone)));
                }
              },
            ),
          ]),
          const SizedBox(height: 12),

          // Security
          _SectionHeader('الأمان'),
          _SettingsCard(children: [
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.changePassword),
              trailing: const Icon(Icons.chevron_right, size: 16),
              onTap: () => _showChangePassword(context, ref),
            ),
          ]),
          const SizedBox(height: 12),

          // Subscription
          Card(
            child: ListTile(
              leading: const Icon(Icons.star_outlined, color: AppColors.goldColor),
              title: const Text('الاشتراك'),
              subtitle: Text(_getSubStatus(ref.read(currentUserProvider))),
              trailing: const Icon(Icons.chevron_right, size: 16),
              onTap: () => context.push('/subscription'),
            ),
          ),
          const SizedBox(height: 12),

          // Logout
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(l10n.logout, style: const TextStyle(color: AppColors.error)),
              onTap: () => _showLogoutConfirm(context, ref),
            ),
          ),
          const SizedBox(height: 24),
          Center(child: Text('TO Best ${l10n.version} 1.0.0', style: theme.textTheme.labelSmall)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  String _getRoleLabel(String role, AppLocalizations l10n) {
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN': return l10n.superAdmin;
      case 'ADMIN': return l10n.adminRole;
      case 'COACH': return l10n.coach;
      case 'TRAINEE': return l10n.trainee;
      case 'VIEWER': return l10n.viewer;
      default: return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'SUPER_ADMIN': return AppColors.superAdminColor;
      case 'ADMIN': return AppColors.adminColor;
      case 'COACH': return AppColors.coachColor;
      case 'VIEWER': return AppColors.viewerColor;
      default: return AppColors.traineeColor;
    }
  }

  String _getSubStatus(user) {
    if (user == null) return 'غير مشترك';
    if (user.isAdminLike) return 'حساب إداري';
    switch (user.subscriptionStatusEffective) {
      case 'active': return 'نشط — ${user.subscriptionType == 'full' ? 'كامل' : 'خفيف'}';
      case 'expired': return 'منتهي الصلاحية';
      case 'payment_pending': return 'في انتظار التأكيد';
      default: return 'غير مشترك';
    }
  }

  void _showEditProfile(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);
    final nameCtrl = TextEditingController(text: user?.name);
    final phoneCtrl = TextEditingController(text: user?.phone);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.profile, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: InputDecoration(labelText: context.l10n.fullName)),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, decoration: InputDecoration(labelText: context.l10n.phone)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).updateProfile({'name': nameCtrl.text.trim(), 'phone': phoneCtrl.text.trim()});
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(context.l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePassword(BuildContext context, WidgetRef ref) {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.changePassword, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(controller: oldCtrl, obscureText: true, decoration: InputDecoration(labelText: context.l10n.oldPassword)),
            const SizedBox(height: 8),
            TextField(controller: newCtrl, obscureText: true, decoration: InputDecoration(labelText: context.l10n.newPassword)),
            const SizedBox(height: 8),
            TextField(controller: confirmCtrl, obscureText: true, decoration: InputDecoration(labelText: context.l10n.confirmPass)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                if (newCtrl.text != confirmCtrl.text) return;
                final err = await ref.read(authProvider.notifier).changePassword(
                  oldPassword: oldCtrl.text, newPassword: newCtrl.text,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? context.l10n.saved)));
                }
              },
              child: Text(context.l10n.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref) {
    const colors = [
      Color(0xFF7C6EFF), Color(0xFF4CAF50), Color(0xFFE53935),
      Color(0xFFFF6B6B), Color(0xFFFFD93D), Color(0xFF4D96FF),
      Color(0xFF6BCB77), Color(0xFFFF9F43), Color(0xFF00B0FF),
    ];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.accentColor, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(spacing: 12, runSpacing: 12, children: colors.map((c) => GestureDetector(
              onTap: () { ref.read(settingsProvider.notifier).setAccentColor(c); Navigator.pop(ctx); },
              child: Container(width: 44, height: 44, decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
            )).toList()),
          ],
        ),
      ),
    );
  }

  void _showSoundPicker(BuildContext context, WidgetRef ref, AppSettings settings) {
    const sounds = ['bell', 'beep', 'chime', 'whistle', 'silent'];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: sounds.map((s) => RadioListTile<String>(
          value: s, groupValue: settings.restTimerSound,
          title: Text(s), onChanged: (v) { ref.read(settingsProvider.notifier).setRestTimerSound(v!); Navigator.pop(ctx); },
        )).toList(),
      ),
    );
  }

  void _showConnectionSettings(BuildContext context, WidgetRef ref) {
    final urlCtrl = TextEditingController(text: ApiService.instance.webAppUrl);
    final secretCtrl = TextEditingController(text: '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.connection, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(controller: urlCtrl, decoration: InputDecoration(labelText: context.l10n.webAppUrl, hintText: 'https://script.google.com/...')),
            const SizedBox(height: 8),
            TextField(controller: secretCtrl, obscureText: true, decoration: InputDecoration(labelText: context.l10n.secretKey)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await ApiService.instance.saveConfig(urlCtrl.text.trim(), secretCtrl.text.trim());
                final result = await ApiService.instance.testConnection();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  final l10n = context.l10n;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result?['ok'] == true ? l10n.connOK : l10n.connFail),
                    backgroundColor: result?['ok'] == true ? AppColors.success : AppColors.error,
                  ));
                }
              },
              child: Text(context.l10n.testConnection),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.logout),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.l10n.cancel)),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/auth/login');
            },
            child: Text(context.l10n.logout, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4, left: 4),
      child: Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700,
      )),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Card(child: Column(children: children));
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final Function(bool) onChanged;
  const _SwitchTile({required this.icon, required this.title, this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      value: value,
      onChanged: onChanged,
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(height: 1, indent: 56);
}
