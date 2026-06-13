import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/version_model.dart';
import '../../../providers/version_provider.dart';
import '../../../providers/settings_provider.dart';

class UpdateScreen extends ConsumerWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vState = ref.watch(versionProvider);
    final settings = ref.watch(settingsProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isAr = settings.isArabic;
    final isBlocked = vState.isBlocked;
    final info = vState.info;

    return WillPopScope(
      onWillPop: () async => !isBlocked,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: SafeArea(
          child: Column(
            children: [
              // Top gradient header
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 48),
                child: Column(
                  children: [
                    // App icon
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                      ),
                      child: const Center(
                        child: Text('🏋️', style: TextStyle(fontSize: 48)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'TO Best',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _StatusBadge(isBlocked: isBlocked, l10n: l10n),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        isBlocked ? l10n.updateRequired : l10n.updateAvailable,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Text(
                        isBlocked
                            ? (isAr ? l10n.updateRequiredDescAr : l10n.updateRequiredDescEn)
                            : (isAr ? l10n.updateOptionalDescAr : l10n.updateOptionalDescEn),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Version info card
                      if (info != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _VersionRow(
                                  label: isAr ? 'الإصدار الحالي' : 'Current Version',
                                  value: 'v${vState.currentVersionName} (${vState.currentBuild})',
                                  color: isBlocked ? AppColors.error : theme.colorScheme.onSurface,
                                  icon: isBlocked ? Icons.warning_amber_rounded : Icons.phone_android,
                                ),
                                const Divider(height: 20),
                                _VersionRow(
                                  label: isAr ? 'الإصدار الجديد' : 'New Version',
                                  value: 'v${info.latestVersionName} (${info.latestBuild})',
                                  color: AppColors.success,
                                  icon: Icons.system_update_rounded,
                                ),
                                if ((isAr ? info.notesAr : info.notesEn).isNotEmpty) ...[
                                  const Divider(height: 20),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.new_releases_outlined,
                                          size: 16, color: theme.colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          isAr ? info.notesAr : info.notesEn,
                                          style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Update button
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () => _openStore(context, info?.downloadUrl ?? ''),
                          icon: const Icon(Icons.download_rounded, size: 22),
                          label: Text(
                            l10n.updateNow,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),

                      // Skip / Later button (optional only)
                      if (!isBlocked) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () async {
                            await ref.read(versionProvider.notifier).skipUpdate();
                            if (context.mounted) Navigator.of(context).pop();
                          },
                          child: Text(
                            l10n.updateLater,
                            style: TextStyle(color: theme.textTheme.bodySmall?.color),
                          ),
                        ),
                      ],

                      // Blocked footer note
                      if (isBlocked) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.error.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline, color: AppColors.error, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isAr
                                      ? 'لا يمكن الدخول للتطبيق بدون تحديثه أولاً'
                                      : 'You must update the app before continuing',
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.updateUrlMissing),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.updateOpenFailed)),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.updateOpenFailed)),
        );
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isBlocked;
  final AppLocalizations l10n;

  const _StatusBadge({required this.isBlocked, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isBlocked ? AppColors.error.withOpacity(0.3) : Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBlocked ? AppColors.error.withOpacity(0.5) : Colors.white.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBlocked ? Icons.block_rounded : Icons.upgrade_rounded,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            isBlocked ? l10n.updateForced : l10n.updateOptional,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _VersionRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _VersionRow({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Banner shown at top of home when optional update is available
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vState = ref.watch(versionProvider);
    if (vState.status != UpdateStatus.optional) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.upgrade_rounded, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.updateBannerText,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UpdateScreen()),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.updateNow, style: const TextStyle(fontSize: 12)),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => ref.read(versionProvider.notifier).skipUpdate(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
