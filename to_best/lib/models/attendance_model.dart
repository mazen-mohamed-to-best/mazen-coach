import 'package:equatable/equatable.dart';
import '../core/constants/app_constants.dart';

class AttendanceModel extends Equatable {
  final String month;
  final Map<int, String> days;

  const AttendanceModel({
    required this.month,
    required this.days,
  });

  factory AttendanceModel.fromJson(String month, Map<String, dynamic> json) {
    final days = <int, String>{};
    json.forEach((k, v) {
      final day = int.tryParse(k);
      if (day != null) days[day] = v.toString();
    });
    return AttendanceModel(month: month, days: days);
  }

  Map<String, dynamic> toJson() {
    return {for (final e in days.entries) e.key.toString(): e.value};
  }

  AttendanceModel setDay(int day, String mark) {
    final newDays = Map<int, String>.from(days);
    newDays[day] = mark;
    return AttendanceModel(month: month, days: newDays);
  }

  int get gymCount => days.values.where((v) => v == AppConstants.attGym).length;
  int get absentCount => days.values.where((v) => v == AppConstants.attAbsent).length;
  int get restCount => days.values.where((v) => v == AppConstants.attRest).length;
  int get totalMarked => days.length;

  double get commitmentRate {
    if (gymCount + absentCount == 0) return 0;
    return gymCount / (gymCount + absentCount) * 100;
  }

  @override
  List<Object?> get props => [month, days];
}

class MeasurementEntry extends Equatable {
  final String date;
  final double weight;
  final double? bodyFat;
  final double? chest;
  final double? waist;
  final double? hips;
  final double? leftArm;
  final double? rightArm;
  final double? leftThigh;
  final double? rightThigh;
  final String? note;

  const MeasurementEntry({
    required this.date,
    required this.weight,
    this.bodyFat,
    this.chest,
    this.waist,
    this.hips,
    this.leftArm,
    this.rightArm,
    this.leftThigh,
    this.rightThigh,
    this.note,
  });

  factory MeasurementEntry.fromJson(Map<String, dynamic> json) => MeasurementEntry(
    date: json['date']?.toString() ?? '',
    weight: _parseDouble(json['weight']) ?? 0,
    bodyFat: _parseDouble(json['bodyFat']),
    chest: _parseDouble(json['chest']),
    waist: _parseDouble(json['waist']),
    hips: _parseDouble(json['hips']),
    leftArm: _parseDouble(json['leftArm']),
    rightArm: _parseDouble(json['rightArm']),
    leftThigh: _parseDouble(json['leftThigh']),
    rightThigh: _parseDouble(json['rightThigh']),
    note: json['note']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'date': date,
    'weight': weight,
    if (bodyFat != null) 'bodyFat': bodyFat,
    if (chest != null) 'chest': chest,
    if (waist != null) 'waist': waist,
    if (hips != null) 'hips': hips,
    if (leftArm != null) 'leftArm': leftArm,
    if (rightArm != null) 'rightArm': rightArm,
    if (leftThigh != null) 'leftThigh': leftThigh,
    if (rightThigh != null) 'rightThigh': rightThigh,
    if (note != null) 'note': note,
  };

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  @override
  List<Object?> get props => [date, weight];
}
