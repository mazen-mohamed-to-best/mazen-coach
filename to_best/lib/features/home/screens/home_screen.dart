import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/exercise_data.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/sync_provider.dart';
import '../../../services/local_db_service.dart';
import '../../../services/sync_service.dart';
import '../../../widgets/common/stats_card.dart';
import '../../../widgets/common/sync_indicator.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Map<String, dynamic> _logs = {};
  bool _loadingLogs = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final logs = await LocalDbService.instance.getAllWorkoutLogs(user.uid);
    if (mounted) setState(() { _logs = logs; _loadingLogs = false; });
  }

  String _getGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 17) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  String? _getTodaySession() {
    final settings = ref.read(settingsProvider);
    final today = DateTime.now().weekday % 7;
    if (!settings.gymDays.contains(today)) return null;
    final sessions = ExerciseData.programSessions[settings.selectedProgram];
    if (sessions == null || sessions.isEmpty) return null;
    final gymDaysSorted = List.from(settings.gymDays)..sort();
    final gymDayIndex = gymDaysSorted.indexOf(today);
    if (gymDayIndex < 0) return null;
    return sessions[gymDayIndex % sessions.length];
  }

  int _getTotalSessions() => _logs.length;

  int _getStreak() {
    int streak = 0;
    var date = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final key = _formatDate(date);
      if (_logs.containsKey(key)) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<MapEntry<String, double>> _getTopPRs() {
    final prs = <String, double>{};
    _logs.forEach((date, logData) {
      if (logData is! Map) return;
      final exercises = (logData['exercises'] as List<dynamic>? ?? []);
      for (final ex in exercises) {
        if (ex is! Map) continue;
        final name = ex['name']?.toString() ?? '';
        final sets = ex['sets'] as List<dynamic>? ?? [];
        for (final s in sets) {
          if (s is! Map) continue;
          final w = double.tryParse(s['weight']?.toString() ?? '') ?? 0;
          if (w > (prs[name] ?? 0)) prs[name] = w;
        }
      }
    });
    final sorted = prs.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final todaySession = _getTodaySession();
    final prs = _getTopPRs();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: SyncIndicator(),
          ),
          if (user?.isAdminLike ?? false)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => context.go('/admin'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final uid = ref.read(currentUserProvider)?.uid ?? '';
          await SyncService.instance.fullPull(uid);
          await _loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text('${_getGreeting(l10n)}, ${user?.name.split(' ').first ?? ''}!',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(l10n.tagline, style: theme.textTheme.bodySmall),
              const SizedBox(height: 24),

              // Today's session card
              Card(
                color: todaySession != null
                    ? theme.colorScheme.primary.withOpacity(0.12)
                    : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: todaySession != null ? () => context.go('/workout') : null,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: todaySession != null
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            todaySession != null ? Icons.fitness_center : Icons.bedtime_outlined,
                            color: todaySession != null ? Colors.white : theme.colorScheme.onSurface,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                todaySession != null ? l10n.todaySession : l10n.restDay,
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                todaySession ?? 'استرح واسترجع طاقتك 💤',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        if (todaySession != null)
                          Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  Expanded(child: StatsCard(
                    title: l10n.totalSessions,
                    value: _getTotalSessions().toString(),
                    icon: Icons.bar_chart,
                    iconColor: AppColors.accent,
                    onTap: () => context.go('/progress'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: StatsCard(
                    title: l10n.streak,
                    value: '${_getStreak()} 🔥',
                    icon: Icons.local_fire_department,
                    iconColor: Colors.orange,
                    onTap: () => context.go('/attendance'),
                  )),
                ],
              ),
              const SizedBox(height: 16),

              // Quick access
              Text(l10n.quickAccess, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              _QuickAccessGrid(),
              const SizedBox(height: 24),

              // Recent PRs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.latestPRs, style: theme.textTheme.titleMedium),
                  TextButton(onPressed: () => context.go('/progress'), child: const Text('عرض الكل')),
                ],
              ),
              const SizedBox(height: 8),
              if (_loadingLogs)
                const Center(child: CircularProgressIndicator())
              else if (prs.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.emoji_events_outlined, size: 40, color: AppColors.goldColor),
                          const SizedBox(height: 8),
                          Text(l10n.noPRs, style: theme.textTheme.titleMedium),
                          Text(l10n.noPRsDesc, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ...prs.map((pr) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Text('🏆', style: TextStyle(fontSize: 24)),
                    title: Text(pr.key, style: theme.textTheme.titleSmall),
                    trailing: Text('${pr.value.toStringAsFixed(1)} kg',
                        style: TextStyle(color: AppColors.goldColor, fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                )).toList(),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAccessGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final items = [
      _QAItem(l10n.workout, Icons.fitness_center, '/workout', AppColors.accent, true),
      _QAItem(l10n.nutrition, Icons.restaurant, '/nutrition', AppColors.primaryGreen,
          user?.featureAllowed('nutrition') ?? false),
      _QAItem(l10n.attendance, Icons.calendar_month, '/attendance', Colors.orange, true),
      _QAItem(l10n.progress, Icons.bar_chart, '/progress', Colors.purple,
          user?.featureAllowed('progress') ?? false),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: items.map((item) {
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: item.enabled ? () => context.go(item.path) : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('هذه الميزة تتطلب اشتراكاً'),
                    action: SnackBarAction(label: 'اشترك', onPressed: () => context.go('/subscription'))),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(item.icon, color: item.enabled ? item.color : Colors.grey, size: 28),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: item.enabled ? null : Colors.grey,
                      ))),
                  if (!item.enabled)
                    const Icon(Icons.lock_outlined, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QAItem {
  final String label;
  final IconData icon;
  final String path;
  final Color color;
  final bool enabled;
  const _QAItem(this.label, this.icon, this.path, this.color, this.enabled);
}
