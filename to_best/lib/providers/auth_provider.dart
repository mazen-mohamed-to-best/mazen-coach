import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';
import '../services/settings_service.dart';
import '../services/sync_service.dart';

enum AuthState { loading, unauthenticated, pending, rejected, authenticated }

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  Future<void> _init() async {
    try {
      await SettingsService.instance.init();
      await ApiService.instance.loadConfig();

      final uid = SettingsService.instance.userId;
      final userData = SettingsService.instance.userData;

      if (uid != null && userData != null) {
        try {
          final json = jsonDecode(userData) as Map<String, dynamic>;
          _currentUser = UserModel.fromJson(json);

          // Check force logout token
          final cachedToken = await LocalDbService.instance.kvGet<String>('force_logout_$uid');
          if (_currentUser!.forceLogoutToken != null &&
              cachedToken != _currentUser!.forceLogoutToken) {
            // Token changed — logout
            await _doLogout();
            return;
          }

          state = AsyncValue.data(_currentUser);
          // Start background sync
          if (ApiService.instance.isConfigured) {
            SyncService.instance.start(uid);
            // Restore from cloud in background
            SyncService.instance.restoreOnLogin(uid).then((_) => _refreshUserFromCache(uid));
          }
          return;
        } catch (_) {}
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await ApiService.instance.login(email, password);
      if (result == null) return 'connection_error';
      if (result['ok'] != true) return result['err']?.toString() ?? 'login_failed';

      final user = UserModel.fromJson(result['user'] as Map<String, dynamic>);
      await _persistUser(user);
      state = AsyncValue.data(user);

      // Restore cloud data
      if (ApiService.instance.isConfigured) {
        SyncService.instance.start(user.uid);
        SyncService.instance.restoreOnLogin(user.uid);
      }

      return null; // success
    } catch (e) {
      state = const AsyncValue.data(null);
      return 'connection_error';
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final result = await ApiService.instance.register(
        email: email, password: password, name: name, phone: phone,
      );
      if (result == null) return 'connection_error';
      if (result['ok'] != true) return result['err']?.toString() ?? 'register_failed';
      return null;
    } catch (_) {
      return 'connection_error';
    }
  }

  Future<String?> guestLogin(String code) async {
    state = const AsyncValue.loading();
    try {
      final result = await ApiService.instance.guestLogin(code);
      if (result == null) return 'connection_error';
      if (result['ok'] != true) return result['err']?.toString() ?? 'invalid_code';

      // Create a temporary guest user
      final guestUser = UserModel(
        uid: 'guest_${code.toUpperCase()}',
        name: 'Guest',
        email: 'guest@tobest.app',
        role: 'VIEWER',
        status: 'active',
        subscriptionStatus: 'active',
        subscriptionType: 'light',
      );
      await _persistUser(guestUser);
      state = AsyncValue.data(guestUser);
      return null;
    } catch (_) {
      state = const AsyncValue.data(null);
      return 'connection_error';
    }
  }

  Future<void> logout() async {
    SyncService.instance.stop();
    await _doLogout();
  }

  Future<void> _doLogout() async {
    final uid = _currentUser?.uid ?? SettingsService.instance.userId ?? '';
    await SettingsService.instance.clearUser();
    if (uid.isNotEmpty) {
      await LocalDbService.instance.clearUserData(uid);
    }
    _currentUser = null;
    state = const AsyncValue.data(null);
  }

  Future<void> _persistUser(UserModel user) async {
    _currentUser = user;
    await SettingsService.instance.setUserId(user.uid);
    await SettingsService.instance.setUserData(jsonEncode(user.toJson()));
    await LocalDbService.instance.kvSet('profile_${user.uid}', user.toJson());
    await LocalDbService.instance.kvSet('force_logout_${user.uid}', user.forceLogoutToken ?? '');
  }

  Future<void> _refreshUserFromCache(String uid) async {
    final cached = await LocalDbService.instance.kvGet<Map>('profile_$uid');
    if (cached != null) {
      final user = UserModel.fromJson(Map<String, dynamic>.from(cached));
      _currentUser = user;
      await SettingsService.instance.setUserData(jsonEncode(user.toJson()));
      state = AsyncValue.data(user);
    }
  }

  Future<void> refreshUser() async {
    final uid = _currentUser?.uid;
    if (uid == null) return;
    final result = await ApiService.instance.fetchUserData(uid);
    if (result?['ok'] == true && result?['data'] != null) {
      final user = UserModel.fromJson(Map<String, dynamic>.from(result!['data']));
      await _persistUser(user);
      state = AsyncValue.data(user);
    }
  }

  Future<String?> updateProfile(Map<String, dynamic> fields) async {
    final uid = _currentUser?.uid;
    if (uid == null) return 'not_logged_in';
    try {
      final result = await ApiService.instance.upsertUser(uid, fields);
      if (result?['ok'] != true) return result?['err']?.toString() ?? 'update_failed';
      await refreshUser();
      return null;
    } catch (_) {
      return 'connection_error';
    }
  }

  Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final uid = _currentUser?.uid;
    final email = _currentUser?.email;
    if (uid == null || email == null) return 'not_logged_in';
    try {
      final result = await ApiService.instance.changePassword(
        uid: uid, oldPassword: oldPassword, newPassword: newPassword,
      );
      if (result?['ok'] != true) return result?['err']?.toString() ?? 'change_failed';
      return null;
    } catch (_) {
      return 'connection_error';
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(
  (ref) => AuthNotifier(),
);

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).valueOrNull;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider)?.isAdminLike ?? false;
});
