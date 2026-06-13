import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/constants/app_constants.dart';
import 'api_service.dart';
import 'local_db_service.dart';

enum SyncStatus { idle, syncing, ok, error, offline }

typedef SyncStatusCallback = void Function(SyncStatus status);

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  Timer? _cycleTimer;
  Timer? _sheetTimer;
  Timer? _debounceTimer;
  SyncStatusCallback? _onStatusChange;
  SyncStatus _currentStatus = SyncStatus.idle;
  int _lastPullTs = 0;
  String? _currentUid;
  bool _isOnline = true;

  StreamSubscription<List<ConnectivityResult>>? _connectSub;

  SyncStatus get status => _currentStatus;

  void setStatusCallback(SyncStatusCallback cb) => _onStatusChange = cb;

  void _setStatus(SyncStatus s) {
    _currentStatus = s;
    _onStatusChange?.call(s);
  }

  // ── Start background sync ────────────────────────────────────

  void start(String uid) {
    stop();
    _currentUid = uid;

    // Watch connectivity
    _connectSub = Connectivity().onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      if (!wasOnline && _isOnline) {
        _setStatus(SyncStatus.syncing);
        _cycle(uid);
      } else if (!_isOnline) {
        _setStatus(SyncStatus.offline);
      }
    });

    // Immediate initial sync after 2s
    Timer(const Duration(seconds: 2), () => _cycle(uid));

    // Periodic cycle every 30s
    _cycleTimer = Timer.periodic(
      Duration(milliseconds: AppConstants.syncCycleMs),
      (_) => _cycle(uid),
    );

    // User sheet push every 5min
    _sheetTimer = Timer.periodic(
      Duration(milliseconds: AppConstants.sheetSyncFreqMs),
      (_) => _pushUserSheet(uid),
    );
  }

  void stop() {
    _cycleTimer?.cancel();
    _sheetTimer?.cancel();
    _debounceTimer?.cancel();
    _connectSub?.cancel();
    _cycleTimer = null;
    _sheetTimer = null;
    _debounceTimer = null;
    _connectSub = null;
    _currentUid = null;
  }

  // Called on every data change — debounced push
  void onChange() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      Duration(milliseconds: AppConstants.debounceMs),
      () async {
        if (!_isOnline || !ApiService.instance.isConfigured) return;
        _setStatus(SyncStatus.syncing);
        final failed = await _flushQueue();
        _setStatus(failed > 0 ? SyncStatus.error : SyncStatus.ok);
      },
    );
  }

  // ── Full restore on login ────────────────────────────────────

  Future<bool> restoreOnLogin(String uid) async {
    if (!ApiService.instance.isConfigured) return false;
    final connectivity = await Connectivity().checkConnectivity();
    _isOnline = connectivity.any((r) => r != ConnectivityResult.none);
    if (!_isOnline) {
      _setStatus(SyncStatus.offline);
      return false;
    }
    _lastPullTs = 0; // force pull
    _setStatus(SyncStatus.syncing);
    final ok = await fullPull(uid);
    if (ok) await _pushUserSheet(uid);
    return ok;
  }

  // ── Full pull: cloud → local ─────────────────────────────────

  Future<bool> fullPull(String uid) async {
    if (!ApiService.instance.isConfigured || !_isOnline) {
      _setStatus(SyncStatus.offline);
      return false;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPullTs < AppConstants.pullCooldownMs) return false;
    _lastPullTs = now;
    _setStatus(SyncStatus.syncing);

    try {
      final result = await ApiService.instance.fetchFullData(uid);
      if (result == null || result['ok'] != true) {
        _setStatus(SyncStatus.error);
        return false;
      }
      await _seedFromCloud(uid, result['data'] as Map<String, dynamic>? ?? {});
      _setStatus(SyncStatus.ok);
      return true;
    } catch (_) {
      _setStatus(SyncStatus.error);
      return false;
    }
  }

  Future<void> _seedFromCloud(String uid, Map<String, dynamic> data) async {
    final db = LocalDbService.instance;

    // Profile → kv
    if (data['profile'] != null) {
      await db.kvSet('profile_$uid', data['profile']);
    }

    // Workout logs
    if (data['logs'] is Map) {
      await db.seedWorkoutLogs(uid, Map<String, dynamic>.from(data['logs']));
    }

    // Attendance
    if (data['att'] is Map) {
      await db.seedAttendance(uid, Map<String, dynamic>.from(data['att']));
    }

    // Meals
    if (data['meals'] is Map) {
      await db.seedMeals(uid, Map<String, dynamic>.from(data['meals']));
    }

    // Meal plan
    if (data['mealPlan'] != null) {
      await db.kvSet('meal_plan_$uid', data['mealPlan']);
    }

    // Measurements
    if (data['meas'] is List) {
      await db.saveMeasurements(uid, data['meas'] as List);
    }

    // Settings
    if (data['settings'] is Map) {
      await db.kvSet('settings_$uid', data['settings']);
    }

    // Custom exercises
    if (data['customExercises'] != null) {
      await db.kvSet('custom_exercises_$uid', data['customExercises']);
    }

    // Exercise swaps
    if (data['exerciseSwaps'] != null) {
      await db.kvSet('exercise_swaps_$uid', data['exerciseSwaps']);
    }
  }

  // ── Push queue: local → cloud ────────────────────────────────

  Future<int> _flushQueue() async {
    final db = LocalDbService.instance;
    final queue = await db.getQueue();
    int failed = 0;

    for (final item in queue) {
      try {
        final result = await _executeQueueItem(item);
        if (result == true) {
          await db.dequeue(item['id'] as String);
        } else {
          await db.incrementRetry(item['id'] as String);
          failed++;
        }
      } catch (_) {
        await db.incrementRetry(item['id'] as String);
        failed++;
      }
    }

    return failed;
  }

  Future<bool> _executeQueueItem(Map<String, dynamic> item) async {
    final action = item['action'] as String;
    final key = item['key'] as String;
    final data = item['data'] as Map<String, dynamic>;

    switch (action) {
      case 'SAVE_ROW':
        final parts = key.split('::');
        if (parts.length == 2) {
          final result = await ApiService.instance.saveRow(parts[0], parts[1], data);
          return result?['ok'] == true;
        }
        return false;

      case 'UPSERT_USER':
        final result = await ApiService.instance.upsertUser(key, data);
        return result?['ok'] == true;

      case 'SAVE_SETTING':
        final result = await ApiService.instance.saveSetting(
          data['uid'] as String,
          data['key'] as String,
          data['value'],
        );
        return result?['ok'] == true;

      default:
        return false;
    }
  }

  Future<void> _pushUserSheet(String uid) async {
    if (!ApiService.instance.isConfigured || !_isOnline || uid.isEmpty) return;
    try {
      final snapshot = await _buildSnapshot(uid);
      await ApiService.instance.pushUserSheet(uid, snapshot);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _buildSnapshot(String uid) async {
    final db = LocalDbService.instance;
    return {
      'profile': await db.kvGet('profile_$uid') ?? {},
      'logs': await db.getAllWorkoutLogs(uid),
      'att': await db.getAllAttendance(uid),
      'meals': {},
      'mealPlan': await db.kvGet('meal_plan_$uid'),
      'meas': await db.getMeasurements(uid),
      'settings': await db.kvGet('settings_$uid') ?? {},
    };
  }

  Future<void> _cycle(String uid) async {
    await _flushQueue();
    await fullPull(uid);
  }

  // ── Enqueue operations ───────────────────────────────────────

  Future<void> enqueueWorkoutLog(String uid, String date, Map<String, dynamic> data) async {
    await LocalDbService.instance.saveWorkoutLog(uid, date, data);
    await LocalDbService.instance.enqueue('SAVE_ROW', 'WorkoutLogs::${uid}_$date', data);
    onChange();
  }

  Future<void> enqueueAttendance(String uid, String month, Map<String, dynamic> data) async {
    await LocalDbService.instance.saveAttendance(uid, month, data);
    await LocalDbService.instance.enqueue('SAVE_ROW', 'Attendance::${uid}_$month', data);
    onChange();
  }

  Future<void> enqueueMeals(String uid, String date, Map<String, dynamic> data) async {
    await LocalDbService.instance.saveMeals(uid, date, data);
    await LocalDbService.instance.enqueue('SAVE_ROW', 'Meals::${uid}_$date', data);
    onChange();
  }

  Future<void> enqueueMeasurements(String uid, List<dynamic> data) async {
    await LocalDbService.instance.saveMeasurements(uid, data);
    await LocalDbService.instance.enqueue('SAVE_ROW', 'Measurements::$uid', {'measurements': data});
    onChange();
  }

  Future<void> enqueueUserUpdate(String uid, Map<String, dynamic> data) async {
    await LocalDbService.instance.kvSet('profile_$uid', data);
    await LocalDbService.instance.enqueue('UPSERT_USER', uid, data);
    onChange();
  }

  Future<void> enqueueSetting(String uid, String key, dynamic value) async {
    final settings = await LocalDbService.instance.kvGet<Map>('settings_$uid') ?? {};
    settings[key] = value;
    await LocalDbService.instance.kvSet('settings_$uid', settings);
    await LocalDbService.instance.enqueue('SAVE_SETTING', 'setting_${uid}_$key', {
      'uid': uid,
      'key': key,
      'value': value,
    });
    onChange();
  }

  Future<int> pendingCount() => LocalDbService.instance.queueLength();
}
