import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../core/constants/app_constants.dart';

/// SQLite cache — local-first cache only, never the source of truth.
class LocalDbService {
  static final LocalDbService instance = LocalDbService._();
  LocalDbService._();

  Database? _db;

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);
    _db = await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE kv (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    )''');
    await db.execute('''CREATE TABLE workout_logs (
      id TEXT PRIMARY KEY,
      uid TEXT NOT NULL,
      date TEXT NOT NULL,
      data TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    )''');
    await db.execute('''CREATE TABLE attendance (
      id TEXT PRIMARY KEY,
      uid TEXT NOT NULL,
      month TEXT NOT NULL,
      data TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    )''');
    await db.execute('''CREATE TABLE meals (
      id TEXT PRIMARY KEY,
      uid TEXT NOT NULL,
      date TEXT NOT NULL,
      data TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    )''');
    await db.execute('''CREATE TABLE sync_queue (
      id TEXT PRIMARY KEY,
      action TEXT NOT NULL,
      key_val TEXT NOT NULL,
      data TEXT NOT NULL,
      ts INTEGER NOT NULL,
      retries INTEGER NOT NULL DEFAULT 0
    )''');
    await db.execute('''CREATE TABLE chat_cache (
      id TEXT PRIMARY KEY,
      room_id TEXT NOT NULL,
      data TEXT NOT NULL,
      ts INTEGER NOT NULL
    )''');
    await db.execute('''CREATE TABLE measurements (
      id TEXT PRIMARY KEY,
      uid TEXT NOT NULL,
      data TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    )''');
    await db.execute('''CREATE TABLE notifications (
      id TEXT PRIMARY KEY,
      uid TEXT NOT NULL,
      data TEXT NOT NULL,
      ts INTEGER NOT NULL,
      read INTEGER NOT NULL DEFAULT 0
    )''');
    await db.execute('''CREATE INDEX idx_wl_uid_date ON workout_logs(uid, date)''');
    await db.execute('''CREATE INDEX idx_att_uid_month ON attendance(uid, month)''');
    await db.execute('''CREATE INDEX idx_meals_uid_date ON meals(uid, date)''');
    await db.execute('''CREATE INDEX idx_chat_room ON chat_cache(room_id, ts)''');
    await db.execute('''CREATE INDEX idx_notif_uid ON notifications(uid, ts)''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations here
  }

  Database get db => _db!;

  // ── KV Store ────────────────────────────────────────────────

  Future<void> kvSet(String key, dynamic value) async {
    await db.insert('kv', {
      'key': key,
      'value': jsonEncode(value),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<T?> kvGet<T>(String key) async {
    final rows = await db.query('kv', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    final raw = rows.first['value'] as String;
    try {
      return jsonDecode(raw) as T?;
    } catch (_) {
      return null;
    }
  }

  Future<void> kvDelete(String key) async {
    await db.delete('kv', where: 'key = ?', whereArgs: [key]);
  }

  // ── Workout Logs ────────────────────────────────────────────

  Future<void> saveWorkoutLog(String uid, String date, Map<String, dynamic> data) async {
    final id = '${uid}_$date';
    await db.insert('workout_logs', {
      'id': id, 'uid': uid, 'date': date,
      'data': jsonEncode(data),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getWorkoutLog(String uid, String date) async {
    final rows = await db.query('workout_logs',
        where: 'uid = ? AND date = ?', whereArgs: [uid, date]);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
  }

  Future<Map<String, Map<String, dynamic>>> getAllWorkoutLogs(String uid) async {
    final rows = await db.query('workout_logs',
        where: 'uid = ?', whereArgs: [uid], orderBy: 'date DESC');
    return {for (final r in rows) r['date'] as String: jsonDecode(r['data'] as String) as Map<String, dynamic>};
  }

  Future<void> seedWorkoutLogs(String uid, Map<String, dynamic> logs) async {
    final batch = db.batch();
    logs.forEach((date, data) {
      batch.insert('workout_logs', {
        'id': '${uid}_$date', 'uid': uid, 'date': date,
        'data': data is String ? data : jsonEncode(data),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
    await batch.commit(noResult: true);
  }

  // ── Attendance ──────────────────────────────────────────────

  Future<void> saveAttendance(String uid, String month, Map<String, dynamic> data) async {
    final id = '${uid}_$month';
    await db.insert('attendance', {
      'id': id, 'uid': uid, 'month': month,
      'data': jsonEncode(data),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getAttendance(String uid, String month) async {
    final rows = await db.query('attendance',
        where: 'uid = ? AND month = ?', whereArgs: [uid, month]);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
  }

  Future<Map<String, Map<String, dynamic>>> getAllAttendance(String uid) async {
    final rows = await db.query('attendance', where: 'uid = ?', whereArgs: [uid]);
    return {for (final r in rows) r['month'] as String: jsonDecode(r['data'] as String) as Map<String, dynamic>};
  }

  Future<void> seedAttendance(String uid, Map<String, dynamic> att) async {
    final batch = db.batch();
    att.forEach((month, data) {
      batch.insert('attendance', {
        'id': '${uid}_$month', 'uid': uid, 'month': month,
        'data': data is String ? data : jsonEncode(data),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
    await batch.commit(noResult: true);
  }

  // ── Meals ────────────────────────────────────────────────────

  Future<void> saveMeals(String uid, String date, Map<String, dynamic> data) async {
    final id = '${uid}_$date';
    await db.insert('meals', {
      'id': id, 'uid': uid, 'date': date,
      'data': jsonEncode(data),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getMeals(String uid, String date) async {
    final rows = await db.query('meals',
        where: 'uid = ? AND date = ?', whereArgs: [uid, date]);
    if (rows.isEmpty) return null;
    return jsonDecode(rows.first['data'] as String) as Map<String, dynamic>;
  }

  Future<void> seedMeals(String uid, Map<String, dynamic> meals) async {
    final batch = db.batch();
    meals.forEach((date, data) {
      batch.insert('meals', {
        'id': '${uid}_$date', 'uid': uid, 'date': date,
        'data': data is String ? data : jsonEncode(data),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
    await batch.commit(noResult: true);
  }

  // ── Measurements ────────────────────────────────────────────

  Future<void> saveMeasurements(String uid, List<dynamic> data) async {
    await db.insert('measurements', {
      'id': uid, 'uid': uid,
      'data': jsonEncode(data),
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<dynamic>> getMeasurements(String uid) async {
    final rows = await db.query('measurements', where: 'uid = ?', whereArgs: [uid]);
    if (rows.isEmpty) return [];
    return jsonDecode(rows.first['data'] as String) as List<dynamic>;
  }

  // ── Sync Queue ──────────────────────────────────────────────

  Future<void> enqueue(String action, String key, Map<String, dynamic> data) async {
    final id = '${DateTime.now().millisecondsSinceEpoch}_${action}_$key';
    await db.insert('sync_queue', {
      'id': id, 'action': action, 'key_val': key,
      'data': jsonEncode(data),
      'ts': DateTime.now().millisecondsSinceEpoch,
      'retries': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getQueue() async {
    final rows = await db.query('sync_queue', orderBy: 'ts ASC', limit: 50);
    return rows.map((r) => {
      'id': r['id'],
      'action': r['action'],
      'key': r['key_val'],
      'data': jsonDecode(r['data'] as String),
      'ts': r['ts'],
      'retries': r['retries'],
    }).toList();
  }

  Future<void> dequeue(String id) async {
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> incrementRetry(String id) async {
    await db.rawUpdate(
      'UPDATE sync_queue SET retries = retries + 1 WHERE id = ?', [id]);
  }

  Future<int> queueLength() async {
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM sync_queue');
    return (result.first['c'] as int?) ?? 0;
  }

  // ── Chat Cache ───────────────────────────────────────────────

  Future<void> saveChatMessage(String roomId, Map<String, dynamic> msg) async {
    final id = msg['id']?.toString() ?? 'm_${msg['ts']}';
    await db.insert('chat_cache', {
      'id': id, 'room_id': roomId,
      'data': jsonEncode(msg),
      'ts': msg['ts'] ?? 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String roomId, {int limit = 100}) async {
    final rows = await db.query('chat_cache',
        where: 'room_id = ?', whereArgs: [roomId],
        orderBy: 'ts ASC', limit: limit);
    return rows.map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>).toList();
  }

  Future<int> getLastMessageTs(String roomId) async {
    final rows = await db.query('chat_cache',
        where: 'room_id = ?', whereArgs: [roomId],
        orderBy: 'ts DESC', limit: 1);
    if (rows.isEmpty) return 0;
    return (rows.first['ts'] as int?) ?? 0;
  }

  // ── Notifications ────────────────────────────────────────────

  Future<void> saveNotification(String uid, Map<String, dynamic> notif) async {
    await db.insert('notifications', {
      'id': notif['id']?.toString() ?? 'n_${DateTime.now().millisecondsSinceEpoch}',
      'uid': uid,
      'data': jsonEncode(notif),
      'ts': notif['ts'] ?? DateTime.now().millisecondsSinceEpoch,
      'read': notif['read'] == true ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getNotifications(String uid) async {
    final rows = await db.query('notifications',
        where: 'uid = ?', whereArgs: [uid], orderBy: 'ts DESC', limit: 50);
    return rows.map((r) => jsonDecode(r['data'] as String) as Map<String, dynamic>).toList();
  }

  Future<void> markNotifRead(String id) async {
    await db.update('notifications', {'read': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> unreadCount(String uid) async {
    final result = await db.rawQuery(
        'SELECT COUNT(*) as c FROM notifications WHERE uid = ? AND read = 0', [uid]);
    return (result.first['c'] as int?) ?? 0;
  }

  // ── Utility ──────────────────────────────────────────────────

  Future<void> clearUserData(String uid) async {
    await Future.wait([
      db.delete('workout_logs', where: 'uid = ?', whereArgs: [uid]),
      db.delete('attendance', where: 'uid = ?', whereArgs: [uid]),
      db.delete('meals', where: 'uid = ?', whereArgs: [uid]),
      db.delete('measurements', where: 'uid = ?', whereArgs: [uid]),
      db.delete('notifications', where: 'uid = ?', whereArgs: [uid]),
      db.delete('sync_queue'),
    ]);
  }

  Future<void> clearAll() async {
    await Future.wait([
      db.delete('kv'),
      db.delete('workout_logs'),
      db.delete('attendance'),
      db.delete('meals'),
      db.delete('measurements'),
      db.delete('sync_queue'),
      db.delete('chat_cache'),
      db.delete('notifications'),
    ]);
  }
}
