import 'package:equatable/equatable.dart';

class SetEntry extends Equatable {
  final double weight;
  final int reps;
  final double? rpe;
  final bool isPr;

  const SetEntry({
    required this.weight,
    required this.reps,
    this.rpe,
    this.isPr = false,
  });

  factory SetEntry.fromJson(Map<String, dynamic> json) => SetEntry(
    weight: _parseDouble(json['weight']) ?? 0,
    reps: _parseInt(json['reps']) ?? 0,
    rpe: _parseDouble(json['rpe']),
    isPr: json['isPr'] == true,
  );

  Map<String, dynamic> toJson() => {
    'weight': weight,
    'reps': reps,
    if (rpe != null) 'rpe': rpe,
    if (isPr) 'isPr': isPr,
  };

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  @override
  List<Object?> get props => [weight, reps, rpe, isPr];
}

class ExerciseLog extends Equatable {
  final String name;
  final List<SetEntry> sets;
  final String? note;
  final double? epley1rm;
  final String? evaluation;

  const ExerciseLog({
    required this.name,
    required this.sets,
    this.note,
    this.epley1rm,
    this.evaluation,
  });

  factory ExerciseLog.fromJson(Map<String, dynamic> json) => ExerciseLog(
    name: json['name']?.toString() ?? '',
    sets: (json['sets'] as List<dynamic>? ?? [])
        .map((s) => SetEntry.fromJson(Map<String, dynamic>.from(s)))
        .toList(),
    note: json['note']?.toString(),
    epley1rm: json['epley1rm'] is num ? (json['epley1rm'] as num).toDouble() : null,
    evaluation: json['evaluation']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'sets': sets.map((s) => s.toJson()).toList(),
    if (note != null && note!.isNotEmpty) 'note': note,
    if (epley1rm != null) 'epley1rm': epley1rm,
    if (evaluation != null) 'evaluation': evaluation,
  };

  @override
  List<Object?> get props => [name, sets];
}

class WorkoutLogModel extends Equatable {
  final String date;
  final String sessionName;
  final String programId;
  final List<ExerciseLog> exercises;
  final int? durationSeconds;
  final String? notes;
  final DateTime? createdAt;

  const WorkoutLogModel({
    required this.date,
    required this.sessionName,
    required this.programId,
    required this.exercises,
    this.durationSeconds,
    this.notes,
    this.createdAt,
  });

  factory WorkoutLogModel.fromJson(String date, Map<String, dynamic> json) {
    return WorkoutLogModel(
      date: date,
      sessionName: json['sessionName']?.toString() ?? '',
      programId: json['programId']?.toString() ?? '',
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map((e) => ExerciseLog.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      durationSeconds: json['durationSeconds'] is num ? (json['durationSeconds'] as num).toInt() : null,
      notes: json['notes']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionName': sessionName,
    'programId': programId,
    'exercises': exercises.map((e) => e.toJson()).toList(),
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
  };

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);

  double get totalVolume => exercises.fold(0.0, (sum, e) =>
    sum + e.sets.fold(0.0, (s2, set) => s2 + set.weight * set.reps));

  @override
  List<Object?> get props => [date, sessionName];
}
