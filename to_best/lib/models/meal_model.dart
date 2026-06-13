import 'package:equatable/equatable.dart';

class FoodItem extends Equatable {
  final String name;
  final double amount;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final String mealType;
  final DateTime? loggedAt;

  const FoodItem({
    required this.name,
    required this.amount,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.mealType = 'snack',
    this.loggedAt,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
    name: json['name']?.toString() ?? '',
    amount: _parseDouble(json['amount']) ?? 100,
    calories: _parseDouble(json['calories']) ?? 0,
    protein: _parseDouble(json['protein']) ?? 0,
    carbs: _parseDouble(json['carbs']) ?? 0,
    fat: _parseDouble(json['fat']) ?? 0,
    fiber: _parseDouble(json['fiber']) ?? 0,
    mealType: json['mealType']?.toString() ?? 'snack',
    loggedAt: json['loggedAt'] != null ? DateTime.tryParse(json['loggedAt'].toString()) : null,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
    'mealType': mealType,
    'loggedAt': loggedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
  };

  FoodItem copyWith({double? amount}) {
    if (amount == null) return this;
    final factor = amount / this.amount;
    return FoodItem(
      name: name,
      amount: amount,
      calories: calories * factor,
      protein: protein * factor,
      carbs: carbs * factor,
      fat: fat * factor,
      fiber: fiber * factor,
      mealType: mealType,
      loggedAt: loggedAt,
    );
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  @override
  List<Object?> get props => [name, amount, mealType];
}

class DailyMeals extends Equatable {
  final String date;
  final List<FoodItem> items;
  final double waterMl;

  const DailyMeals({
    required this.date,
    required this.items,
    this.waterMl = 0,
  });

  factory DailyMeals.fromJson(String date, Map<String, dynamic> json) {
    return DailyMeals(
      date: date,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => FoodItem.fromJson(Map<String, dynamic>.from(i)))
          .toList(),
      waterMl: _parseDouble(json['waterMl']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((i) => i.toJson()).toList(),
    'waterMl': waterMl,
  };

  double get totalCalories => items.fold(0.0, (s, i) => s + i.calories);
  double get totalProtein => items.fold(0.0, (s, i) => s + i.protein);
  double get totalCarbs => items.fold(0.0, (s, i) => s + i.carbs);
  double get totalFat => items.fold(0.0, (s, i) => s + i.fat);
  double get totalFiber => items.fold(0.0, (s, i) => s + i.fiber);

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  @override
  List<Object?> get props => [date];
}

class MealPlanItem extends Equatable {
  final String name;
  final String time;
  final List<FoodItem> foods;
  final String? note;

  const MealPlanItem({
    required this.name,
    required this.time,
    required this.foods,
    this.note,
  });

  factory MealPlanItem.fromJson(Map<String, dynamic> json) => MealPlanItem(
    name: json['name']?.toString() ?? '',
    time: json['time']?.toString() ?? '',
    foods: (json['foods'] as List<dynamic>? ?? [])
        .map((f) => FoodItem.fromJson(Map<String, dynamic>.from(f)))
        .toList(),
    note: json['note']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'time': time,
    'foods': foods.map((f) => f.toJson()).toList(),
    if (note != null) 'note': note,
  };

  @override
  List<Object?> get props => [name, time];
}
