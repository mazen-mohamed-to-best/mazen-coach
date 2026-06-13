import 'package:equatable/equatable.dart';

class SubscriptionRequest extends Equatable {
  final String id;
  final String uid;
  final String subscriptionType;
  final int subscriptionDuration;
  final double amount;
  final String transferPhone;
  final String status;
  final String? imageUrl;
  final String? name;
  final String? email;
  final String createdAt;
  final String? notes;

  const SubscriptionRequest({
    required this.id,
    required this.uid,
    required this.subscriptionType,
    required this.subscriptionDuration,
    required this.amount,
    required this.transferPhone,
    required this.status,
    this.imageUrl,
    this.name,
    this.email,
    required this.createdAt,
    this.notes,
  });

  factory SubscriptionRequest.fromJson(Map<String, dynamic> json) => SubscriptionRequest(
    id: json['id']?.toString() ?? '',
    uid: json['uid']?.toString() ?? '',
    subscriptionType: json['subscriptionType']?.toString() ?? 'light',
    subscriptionDuration: _parseInt(json['subscriptionDuration']) ?? 1,
    amount: _parseDouble(json['amount']) ?? 0,
    transferPhone: json['transferPhone']?.toString() ?? '',
    status: json['status']?.toString() ?? 'pending',
    imageUrl: json['imageUrl']?.toString(),
    name: json['name']?.toString(),
    email: json['email']?.toString(),
    createdAt: json['createdAt']?.toString() ?? '',
    notes: json['notes']?.toString(),
  );

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  @override
  List<Object?> get props => [id, status];
}

class SubscriptionPlan extends Equatable {
  final String id;
  final String name;
  final String description;
  final double priceMultiplier;
  final Map<String, bool> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.priceMultiplier,
    required this.features,
  });

  @override
  List<Object?> get props => [id];
}

class SubscriptionConfig extends Equatable {
  final String walletNumber;
  final double basePrice;
  final Map<String, SubscriptionPlan> plans;

  const SubscriptionConfig({
    required this.walletNumber,
    required this.basePrice,
    required this.plans,
  });

  static SubscriptionConfig get defaults => const SubscriptionConfig(
    walletNumber: '',
    basePrice: 100,
    plans: {
      'light': SubscriptionPlan(
        id: 'light',
        name: 'اشتراك خفيف',
        description: 'تدريب + حضور + شات عام',
        priceMultiplier: 1,
        features: {
          'workout': true,
          'nutrition': false,
          'attendance': true,
          'progress': false,
          'chat_general': true,
          'chat_coach': false,
          'ai_chat': false,
        },
      ),
      'full': SubscriptionPlan(
        id: 'full',
        name: 'اشتراك كامل',
        description: 'جميع الميزات بدون قيود',
        priceMultiplier: 2,
        features: {
          'workout': true,
          'nutrition': true,
          'attendance': true,
          'progress': true,
          'chat_general': true,
          'chat_coach': true,
          'ai_chat': true,
        },
      ),
    },
  );

  @override
  List<Object?> get props => [walletNumber, basePrice];
}

class PromoCode extends Equatable {
  final String code;
  final double discount;
  final int maxUses;
  final int uses;
  final bool active;
  final String createdAt;

  const PromoCode({
    required this.code,
    required this.discount,
    required this.maxUses,
    required this.uses,
    required this.active,
    required this.createdAt,
  });

  factory PromoCode.fromJson(Map<String, dynamic> json) => PromoCode(
    code: json['code']?.toString() ?? '',
    discount: _parseDouble(json['discount']) ?? 0,
    maxUses: _parseInt(json['maxUses']) ?? 0,
    uses: _parseInt(json['uses']) ?? 0,
    active: json['active'] == true || json['active'] == 'TRUE',
    createdAt: json['createdAt']?.toString() ?? '',
  );

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  @override
  List<Object?> get props => [code];
}

class GuestCode extends Equatable {
  final String code;
  final bool used;
  final String? usedAt;
  final String createdAt;

  const GuestCode({
    required this.code,
    required this.used,
    this.usedAt,
    required this.createdAt,
  });

  factory GuestCode.fromJson(Map<String, dynamic> json) => GuestCode(
    code: json['code']?.toString() ?? '',
    used: json['used'] == true || json['used'] == 'TRUE',
    usedAt: json['usedAt']?.toString(),
    createdAt: json['createdAt']?.toString() ?? '',
  );

  @override
  List<Object?> get props => [code];
}
