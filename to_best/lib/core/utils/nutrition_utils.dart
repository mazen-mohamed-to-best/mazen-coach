/// Nutrition calculation utilities

class NutritionUtils {
  NutritionUtils._();

  /// Calculate BMR using Mifflin-St Jeor
  static double calcBmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required bool isMale,
  }) {
    if (isMale) {
      return 10 * weightKg + 6.25 * heightCm - 5 * age + 5;
    } else {
      return 10 * weightKg + 6.25 * heightCm - 5 * age - 161;
    }
  }

  /// Calculate TDEE from BMR and activity factor
  static double calcTdee(double bmr, double activityFactor) => bmr * activityFactor;

  /// Activity level multipliers
  static const Map<String, double> activityFactors = {
    'sedentary': 1.2,
    'light': 1.375,
    'moderate': 1.55,
    'active': 1.725,
    'veryActive': 1.9,
  };

  /// Calculate Epley 1RM estimate
  static double calcEpley1rm(double weight, int reps) {
    if (reps == 1) return weight;
    if (reps <= 0) return 0;
    return weight * (1 + reps / 30);
  }

  /// Calculate Brzycki 1RM estimate
  static double calcBrzycki1rm(double weight, int reps) {
    if (reps == 1) return weight;
    if (reps >= 37) return weight * 0.1;
    return weight * (36 / (37 - reps));
  }

  /// Suggest next weight
  static double suggestNextWeight({
    required double currentWeight,
    required int currentReps,
    required int targetRepsMax,
    required int targetRepsMin,
  }) {
    if (currentReps >= targetRepsMax) {
      // Increase weight by 2.5kg
      return currentWeight + 2.5;
    } else if (currentReps < targetRepsMin) {
      // Decrease weight by 2.5kg
      return (currentWeight - 2.5).clamp(0, double.infinity);
    }
    return currentWeight;
  }

  /// Evaluate performance vs previous
  static String evaluatePerformance(double currentEpley, double previousEpley) {
    if (previousEpley <= 0) return 'beg';
    final diff = currentEpley - previousEpley;
    final pct = diff / previousEpley * 100;
    if (pct >= 5) return 's1';
    if (pct >= 2.5) return 's2';
    if (pct > 0) return 's3';
    if (pct == 0) return 'st';
    if (pct >= -5) return 'gd';
    if (pct >= -10) return 'ws';
    return 'dn';
  }

  /// Check if stagnant (same or lower for N weeks)
  static bool isStagnant(List<double> weeklyEpleys, int weeks) {
    if (weeklyEpleys.length < weeks) return false;
    final recent = weeklyEpleys.sublist(weeklyEpleys.length - weeks);
    final first = recent.first;
    return recent.every((v) => v <= first);
  }

  /// Format macro values
  static String formatGrams(double g) => '${g.toStringAsFixed(1)}g';
  static String formatCals(double c) => '${c.toInt()} kcal';
  static String formatKg(double kg) => '${kg.toStringAsFixed(1)} kg';
}
