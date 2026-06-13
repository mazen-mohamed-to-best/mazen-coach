import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/local_db_service.dart';
import '../../../services/sync_service.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});
  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _displayMonth = DateTime.now();
  Map<int, String> _currentMonth = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  String get _monthKey =>
      '${_displayMonth.year}-${_displayMonth.month.toString().padLeft(2, '0')}';

  Future<void> _loadAttendance() async {
    setState(() => _loading = true);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final data = await LocalDbService.instance.getAttendance(user.uid, _monthKey);
    if (mounted) {
      setState(() {
        _currentMonth = data != null
            ? {for (final e in data.entries) int.tryParse(e.key) ?? 0: e.value as String}
            : {};
        _loading = false;
      });
    }
  }

  Future<void> _markDay(int day, String mark) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _currentMonth[day] = mark);
    final dataToSave = {for (final e in _currentMonth.entries) e.key.toString(): e.value};
    await SyncService.instance.enqueueAttendance(user.uid, _monthKey, dataToSave);
  }

  void _showMarkDialog(int day) {
    final l10n = context.l10n;
    final current = _currentMonth[day];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('يوم $day — تسجيل الحضور', style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MarkButton('✔ حضور', AppColors.gymColor, AppConstants.attGym, current,
                    () { _markDay(day, AppConstants.attGym); Navigator.pop(ctx); }),
                _MarkButton('✘ غياب', AppColors.absentColor, AppConstants.attAbsent, current,
                    () { _markDay(day, AppConstants.attAbsent); Navigator.pop(ctx); }),
                _MarkButton('🛌 راحة', AppColors.restColor, AppConstants.attRest, current,
                    () { _markDay(day, AppConstants.attRest); Navigator.pop(ctx); }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final daysInMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_displayMonth.year, _displayMonth.month, 1).weekday % 7;

    final gymCount = _currentMonth.values.where((v) => v == AppConstants.attGym).length;
    final absentCount = _currentMonth.values.where((v) => v == AppConstants.attAbsent).length;
    final restCount = _currentMonth.values.where((v) => v == AppConstants.attRest).length;
    final commitRate = (gymCount + absentCount) > 0
        ? gymCount / (gymCount + absentCount) * 100 : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.attendance),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() => _displayMonth = DateTime.now());
              _loadAttendance();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month nav
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () {
                    setState(() => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month - 1));
                    _loadAttendance();
                  },
                ),
                Text(
                  '${_monthName(_displayMonth.month)} ${_displayMonth.year}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    setState(() => _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + 1));
                    _loadAttendance();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Stats
            Row(
              children: [
                Expanded(child: _StatBadge(gymCount.toString(), 'حضور', AppColors.gymColor)),
                const SizedBox(width: 8),
                Expanded(child: _StatBadge(absentCount.toString(), 'غياب', AppColors.absentColor)),
                const SizedBox(width: 8),
                Expanded(child: _StatBadge(restCount.toString(), 'راحة', AppColors.restColor)),
                const SizedBox(width: 8),
                Expanded(child: _StatBadge('${commitRate.toStringAsFixed(0)}%', 'الإلتزام', theme.colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 16),

            // Calendar grid
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Day headers
                    Row(
                      children: ['أح', 'إث', 'ثل', 'أر', 'خم', 'جم', 'سب']
                          .map((d) => Expanded(child: Center(child: Text(d,
                              style: theme.textTheme.labelSmall))))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    // Calendar days
                    if (_loading) const Center(child: CircularProgressIndicator())
                    else _buildCalendarGrid(firstWeekday, daysInMonth, theme),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Today's mark
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showMarkDialog(DateTime.now().day),
                icon: const Icon(Icons.edit_calendar),
                label: Text(l10n.markToday),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(int firstWeekday, int daysInMonth, ThemeData theme) {
    final cells = <Widget>[];
    // Empty cells before first day
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }
    // Day cells
    for (int day = 1; day <= daysInMonth; day++) {
      final mark = _currentMonth[day];
      final isToday = DateTime.now().day == day &&
          DateTime.now().month == _displayMonth.month &&
          DateTime.now().year == _displayMonth.year;
      cells.add(_DayCell(
        day: day,
        mark: mark,
        isToday: isToday,
        theme: theme,
        onTap: () => _showMarkDialog(day),
      ));
    }
    // Pad to 7 columns
    while (cells.length % 7 != 0) cells.add(const SizedBox());

    final rows = <Widget>[];
    for (int i = 0; i < cells.length; i += 7) {
      rows.add(Row(children: cells.sublist(i, i + 7).map((c) => Expanded(child: c)).toList()));
      rows.add(const SizedBox(height: 4));
    }
    return Column(children: rows);
  }

  String _monthName(int m) {
    const names = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return names[m - 1];
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final String? mark;
  final bool isToday;
  final ThemeData theme;
  final VoidCallback onTap;

  const _DayCell({required this.day, required this.mark, required this.isToday, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color? bgColor;
    String? emoji;
    if (mark == AppConstants.attGym) { bgColor = AppColors.gymColor; emoji = '✔'; }
    else if (mark == AppConstants.attAbsent) { bgColor = AppColors.absentColor; emoji = '✘'; }
    else if (mark == AppConstants.attRest) { bgColor = AppColors.restColor.withOpacity(0.5); emoji = '🛌'; }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        height: 42,
        decoration: BoxDecoration(
          color: bgColor?.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: isToday ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (emoji != null)
              Text(emoji, style: const TextStyle(fontSize: 12))
            else
              Text('$day', style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: isToday ? FontWeight.w700 : null,
                color: isToday ? theme.colorScheme.primary : null,
              )),
            if (emoji == null)
              const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBadge(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 18)),
            Text(label, style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MarkButton extends StatelessWidget {
  final String label;
  final Color color;
  final String mark;
  final String? current;
  final VoidCallback onTap;
  const _MarkButton(this.label, this.color, this.mark, this.current, this.onTap);

  @override
  Widget build(BuildContext context) {
    final isSelected = current == mark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: isSelected ? 2 : 1),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : color, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
