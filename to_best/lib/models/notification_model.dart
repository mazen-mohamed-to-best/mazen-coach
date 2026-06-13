import 'package:equatable/equatable.dart';

class NotificationModel extends Equatable {
  final String id;
  final String icon;
  final String title;
  final String body;
  final int ts;
  final bool read;

  const NotificationModel({
    required this.id,
    required this.icon,
    required this.title,
    required this.body,
    required this.ts,
    this.read = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id']?.toString() ?? 'n_${json['ts']}',
    icon: json['icon']?.toString() ?? '🔔',
    title: json['title']?.toString() ?? '',
    body: json['body']?.toString() ?? '',
    ts: _parseInt(json['ts']) ?? 0,
    read: json['read'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'icon': icon,
    'title': title,
    'body': body,
    'ts': ts,
    'read': read,
  };

  NotificationModel markRead() => NotificationModel(
    id: id, icon: icon, title: title, body: body, ts: ts, read: true,
  );

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  @override
  List<Object?> get props => [id, ts];
}
