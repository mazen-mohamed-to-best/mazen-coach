import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/exercise_data.dart';
import '../../../models/workout_log_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/sync_service.dart';

class SessionScreen extends ConsumerStatefulWidget {
  final String sessionName;
  final String programId;

  const SessionScreen({super.key, required this.sessionName, required this.programId});

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends ConsumerState<SessionScreen> {
  List<Map<String, dynamic>> _exercises = [];
  // exerciseIndex → setIndex → {weight, reps, rpe}
  final Map<int, List<Map<String, dynamic>>> _sets = {};
  bool _warmupDone = false;
  int _currentExIndex = 0;
  Timer? _restTimer;
  int _restSecondsLeft = 0;
  bool _restRunning = false;
  final DateTime _startTime = DateTime.now();
  bool _saving = false;
  bool _showWarmup = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
  }

  void _loadExercises() {
    final rawList = ExerciseData.sessions[widget.sessionName];
    if (rawList != null) {
      _exercises = List<Map<String, dynamic>>.from(rawList);
    }
    // Initialize sets for each exercise
    for (int i = 0; i < _exercises.length; i++) {
      final ex = _exercises[i];
      final setCount = (ex['sets'] as int?) ?? 2;
      _sets[i] = List.generate(setCount, (_) => {'weight': 0.0, 'reps': 0, 'rpe': null});
    }
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    setState(() { _restSecondsLeft = seconds; _restRunning = true; });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restSecondsLeft <= 0) {
        timer.cancel();
        setState(() => _restRunning = false);
        return;
      }
      setState(() => _restSecondsLeft--);
    });
  }

  Future<void> _finishSession() async {
    setState(() => _saving = true);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final settings = ref.read(settingsProvider);

    final exerciseLogs = <Map<String, dynamic>>[];
    for (int i = 0; i < _exercises.length; i++) {
      final ex = _exercises[i];
      final sets = _sets[i] ?? [];
      final validSets = sets.where((s) => (s['reps'] as int? ?? 0) > 0).toList();
      if (validSets.isEmpty) continue;
      exerciseLogs.add({
        'name': ex['name'],
        'sets': validSets.map((s) => {
          'weight': s['weight'] ?? 0.0,
          'reps': s['reps'] ?? 0,
          if (s['rpe'] != null) 'rpe': s['rpe'],
        }).toList(),
      });
    }

    final duration = DateTime.now().difference(_startTime).inSeconds;
    final today = _formatDate(DateTime.now());

    final logData = {
      'sessionName': widget.sessionName,
      'programId': widget.programId,
      'exercises': exerciseLogs,
      'durationSeconds': duration,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await SyncService.instance.enqueueWorkoutLog(user.uid, today, logData);

    if (mounted) {
      setState(() => _saving = false);
      _showSessionDoneDialog();
    }
  }

  void _showSessionDoneDialog() {
    final l10n = context.l10n;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.sessionDone),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, color: AppColors.goldColor, size: 64),
            const SizedBox(height: 12),
            Text('مدة الجلسة: ${_formatDuration(DateTime.now().difference(_startTime))}'),
            Text('عدد التمارين: ${_sets.values.where((s) => s.any((set) => (set['reps'] as int? ?? 0) > 0)).length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
            child: const Text('رجوع للرئيسية'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}:${s.toString().padLeft(2, '0')}';
  }

  double _calcEpley(double weight, int reps) {
    if (reps == 1) return weight;
    return weight * (1 + reps / 30);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.sessionName, style: const TextStyle(fontSize: 16)),
            Text(_formatDuration(DateTime.now().difference(_startTime)),
                style: theme.textTheme.bodySmall),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _finishSession,
            child: _saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.finishSession, style: TextStyle(color: theme.colorScheme.primary)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Rest timer bar
          if (_restRunning)
            Container(
              color: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: _restSecondsLeft / settings.restTimerDuration,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${_restSecondsLeft}s', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () { _restTimer?.cancel(); setState(() => _restRunning = false); },
                    child: const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Warmup
                  if (_showWarmup)
                    _WarmupCard(
                      done: _warmupDone,
                      onDone: () => setState(() { _warmupDone = true; _showWarmup = false; }),
                      l10n: l10n,
                      theme: theme,
                    ),

                  // Exercises
                  ..._exercises.asMap().entries.map((entry) {
                    final i = entry.key;
                    final ex = entry.value;
                    return _ExerciseCard(
                      exerciseIndex: i,
                      exercise: ex,
                      sets: _sets[i] ?? [],
                      settings: settings,
                      l10n: l10n,
                      theme: theme,
                      onSetChanged: (setIdx, field, value) {
                        setState(() => _sets[i]![setIdx][field] = value);
                      },
                      onAddSet: () => setState(() => _sets[i]!.add({'weight': 0.0, 'reps': 0, 'rpe': null})),
                      onStartRest: (secs) => _startRestTimer(secs),
                      onCalcEpley: _calcEpley,
                    );
                  }).toList(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _finishSession,
        icon: _saving
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.check),
        label: Text(l10n.finishSession),
      ),
    );
  }
}

class _WarmupCard extends StatelessWidget {
  final bool done;
  final VoidCallback onDone;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _WarmupCard({required this.done, required this.onDone, required this.l10n, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(Icons.local_fire_department, color: Colors.orange),
        title: Text(l10n.warmupProtocol, style: theme.textTheme.titleSmall),
        children: [
          ...ExerciseData.warmup.map((w) => ListTile(
            dense: true,
            leading: const Icon(Icons.circle, size: 8),
            title: Text(w['name'] as String, style: theme.textTheme.bodyMedium),
            subtitle: Text('${w['reps']}  |  ${w['note']}', style: theme.textTheme.bodySmall),
          )).toList(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: done ? null : onDone,
                child: Text(done ? l10n.warmupDone : 'انتهيت من الإحماء ✓'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final int exerciseIndex;
  final Map<String, dynamic> exercise;
  final List<Map<String, dynamic>> sets;
  final AppSettings settings;
  final AppLocalizations l10n;
  final ThemeData theme;
  final Function(int setIdx, String field, dynamic value) onSetChanged;
  final VoidCallback onAddSet;
  final Function(int seconds) onStartRest;
  final double Function(double weight, int reps) onCalcEpley;

  const _ExerciseCard({
    required this.exerciseIndex,
    required this.exercise,
    required this.sets,
    required this.settings,
    required this.l10n,
    required this.theme,
    required this.onSetChanged,
    required this.onAddSet,
    required this.onStartRest,
    required this.onCalcEpley,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = exercise['primary'] as bool? ?? false;
    final muscle = exercise['muscle']?.toString() ?? '';
    final alt1 = exercise['alt1']?.toString() ?? '';
    final note = exercise['note']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isPrimary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('أساسي', style: const TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                if (isPrimary) const SizedBox(width: 6),
                Expanded(
                  child: Text(exercise['name'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                ),
                if (alt1.isNotEmpty)
                  TextButton(
                    onPressed: () => _showAlternative(context),
                    child: Text(l10n.alt, style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
            Row(
              children: [
                Text(muscle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                const SizedBox(width: 12),
                Text('${exercise['sets']} × ${exercise['reps']}', style: theme.textTheme.bodySmall),
                const SizedBox(width: 12),
                const Icon(Icons.timer_outlined, size: 12),
                Text(' ${exercise['rest']} min', style: theme.textTheme.bodySmall),
              ],
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('💡 $note', style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Sets table header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  SizedBox(width: 30, child: Text('#', style: theme.textTheme.labelSmall, textAlign: TextAlign.center)),
                  Expanded(child: Text('${l10n.weight} (kg)', style: theme.textTheme.labelSmall, textAlign: TextAlign.center)),
                  Expanded(child: Text(l10n.reps, style: theme.textTheme.labelSmall, textAlign: TextAlign.center)),
                  if (settings.showRpe)
                    SizedBox(width: 60, child: Text(l10n.rpe, style: theme.textTheme.labelSmall, textAlign: TextAlign.center)),
                  SizedBox(width: 36, child: Text(l10n.rest, style: theme.textTheme.labelSmall, textAlign: TextAlign.center)),
                ],
              ),
            ),

            ...sets.asMap().entries.map((e) {
              final setIdx = e.key;
              final set = e.value;
              final w = (set['weight'] as num?)?.toDouble() ?? 0.0;
              final r = (set['reps'] as int?) ?? 0;
              return _SetRow(
                setIdx: setIdx,
                weight: w,
                reps: r,
                rpe: set['rpe'] as double?,
                showRpe: settings.showRpe,
                showEpley: settings.showEpley,
                theme: theme,
                onChanged: (field, val) => onSetChanged(setIdx, field, val),
                onStartRest: () {
                  final restRange = exercise['rest']?.toString() ?? '2~3';
                  final restMins = int.tryParse(restRange.split('~').first) ?? 2;
                  onStartRest(restMins * 60);
                },
                epley: r > 0 && w > 0 ? onCalcEpley(w, r) : null,
              );
            }).toList(),

            // Add set button
            TextButton.icon(
              onPressed: onAddSet,
              icon: const Icon(Icons.add, size: 16),
              label: Text('إضافة مجموعة', style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAlternative(BuildContext context) {
    final alt1 = exercise['alt1']?.toString() ?? '';
    final alt2 = exercise['alt2']?.toString() ?? '';
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('البدائل', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (alt1.isNotEmpty) ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(alt1),
            ),
            if (alt2.isNotEmpty) ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(alt2),
            ),
            if (alt1.isEmpty && alt2.isEmpty)
              const Text('لا توجد بدائل لهذا التمرين'),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends StatefulWidget {
  final int setIdx;
  final double weight;
  final int reps;
  final double? rpe;
  final bool showRpe;
  final bool showEpley;
  final ThemeData theme;
  final Function(String field, dynamic val) onChanged;
  final VoidCallback onStartRest;
  final double? epley;

  const _SetRow({
    required this.setIdx,
    required this.weight,
    required this.reps,
    required this.rpe,
    required this.showRpe,
    required this.showEpley,
    required this.theme,
    required this.onChanged,
    required this.onStartRest,
    required this.epley,
  });

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late TextEditingController _weightCtrl;
  late TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    _weightCtrl = TextEditingController(text: widget.weight > 0 ? widget.weight.toString() : '');
    _repsCtrl = TextEditingController(text: widget.reps > 0 ? widget.reps.toString() : '');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('${widget.setIdx + 1}',
                style: widget.theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: widget.theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                ),
                onChanged: (v) => widget.onChanged('weight', double.tryParse(v) ?? 0.0),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _repsCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: widget.theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                ),
                onChanged: (v) => widget.onChanged('reps', int.tryParse(v) ?? 0),
              ),
            ),
          ),
          if (widget.showRpe)
            SizedBox(
              width: 60,
              child: DropdownButton<double>(
                value: widget.rpe,
                isDense: true,
                underline: const SizedBox(),
                hint: const Text('RPE', style: TextStyle(fontSize: 11)),
                items: [6.0, 6.5, 7.0, 7.5, 8.0, 8.5, 9.0, 9.5, 10.0].map((v) =>
                    DropdownMenuItem(value: v, child: Text(v.toString(), style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (v) => widget.onChanged('rpe', v),
              ),
            ),
          SizedBox(
            width: 36,
            child: IconButton(
              icon: const Icon(Icons.timer_outlined, size: 18),
              onPressed: widget.onStartRest,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
