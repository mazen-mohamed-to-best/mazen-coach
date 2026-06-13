import 'package:equatable/equatable.dart';

class ExerciseDefinition extends Equatable {
  final String name;
  final bool isPrimary;
  final String warmupSets;
  final int defaultSets;
  final String repsRange;
  final String restRange;
  final String muscle;
  final String alt1;
  final String alt2;
  final String note;
  final String? videoUrl;

  const ExerciseDefinition({
    required this.name,
    this.isPrimary = false,
    this.warmupSets = '0',
    this.defaultSets = 2,
    this.repsRange = '6~10',
    this.restRange = '2~3',
    this.muscle = '',
    this.alt1 = '',
    this.alt2 = '',
    this.note = '',
    this.videoUrl,
  });

  factory ExerciseDefinition.fromJson(Map<String, dynamic> json) => ExerciseDefinition(
    name: json['name']?.toString() ?? '',
    isPrimary: json['primary'] == true,
    warmupSets: json['wu']?.toString() ?? '0',
    defaultSets: _parseInt(json['sets']) ?? 2,
    repsRange: json['reps']?.toString() ?? '6~10',
    restRange: json['rest']?.toString() ?? '2~3',
    muscle: json['muscle']?.toString() ?? '',
    alt1: json['alt1']?.toString() ?? '',
    alt2: json['alt2']?.toString() ?? '',
    note: json['note']?.toString() ?? '',
    videoUrl: json['videoUrl']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'primary': isPrimary,
    'wu': warmupSets,
    'sets': defaultSets,
    'reps': repsRange,
    'rest': restRange,
    'muscle': muscle,
    'alt1': alt1,
    'alt2': alt2,
    'note': note,
    if (videoUrl != null) 'videoUrl': videoUrl,
  };

  int get minReps => _parseInt(repsRange.split('~').first) ?? 6;
  int get maxReps => _parseInt(repsRange.split('~').last) ?? 10;

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  @override
  List<Object?> get props => [name, muscle];
}

class CustomExercise extends Equatable {
  final String name;
  final String muscle;
  final String? note;
  final String? videoUrl;

  const CustomExercise({
    required this.name,
    required this.muscle,
    this.note,
    this.videoUrl,
  });

  factory CustomExercise.fromJson(Map<String, dynamic> json) => CustomExercise(
    name: json['name']?.toString() ?? '',
    muscle: json['muscle']?.toString() ?? '',
    note: json['note']?.toString(),
    videoUrl: json['videoUrl']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'muscle': muscle,
    if (note != null) 'note': note,
    if (videoUrl != null) 'videoUrl': videoUrl,
  };

  @override
  List<Object?> get props => [name];
}
