import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/exercise_data.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/local_db_service.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});
  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  Map<String, dynamic> _recentLogs = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final logs = await LocalDbService.instance.getAllWorkoutLogs(user.uid);
    if (mounted) setState(() { _recentLogs = logs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final program = ExerciseData.programs[settings.selectedProgram];
    final sessions = ExerciseData.programSessions[settings.selectedProgram] ?? [];
    final today = DateTime.now().weekday % 7;
    final isGymDay = settings.gymDays.contains(today);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workout),
        actions: [
          TextButton.icon(
            onPressed: () => _showProgramSelector(context, settings),
            icon: const Icon(Icons.swap_horiz),
            label: Text(settings.selectedProgram),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Program info card
            Card(
              color: theme.colorScheme.primary.withOpacity(0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.fitness_center, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(program?['name'] ?? settings.selectedProgram,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          Text(program?['description'] ?? program?['descEn'] ?? '',
                              style: theme.textTheme.bodySmall),
                          Text('${settings.programDays} ${l10n.daysPerWeek}',
                              style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Today marker
            if (isGymDay) ...[
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(l10n.todaySession, style: theme.textTheme.titleSmall?.copyWith(color: AppColors.success)),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Sessions list
            Text('جلسات البرنامج', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...sessions.asMap().map((i, session) {
              final todaySessionIndex = _getTodaySessionIndex(settings);
              final isToday = i == todaySessionIndex;
              final lastLog = _getLastLog(session);
              return MapEntry(i, _SessionCard(
                sessionName: session,
                isToday: isToday,
                lastLog: lastLog,
                programId: settings.selectedProgram,
                onTap: () => context.push('/workout/session', extra: {
                  'sessionName': session,
                  'programId': settings.selectedProgram,
                }),
              ));
            }).values.toList(),

            const SizedBox(height: 20),

            // Recent logs section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('الجلسات الأخيرة', style: theme.textTheme.titleMedium),
                Text('${_recentLogs.length} جلسة', style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading) const Center(child: CircularProgressIndicator())
            else if (_recentLogs.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text('لا توجد جلسات مسجلة بعد', style: theme.textTheme.bodyMedium)),
                ),
              )
            else ..._recentLogs.entries.take(5).map((e) {
              final log = e.value as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text(log['sessionName']?.toString() ?? '', style: theme.textTheme.titleSmall),
                  subtitle: Text(e.key),
                  trailing: Text('${(log['exercises'] as List?)?.length ?? 0} تمارين',
                      style: theme.textTheme.bodySmall),
                ),
              );
            }).toList(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  int _getTodaySessionIndex(AppSettings settings) {
    final today = DateTime.now().weekday % 7;
    final gymDaysSorted = List.from(settings.gymDays)..sort();
    final idx = gymDaysSorted.indexOf(today);
    if (idx < 0) return -1;
    final sessions = ExerciseData.programSessions[settings.selectedProgram] ?? [];
    return sessions.isEmpty ? -1 : idx % sessions.length;
  }

  Map<String, dynamic>? _getLastLog(String sessionName) {
    for (final entry in _recentLogs.entries) {
      if (entry.value is Map && entry.value['sessionName'] == sessionName) {
        return entry.value as Map<String, dynamic>;
      }
    }
    return null;
  }

  void _showProgramSelector(BuildContext context, AppSettings settings) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('اختر البرنامج التدريبي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          ...ExerciseData.programs.entries.map((e) {
            final isSelected = settings.selectedProgram == e.key;
            return ListTile(
              leading: Icon(Icons.fitness_center,
                  color: isSelected ? Theme.of(ctx).colorScheme.primary : null),
              title: Text(e.value['name'] ?? e.key),
              subtitle: Text(e.value['description'] ?? ''),
              trailing: isSelected ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary) : null,
              onTap: () {
                ref.read(settingsProvider.notifier).setSelectedProgram(e.key);
                final days = (e.value['daysOptions'] as List?)?.first as int? ?? 4;
                ref.read(settingsProvider.notifier).setProgramDays(days);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final String sessionName;
  final bool isToday;
  final Map<String, dynamic>? lastLog;
  final String programId;
  final VoidCallback onTap;

  const _SessionCard({
    required this.sessionName,
    required this.isToday,
    required this.lastLog,
    required this.programId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exercises = ExerciseData.sessions[sessionName] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isToday ? theme.colorScheme.primary.withOpacity(0.08) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('اليوم', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  if (isToday) const SizedBox(height: 4),
                  Text(sessionName, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text('${exercises.length} تمارين', style: theme.textTheme.bodySmall),
                  if (lastLog != null)
                    Text('آخر تمرين: ${_formatExerciseSummary(lastLog!)}',
                        style: theme.textTheme.labelSmall),
                ],
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatExerciseSummary(Map<String, dynamic> log) {
    final exCount = (log['exercises'] as List?)?.length ?? 0;
    return '$exCount تمارين';
  }
}
