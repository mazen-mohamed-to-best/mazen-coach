import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String roomId;
  final String uid;
  final String senderName;
  final String? senderPicture;
  final String senderRole;
  final String text;
  final int ts;
  final bool deleted;
  final bool edited;
  final bool pinned;
  final String? replyToId;
  final String? replyToText;
  final String? replyToSender;
  final String? imageUrl;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.uid,
    required this.senderName,
    this.senderPicture,
    this.senderRole = 'TRAINEE',
    required this.text,
    required this.ts,
    this.deleted = false,
    this.edited = false,
    this.pinned = false,
    this.replyToId,
    this.replyToText,
    this.replyToSender,
    this.imageUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id']?.toString() ?? 'm_${json['ts']}',
    roomId: json['roomId']?.toString() ?? '',
    uid: json['uid']?.toString() ?? '',
    senderName: json['senderName']?.toString() ?? 'Unknown',
    senderPicture: json['senderPicture']?.toString(),
    senderRole: json['senderRole']?.toString() ?? 'TRAINEE',
    text: json['text']?.toString() ?? '',
    ts: _parseInt(json['ts']) ?? 0,
    deleted: json['deleted'] == true,
    edited: json['edited'] == true,
    pinned: json['pinned'] == true,
    replyToId: json['replyToId']?.toString(),
    replyToText: json['replyToText']?.toString(),
    replyToSender: json['replyToSender']?.toString(),
    imageUrl: json['imageUrl']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'roomId': roomId,
    'uid': uid,
    'senderName': senderName,
    if (senderPicture != null) 'senderPicture': senderPicture,
    'senderRole': senderRole,
    'text': text,
    'ts': ts,
    if (deleted) 'deleted': deleted,
    if (edited) 'edited': edited,
    if (pinned) 'pinned': pinned,
    if (replyToId != null) 'replyToId': replyToId,
    if (replyToText != null) 'replyToText': replyToText,
    if (replyToSender != null) 'replyToSender': replyToSender,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(ts);

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  @override
  List<Object?> get props => [id, ts, text, deleted, edited];
}

class ChatRoom extends Equatable {
  final String id;
  final String name;
  final String nameAr;
  final String icon;
  final bool isPrivate;
  final String? otherUid;

  const ChatRoom({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.icon,
    this.isPrivate = false,
    this.otherUid,
  });

  @override
  List<Object?> get props => [id];
}
