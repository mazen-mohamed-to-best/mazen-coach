import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);

    final subStatus = user?.subscriptionStatusEffective ?? 'no_subscription';
    final isActive = subStatus == 'active' || subStatus == 'admin';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.subscription)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current status
            _StatusCard(subStatus: subStatus, user: user, l10n: l10n, theme: theme),
            const SizedBox(height: 24),

            if (!isActive || subStatus == 'expired') ...[
              Text('اختر خطتك', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              _PlanCard(
                planId: 'light',
                title: l10n.subLight,
                description: 'تدريب + حضور + شات عام',
                price: 100,
                color: const Color(0xFF4CAF50),
                features: const ['✔ جدول التمرين', '✔ سجل الحضور', '✔ الدردشة العامة', '✘ التغذية', '✘ التقدم والقياسات', '✘ الشات مع المدرب'],
                onSelect: () => context.push('/subscription/pay', extra: {'planId': 'light'}),
                l10n: l10n,
                theme: theme,
              ),
              const SizedBox(height: 12),
              _PlanCard(
                planId: 'full',
                title: l10n.subFull,
                description: 'جميع الميزات بدون قيود',
                price: 200,
                color: AppColors.goldColor,
                features: const ['✔ جدول التمرين', '✔ التغذية وتتبع الوجبات', '✔ سجل الحضور', '✔ التقدم والقياسات', '✔ الدردشة العامة', '✔ الشات مع المدرب', '✔ مساعد AI'],
                highlighted: true,
                onSelect: () => context.push('/subscription/pay', extra: {'planId': 'full'}),
                l10n: l10n,
                theme: theme,
              ),
            ] else ...[
              // Active sub details
              Text('تفاصيل الاشتراك', style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('نوع الاشتراك', style: theme.textTheme.bodySmall),
                          Text(user?.subscriptionType == 'full' ? 'كامل 🌟' : 'خفيف',
                              style: theme.textTheme.titleSmall?.copyWith(color: AppColors.goldColor)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (user?.subscriptionEnd != null) Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l10n.expiresOn, style: theme.textTheme.bodySmall),
                          Text(
                            _formatDate(DateTime.fromMillisecondsSinceEpoch(user!.subscriptionEnd!)),
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.push('/subscription/pay', extra: {'planId': user?.subscriptionType ?? 'full'}),
                          child: Text(l10n.renewSubscription),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (subStatus == 'payment_pending') ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.orange.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.pending_outlined, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.paymentPending, style: theme.textTheme.titleSmall),
                          Text('في انتظار مراجعة المدرب. سيتم تفعيل اشتراكك قريباً.', style: theme.textTheme.bodySmall),
                        ],
                      )),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

class _StatusCard extends StatelessWidget {
  final String subStatus;
  final dynamic user;
  final AppLocalizations l10n;
  final ThemeData theme;
  const _StatusCard({required this.subStatus, required this.user, required this.l10n, required this.theme});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String title;
    String subtitle;

    switch (subStatus) {
      case 'active':
        color = AppColors.success;
        icon = Icons.verified;
        title = l10n.subscriptionActive;
        subtitle = user?.subscriptionType == 'full' ? l10n.subFull : l10n.subLight;
        break;
      case 'admin':
        color = AppColors.goldColor;
        icon = Icons.admin_panel_settings;
        title = 'حساب إداري';
        subtitle = 'وصول كامل لجميع الميزات';
        break;
      case 'payment_pending':
        color = Colors.orange;
        icon = Icons.pending;
        title = l10n.paymentPending;
        subtitle = 'جارٍ مراجعة الدفع';
        break;
      case 'expired':
        color = AppColors.error;
        icon = Icons.cancel;
        title = l10n.subscriptionExpired;
        subtitle = 'قم بتجديد اشتراكك';
        break;
      default:
        color = AppColors.darkSubText;
        icon = Icons.lock_outline;
        title = 'لا يوجد اشتراك';
        subtitle = 'اشترك لاستخدام جميع الميزات';
    }

    return Card(
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String planId;
  final String title;
  final String description;
  final double price;
  final Color color;
  final List<String> features;
  final bool highlighted;
  final VoidCallback onSelect;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _PlanCard({
    required this.planId,
    required this.title,
    required this.description,
    required this.price,
    required this.color,
    required this.features,
    this.highlighted = false,
    required this.onSelect,
    required this.l10n,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlighted ? color.withOpacity(0.06) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: highlighted ? color : Colors.transparent, width: highlighted ? 2 : 0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (highlighted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
                child: const Text('الأكثر شيوعاً', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            if (highlighted) const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: color)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$price', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: color)),
                    Text('ريال / شهر', style: theme.textTheme.labelSmall),
                  ],
                ),
              ],
            ),
            Text(description, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(f, style: theme.textTheme.bodySmall?.copyWith(
                color: f.startsWith('✔') ? null : theme.textTheme.bodySmall?.color?.withOpacity(0.4),
              )),
            )).toList(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSelect,
                style: ElevatedButton.styleFrom(backgroundColor: color),
                child: Text('${l10n.subscribeNow} — $title'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
