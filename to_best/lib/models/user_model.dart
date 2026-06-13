import 'package:equatable/equatable.dart';
import '../core/constants/app_constants.dart';

class UserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String status;
  final String program;
  final int programDays;
  final String subscriptionType;
  final int subscriptionDuration;
  final String subscriptionStatus;
  final int? subscriptionStart;
  final int? subscriptionEnd;
  final double? dailyCalories;
  final String goal;
  final String? picture;
  final String? createdAt;
  final bool chatBanned;
  final int? chatMutedUntil;
  final String? promoCode;
  final double? discount;
  final String? forceLogoutToken;
  final Map<String, dynamic> extra;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = AppConstants.roleTrainee,
    this.status = AppConstants.statusPending,
    this.program = 'UL',
    this.programDays = 4,
    this.subscriptionType = AppConstants.subLight,
    this.subscriptionDuration = 1,
    this.subscriptionStatus = AppConstants.subNone,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.dailyCalories,
    this.goal = '',
    this.picture,
    this.createdAt,
    this.chatBanned = false,
    this.chatMutedUntil,
    this.promoCode,
    this.discount,
    this.forceLogoutToken,
    this.extra = const {},
  });

  bool get isSuperAdmin => role.toUpperCase() == AppConstants.roleSuperAdmin;
  bool get isAdmin => role.toUpperCase() == AppConstants.roleAdmin;
  bool get isCoach => role.toUpperCase() == AppConstants.roleCoach;
  bool get isAdminLike => isSuperAdmin || isAdmin || isCoach;
  bool get isTrainee => role.toUpperCase() == AppConstants.roleTrainee;

  String get subscriptionStatusEffective {
    if (isAdminLike) return 'admin';
    if (subscriptionStatus == AppConstants.subNone || subscriptionStatus.isEmpty) return 'no_subscription';
    if (subscriptionStatus == AppConstants.subPending) return 'payment_pending';
    if (subscriptionStatus == AppConstants.subActive) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final end = subscriptionEnd ?? 0;
      if (end > 0 && now > end) return 'expired';
      return 'active';
    }
    if (subscriptionStatus == AppConstants.subExpired) return 'expired';
    return 'no_subscription';
  }

  bool get isSubscriptionActive => subscriptionStatusEffective == 'active' || subscriptionStatusEffective == 'admin';

  bool featureAllowed(String featureKey) {
    if (isAdminLike) return true;
    if (!isSubscriptionActive) return false;
    final Map<String, Map<String, bool>> planFeatures = {
      AppConstants.subLight: {
        'workout': true,
        'nutrition': false,
        'attendance': true,
        'progress': false,
        'chat_general': true,
        'chat_coach': false,
        'ai_chat': false,
      },
      AppConstants.subFull: {
        'workout': true,
        'nutrition': true,
        'attendance': true,
        'progress': true,
        'chat_general': true,
        'chat_coach': true,
        'ai_chat': true,
      },
    };
    return planFeatures[subscriptionType]?[featureKey] ?? true;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? AppConstants.roleTrainee,
      status: json['status']?.toString() ?? AppConstants.statusPending,
      program: json['program']?.toString() ?? 'UL',
      programDays: _parseInt(json['programDays']) ?? 4,
      subscriptionType: json['subscriptionType']?.toString() ?? AppConstants.subLight,
      subscriptionDuration: _parseInt(json['subscriptionDuration']) ?? 1,
      subscriptionStatus: json['subscriptionStatus']?.toString() ?? AppConstants.subNone,
      subscriptionStart: _parseInt(json['subscriptionStart']),
      subscriptionEnd: _parseInt(json['subscriptionEnd']),
      dailyCalories: _parseDouble(json['dailyCalories']),
      goal: json['goal']?.toString() ?? '',
      picture: json['picture']?.toString(),
      createdAt: json['createdAt']?.toString(),
      chatBanned: json['chatBanned'] == true || json['chatBanned'] == 'true',
      chatMutedUntil: _parseInt(json['chatMutedUntil']),
      promoCode: json['promoCode']?.toString(),
      discount: _parseDouble(json['discount']),
      forceLogoutToken: json['forceLogoutToken']?.toString(),
      extra: {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'status': status,
      'program': program,
      'programDays': programDays,
      'subscriptionType': subscriptionType,
      'subscriptionDuration': subscriptionDuration,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionStart': subscriptionStart,
      'subscriptionEnd': subscriptionEnd,
      'dailyCalories': dailyCalories,
      'goal': goal,
      'picture': picture,
      'createdAt': createdAt,
      'chatBanned': chatBanned,
      'chatMutedUntil': chatMutedUntil,
      'promoCode': promoCode,
      'discount': discount,
      'forceLogoutToken': forceLogoutToken,
    };
  }

  UserModel copyWith({
    String? uid, String? name, String? email, String? phone, String? role,
    String? status, String? program, int? programDays, String? subscriptionType,
    int? subscriptionDuration, String? subscriptionStatus, int? subscriptionStart,
    int? subscriptionEnd, double? dailyCalories, String? goal, String? picture,
    String? createdAt, bool? chatBanned, int? chatMutedUntil, String? promoCode,
    double? discount, String? forceLogoutToken,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      program: program ?? this.program,
      programDays: programDays ?? this.programDays,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionDuration: subscriptionDuration ?? this.subscriptionDuration,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionStart: subscriptionStart ?? this.subscriptionStart,
      subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      goal: goal ?? this.goal,
      picture: picture ?? this.picture,
      createdAt: createdAt ?? this.createdAt,
      chatBanned: chatBanned ?? this.chatBanned,
      chatMutedUntil: chatMutedUntil ?? this.chatMutedUntil,
      promoCode: promoCode ?? this.promoCode,
      discount: discount ?? this.discount,
      forceLogoutToken: forceLogoutToken ?? this.forceLogoutToken,
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null || v == '') return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _parseDouble(dynamic v) {
    if (v == null || v == '') return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  @override
  List<Object?> get props => [uid, name, email, role, status, subscriptionStatus];
}
