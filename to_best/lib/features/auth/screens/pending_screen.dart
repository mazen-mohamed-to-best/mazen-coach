import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';

class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final isRejected = user?.status == 'rejected';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: isRejected ? AppColors.error.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isRejected ? Icons.cancel_outlined : Icons.hourglass_empty,
                    size: 52,
                    color: isRejected ? AppColors.error : Colors.orange,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  isRejected ? l10n.rejected : l10n.pendingApproval,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  isRejected ? l10n.rejectedDesc : l10n.pendingDesc,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (!isRejected) ...[
                  OutlinedButton.icon(
                    onPressed: () => ref.read(authProvider.notifier).refreshUser(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('تحديث الحالة'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextButton(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/auth/login');
                  },
                  child: Text(l10n.logout),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
