import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/local_db_service.dart';
import '../../../services/sync_service.dart';
import '../../../models/meal_model.dart';
import '../../../widgets/common/stats_card.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});
  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  DailyMeals? _todayMeals;
  bool _loading = true;
  double _waterMl = 0;
  final DateTime _today = DateTime.now();

  String get _todayKey =>
      '${_today.year}-${_today.month.toString().padLeft(2, '0')}-${_today.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final data = await LocalDbService.instance.getMeals(user.uid, _todayKey);
    if (mounted) {
      setState(() {
        if (data != null) {
          _todayMeals = DailyMeals.fromJson(_todayKey, data);
          _waterMl = _todayMeals!.waterMl;
        } else {
          _todayMeals = DailyMeals(date: _todayKey, items: []);
        }
        _loading = false;
      });
    }
  }

  Future<void> _addWater(double ml) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final newWater = (_waterMl + ml).clamp(0, 10000).toDouble();
    setState(() => _waterMl = newWater);
    final meals = _todayMeals ?? DailyMeals(date: _todayKey, items: []);
    final updated = DailyMeals(date: _todayKey, items: meals.items, waterMl: newWater);
    await SyncService.instance.enqueueMeals(user.uid, _todayKey, updated.toJson());
    setState(() => _todayMeals = updated);
  }

  Future<void> _addFood(FoodItem food) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final items = [...(_todayMeals?.items ?? []), food];
    final updated = DailyMeals(date: _todayKey, items: items, waterMl: _waterMl);
    await SyncService.instance.enqueueMeals(user.uid, _todayKey, updated.toJson());
    setState(() => _todayMeals = updated);
  }

  Future<void> _removeFood(int index) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final items = List<FoodItem>.from(_todayMeals?.items ?? []);
    items.removeAt(index);
    final updated = DailyMeals(date: _todayKey, items: items, waterMl: _waterMl);
    await SyncService.instance.enqueueMeals(user.uid, _todayKey, updated.toJson());
    setState(() => _todayMeals = updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final targetCals = user?.dailyCalories ?? 2000;

    final calories = _todayMeals?.totalCalories ?? 0;
    final protein = _todayMeals?.totalProtein ?? 0;
    final carbs = _todayMeals?.totalCarbs ?? 0;
    final fat = _todayMeals?.totalFat ?? 0;
    final remaining = targetCals - calories;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.nutrition)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Calories ring card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _CalorieCircle(
                                current: calories,
                                target: targetCals,
                                color: theme.colorScheme.primary,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _CalorieStat(l10n.target, '${targetCals.toInt()} kcal', theme.colorScheme.primary),
                                  const SizedBox(height: 8),
                                  _CalorieStat(l10n.consumed, '${calories.toInt()} kcal', AppColors.warning),
                                  const SizedBox(height: 8),
                                  _CalorieStat(l10n.remaining,
                                      '${remaining.toInt()} kcal',
                                      remaining >= 0 ? AppColors.success : AppColors.error),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: MacroCard(label: l10n.protein, current: protein, target: targetCals * 0.3 / 4, color: Colors.blue)),
                              const SizedBox(width: 8),
                              Expanded(child: MacroCard(label: l10n.carbs, current: carbs, target: targetCals * 0.4 / 4, color: Colors.orange)),
                              const SizedBox(width: 8),
                              Expanded(child: MacroCard(label: l10n.fat, current: fat, target: targetCals * 0.3 / 9, color: Colors.red)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Water tracker
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.water_drop, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(l10n.waterTracker, style: theme.textTheme.titleSmall),
                              const Spacer(),
                              Text('${(_waterMl / 1000).toStringAsFixed(1)}L / 3.0L',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.blue)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (_waterMl / 3000).clamp(0.0, 1.0),
                              backgroundColor: Colors.blue.withOpacity(0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _WaterBtn('250ml', () => _addWater(250)),
                              _WaterBtn('500ml', () => _addWater(500)),
                              _WaterBtn('750ml', () => _addWater(750)),
                              _WaterBtn('1L', () => _addWater(1000)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Food logs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l10n.loggedMeals, style: theme.textTheme.titleMedium),
                      ElevatedButton.icon(
                        onPressed: () => _showAddFoodDialog(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(l10n.addFood),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_todayMeals?.items.isEmpty ?? true)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(child: Column(
                          children: [
                            const Icon(Icons.restaurant_outlined, size: 40, color: AppColors.darkSubText),
                            const SizedBox(height: 8),
                            Text(l10n.noFoodToday, style: theme.textTheme.bodyMedium),
                          ],
                        )),
                      ),
                    )
                  else
                    ..._todayMeals!.items.asMap().entries.map((e) => _FoodItemCard(
                      item: e.value,
                      index: e.key,
                      theme: theme,
                      onRemove: () => _removeFood(e.key),
                    )).toList(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  void _showAddFoodDialog(BuildContext context) {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    final protCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final fatCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '100');
    String mealType = 'snack';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.addFood, style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'اسم الطعام')),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'كمية (g)', isDense: true))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعرات', isDense: true))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: protCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'بروتين', isDense: true))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: carbCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'كارب', isDense: true))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: fatCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'دهون', isDense: true))),
              ]),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: mealType,
                isExpanded: true,
                items: [
                  DropdownMenuItem(value: 'breakfast', child: Text(l10n.breakfast)),
                  DropdownMenuItem(value: 'lunch', child: Text(l10n.lunch)),
                  DropdownMenuItem(value: 'dinner', child: Text(l10n.dinner)),
                  DropdownMenuItem(value: 'snack', child: Text(l10n.snack)),
                ],
                onChanged: (v) => setInner(() => mealType = v ?? 'snack'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isEmpty) return;
                  final food = FoodItem(
                    name: nameCtrl.text.trim(),
                    amount: double.tryParse(amountCtrl.text) ?? 100,
                    calories: double.tryParse(calCtrl.text) ?? 0,
                    protein: double.tryParse(protCtrl.text) ?? 0,
                    carbs: double.tryParse(carbCtrl.text) ?? 0,
                    fat: double.tryParse(fatCtrl.text) ?? 0,
                    mealType: mealType,
                    loggedAt: DateTime.now(),
                  );
                  Navigator.pop(ctx);
                  _addFood(food);
                },
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalorieCircle extends StatelessWidget {
  final double current;
  final double target;
  final Color color;
  const _CalorieCircle({required this.current, required this.target, required this.color});

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      width: 110, height: 110,
      child: Stack(
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${current.toInt()}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: color)),
                const Text('kcal', style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _CalorieStat(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _WaterBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _WaterBtn(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.blue,
        side: const BorderSide(color: Colors.blue),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _FoodItemCard extends StatelessWidget {
  final FoodItem item;
  final int index;
  final ThemeData theme;
  final VoidCallback onRemove;
  const _FoodItemCard({required this.item, required this.index, required this.theme, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    const mealIcons = {'breakfast': '☀️', 'lunch': '🌅', 'dinner': '🌙', 'snack': '🍎'};
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(mealIcons[item.mealType] ?? '🍽️', style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: theme.textTheme.titleSmall),
                  Text('${item.amount.toInt()}g  •  ${item.calories.toInt()} kcal',
                      style: theme.textTheme.bodySmall),
                  Text('P: ${item.protein.toInt()}g  C: ${item.carbs.toInt()}g  F: ${item.fat.toInt()}g',
                      style: theme.textTheme.labelSmall),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: onRemove),
          ],
        ),
      ),
    );
  }
}
