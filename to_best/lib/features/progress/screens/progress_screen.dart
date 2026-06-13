import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/local_db_service.dart';
import '../../../services/sync_service.dart';
import '../../../models/attendance_model.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});
  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<dynamic> _measurements = [];
  Map<String, dynamic> _logs = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final meas = await LocalDbService.instance.getMeasurements(user.uid);
    final logs = await LocalDbService.instance.getAllWorkoutLogs(user.uid);
    if (mounted) setState(() { _measurements = meas; _logs = logs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.progress),
        bottom: TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'القياسات'), Tab(text: 'الأوزان'), Tab(text: 'الإحصائيات')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tab,
              children: [
                _MeasurementsTab(measurements: _measurements, onAdd: _showAddMeasurement, theme: theme),
                _WeightsTab(logs: _logs, theme: theme),
                _StatsTab(logs: _logs, measurements: _measurements, theme: theme, l10n: l10n),
              ],
            ),
    );
  }

  void _showAddMeasurement(BuildContext context) {
    final weightCtrl = TextEditingController();
    final waistCtrl = TextEditingController();
    final chestCtrl = TextEditingController();
    final armCtrl = TextEditingController();
    final thighCtrl = TextEditingController();
    final bfCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, left: 16, right: 16, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('إضافة قياسات', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _MeasField(weightCtrl, 'الوزن (kg)')),
              const SizedBox(width: 8),
              Expanded(child: _MeasField(bfCtrl, 'دهون الجسم (%)')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _MeasField(chestCtrl, 'الصدر (cm)')),
              const SizedBox(width: 8),
              Expanded(child: _MeasField(waistCtrl, 'الخصر (cm)')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _MeasField(armCtrl, 'الذراع (cm)')),
              const SizedBox(width: 8),
              Expanded(child: _MeasField(thighCtrl, 'الفخذ (cm)')),
            ]),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final user = ref.read(currentUserProvider);
                if (user == null) return;
                final now = DateTime.now();
                final entry = {
                  'date': '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}',
                  'weight': double.tryParse(weightCtrl.text) ?? 0,
                  'bodyFat': double.tryParse(bfCtrl.text),
                  'chest': double.tryParse(chestCtrl.text),
                  'waist': double.tryParse(waistCtrl.text),
                  'leftArm': double.tryParse(armCtrl.text),
                  'leftThigh': double.tryParse(thighCtrl.text),
                };
                final updated = [entry, ..._measurements];
                await SyncService.instance.enqueueMeasurements(user.uid, updated);
                setState(() => _measurements = updated);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  const _MeasField(this.ctrl, this.label);
  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, isDense: true),
  );
}

class _MeasurementsTab extends StatelessWidget {
  final List<dynamic> measurements;
  final Function(BuildContext) onAdd;
  final ThemeData theme;
  const _MeasurementsTab({required this.measurements, required this.onAdd, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => onAdd(context),
              icon: const Icon(Icons.add),
              label: const Text('إضافة قياسات جديدة'),
            ),
          ),
        ),
        if (measurements.isEmpty)
          Expanded(child: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.straighten, size: 60, color: AppColors.darkSubText),
              const SizedBox(height: 12),
              Text('لا توجد قياسات بعد', style: theme.textTheme.bodyLarge),
            ],
          )))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: measurements.length,
              itemBuilder: (ctx, i) {
                final m = measurements[i] as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['date']?.toString() ?? '', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Wrap(spacing: 16, runSpacing: 4, children: [
                          if (m['weight'] != null) _MeasChip('⚖️ ${m['weight']} kg'),
                          if (m['bodyFat'] != null) _MeasChip('💉 ${m['bodyFat']}%'),
                          if (m['chest'] != null) _MeasChip('💪 ${m['chest']} cm'),
                          if (m['waist'] != null) _MeasChip('🔲 ${m['waist']} cm'),
                          if (m['leftArm'] != null) _MeasChip('💪 ذراع: ${m['leftArm']} cm'),
                          if (m['leftThigh'] != null) _MeasChip('🦵 ${m['leftThigh']} cm'),
                        ]),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _MeasChip extends StatelessWidget {
  final String label;
  const _MeasChip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _WeightsTab extends StatelessWidget {
  final Map<String, dynamic> logs;
  final ThemeData theme;
  const _WeightsTab({required this.logs, required this.theme});

  @override
  Widget build(BuildContext context) {
    // Extract PR data per exercise
    final prs = <String, List<FlSpot>>{};
    int dateIdx = 0;
    final sortedKeys = logs.keys.toList()..sort();
    for (final date in sortedKeys) {
      final log = logs[date] as Map<String, dynamic>?;
      final exercises = (log?['exercises'] as List<dynamic>?) ?? [];
      for (final ex in exercises) {
        if (ex is! Map) continue;
        final name = ex['name']?.toString() ?? '';
        final sets = ex['sets'] as List<dynamic>? ?? [];
        double maxW = 0;
        for (final s in sets) {
          if (s is! Map) continue;
          final w = double.tryParse(s['weight']?.toString() ?? '') ?? 0;
          if (w > maxW) maxW = w;
        }
        if (maxW > 0) {
          prs.putIfAbsent(name, () => []);
          prs[name]!.add(FlSpot(dateIdx.toDouble(), maxW));
        }
      }
      dateIdx++;
    }

    if (prs.isEmpty) {
      return Center(child: Text('لا توجد بيانات أوزان بعد', style: theme.textTheme.bodyLarge));
    }

    // Show chart for top exercise
    final topExercise = prs.entries.first;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تطور الأوزان — ${topExercise.key}', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: topExercise.value,
                    isCurved: true,
                    color: theme.colorScheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: theme.colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('أقوى تمارين', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...prs.entries.take(10).map((e) {
            final maxWeight = e.value.fold(0.0, (m, s) => s.y > m ? s.y : m);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Text('🏆', style: TextStyle(fontSize: 22)),
                title: Text(e.key, style: theme.textTheme.titleSmall),
                trailing: Text('${maxWeight.toStringAsFixed(1)} kg',
                    style: TextStyle(color: AppColors.goldColor, fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final Map<String, dynamic> logs;
  final List<dynamic> measurements;
  final ThemeData theme;
  final AppLocalizations l10n;
  const _StatsTab({required this.logs, required this.measurements, required this.theme, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final totalSessions = logs.length;
    int totalSets = 0;
    double totalVolume = 0;
    for (final log in logs.values) {
      if (log is! Map) continue;
      for (final ex in (log['exercises'] as List<dynamic>? ?? [])) {
        if (ex is! Map) continue;
        for (final s in (ex['sets'] as List<dynamic>? ?? [])) {
          if (s is! Map) continue;
          totalSets++;
          totalVolume += (double.tryParse(s['weight']?.toString() ?? '') ?? 0) *
              (int.tryParse(s['reps']?.toString() ?? '') ?? 0);
        }
      }
    }

    final latestWeight = measurements.isNotEmpty
        ? (measurements.first as Map<String, dynamic>)['weight'] : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _StatCard('جلسات', '$totalSessions', Icons.fitness_center, AppColors.accent)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard('مجاميع', '$totalSets', Icons.repeat, AppColors.primaryGreen)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _StatCard('حجم إجمالي', '${(totalVolume / 1000).toStringAsFixed(1)}T', Icons.bar_chart, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard('آخر وزن', latestWeight != null ? '$latestWeight kg' : '-', Icons.monitor_weight, Colors.purple)),
          ]),
          const SizedBox(height: 24),
          Text('التقدم الأسبوعي', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            Card(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('لا توجد بيانات كافية', style: theme.textTheme.bodyMedium)),
            ))
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 180,
                  child: BarChart(BarChartData(
                    barGroups: _buildWeeklyBars(logs),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                  )),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildWeeklyBars(Map<String, dynamic> logs) {
    final weekCounts = <int, int>{};
    for (final key in logs.keys) {
      try {
        final d = DateTime.parse(key);
        final weekOfYear = (d.difference(DateTime(d.year, 1, 1)).inDays / 7).floor();
        weekCounts[weekOfYear] = (weekCounts[weekOfYear] ?? 0) + 1;
      } catch (_) {}
    }
    final sorted = weekCounts.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return sorted.take(8).toList().asMap().entries.map((e) => BarChartGroupData(
      x: e.key,
      barRods: [BarChartRodData(toY: e.value.value.toDouble(), color: AppColors.accent, width: 16, borderRadius: BorderRadius.circular(4))],
    )).toList();
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: color)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
