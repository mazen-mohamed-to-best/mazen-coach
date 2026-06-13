import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class ApiService {
  static final ApiService instance = ApiService._();
  ApiService._();

  String _webAppUrl = '';
  String _secretKey = '';

  Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    _webAppUrl = prefs.getString(AppConstants.prefWebAppUrl) ?? '';
    _secretKey = prefs.getString(AppConstants.prefSecretKey) ?? '';
  }

  Future<void> saveConfig(String url, String secret) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefWebAppUrl, url);
    await prefs.setString(AppConstants.prefSecretKey, secret);
    _webAppUrl = url;
    _secretKey = secret;
  }

  bool get isConfigured => _webAppUrl.isNotEmpty && _secretKey.isNotEmpty;

  String get webAppUrl => _webAppUrl;
  String get secretKey => _secretKey;

  Future<Map<String, dynamic>?> _post(Map<String, dynamic> payload, {int timeoutSec = 30}) async {
    if (!isConfigured) return null;
    try {
      payload['secret'] = _secretKey;
      final response = await http.post(
        Uri.parse(_webAppUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(Duration(seconds: timeoutSec));

      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (e) {
      return null;
    }
  }

  // ── Auth ───────────────────────────────────────────────────

  Future<Map<String, dynamic>?> login(String email, String password) =>
      _post({'action': 'LOGIN', 'email': email, 'password': password});

  Future<Map<String, dynamic>?> register({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) => _post({'action': 'REGISTER', 'email': email, 'password': password, 'name': name, 'phone': phone});

  Future<Map<String, dynamic>?> guestLogin(String code) =>
      _post({'action': 'GUEST_LOGIN', 'code': code});

  Future<Map<String, dynamic>?> forgotPassword(String email) =>
      _post({'action': 'FORGOT_PASSWORD', 'email': email});

  Future<Map<String, dynamic>?> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _post({'action': 'RESET_PASSWORD', 'email': email, 'code': code, 'newPassword': newPassword});

  Future<Map<String, dynamic>?> changePassword({
    required String uid,
    required String oldPassword,
    required String newPassword,
  }) => _post({'action': 'CHANGE_PASSWORD', 'uid': uid, 'oldPassword': oldPassword, 'newPassword': newPassword});

  // ── User Data ──────────────────────────────────────────────

  Future<Map<String, dynamic>?> fetchUserData(String uid) =>
      _post({'action': 'FETCH_USER_DATA', 'uid': uid});

  Future<Map<String, dynamic>?> fetchAllUsers() =>
      _post({'action': 'FETCH_ALL_USERS'});

  Future<Map<String, dynamic>?> updateUser(String uid, Map<String, dynamic> fields) =>
      _post({'action': 'UPDATE_USER', 'uid': uid, 'data': fields});

  Future<Map<String, dynamic>?> fetchFullData(String uid) =>
      _post({'action': 'FULL_SYNC_PULL', 'uid': uid}, timeoutSec: 60);

  // ── Data Save ──────────────────────────────────────────────

  Future<Map<String, dynamic>?> saveRow(String sheetName, String key, Map<String, dynamic> data) =>
      _post({'action': 'SAVE_ROW', 'sheetName': sheetName, 'key': key, 'data': data});

  Future<Map<String, dynamic>?> upsertUser(String uid, Map<String, dynamic> data) =>
      _post({'action': 'UPSERT_USER', 'uid': uid, 'data': data});

  // ── Chat ───────────────────────────────────────────────────

  Future<Map<String, dynamic>?> sendMessage(String roomId, Map<String, dynamic> msg) =>
      _post({'action': 'APPEND_CHAT', 'roomId': roomId, 'msg': msg});

  Future<Map<String, dynamic>?> fetchMessages(String roomId, int since) =>
      _post({'action': 'FETCH_MSGS', 'roomId': roomId, 'since': since});

  Future<Map<String, dynamic>?> deleteMessage(String roomId, String msgId) =>
      _post({'action': 'DELETE_MSG', 'roomId': roomId, 'msgId': msgId});

  Future<Map<String, dynamic>?> editMessage(String roomId, String msgId, String newText) =>
      _post({'action': 'EDIT_MSG', 'roomId': roomId, 'msgId': msgId, 'newText': newText});

  Future<Map<String, dynamic>?> pinMessage(String roomId, Map<String, dynamic> msg) =>
      _post({'action': 'PIN_MSG', 'roomId': roomId, 'msg': msg});

  Future<Map<String, dynamic>?> unpinMessage(String roomId) =>
      _post({'action': 'UNPIN_MSG', 'roomId': roomId});

  Future<Map<String, dynamic>?> getPinned(String roomId) =>
      _post({'action': 'GET_PINNED', 'roomId': roomId});

  // ── Subscription ───────────────────────────────────────────

  Future<Map<String, dynamic>?> saveSubscriptionRequest(String uid, Map<String, dynamic> data) =>
      _post({'action': 'SAVE_SUBSCRIPTION_REQUEST', 'uid': uid, 'data': data});

  // ── Version Check ───────────────────────────────────────────

  /// Checks version info from the server. Does NOT require auth — uses public action.
  Future<Map<String, dynamic>?> checkVersion(int currentBuild) async {
    if (!isConfigured) return null;
    try {
      final response = await http.post(
        Uri.parse(_webAppUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': 'CHECK_VERSION',
          'secret': _secretKey,
          'build': currentBuild,
          'platform': 'android',
        }),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSubscriptionRequests() =>
      _post({'action': 'GET_SUBSCRIPTION_REQUESTS'});

  Future<Map<String, dynamic>?> updateSubscriptionRequest(
    String id, String status, Map<String, dynamic>? fields,
  ) => _post({'action': 'UPDATE_SUBSCRIPTION_REQUEST', 'id': id, 'status': status, 'fields': fields});

  // ── Promo Codes ────────────────────────────────────────────

  Future<Map<String, dynamic>?> checkPromo(String code) =>
      _post({'action': 'CHECK_PROMO', 'code': code});

  Future<Map<String, dynamic>?> createPromo(String code, double discount, int maxUses) =>
      _post({'action': 'CREATE_PROMO', 'code': code, 'discount': discount, 'maxUses': maxUses});

  Future<Map<String, dynamic>?> listPromos() =>
      _post({'action': 'LIST_PROMOS'});

  Future<Map<String, dynamic>?> deletePromo(String code) =>
      _post({'action': 'DELETE_PROMO', 'code': code});

  // ── Guest Codes ────────────────────────────────────────────

  Future<Map<String, dynamic>?> createGuestCode([String? code]) =>
      _post({'action': 'CREATE_GUEST_CODE', 'code': code});

  Future<Map<String, dynamic>?> listGuestCodes() =>
      _post({'action': 'LIST_GUEST_CODES'});

  Future<Map<String, dynamic>?> deleteGuestCode(String code) =>
      _post({'action': 'DELETE_GUEST_CODE', 'code': code});

  // ── Admin ──────────────────────────────────────────────────

  Future<Map<String, dynamic>?> adminUpdateUser(String uid, Map<String, dynamic> fields) =>
      _post({'action': 'ADMIN_UPDATE_USER', 'uid': uid, 'fields': fields});

  Future<Map<String, dynamic>?> adminApproveUser(String uid, bool approved) =>
      _post({'action': 'ADMIN_APPROVE', 'uid': uid, 'approved': approved});

  Future<Map<String, dynamic>?> adminDeleteUser(String uid) =>
      _post({'action': 'ADMIN_DELETE_USER', 'uid': uid});

  Future<Map<String, dynamic>?> approveProgram(String uid, String programId, int programDays) =>
      _post({'action': 'APPROVE_PROGRAM', 'uid': uid, 'programId': programId, 'programDays': programDays});

  Future<Map<String, dynamic>?> forceLogoutUser(String uid) =>
      _post({'action': 'FORCE_LOGOUT_USER', 'uid': uid});

  Future<Map<String, dynamic>?> forceLogoutAll() =>
      _post({'action': 'FORCE_LOGOUT_ALL'});

  Future<Map<String, dynamic>?> chatBan(String uid, bool ban) =>
      _post({'action': 'CHAT_BAN', 'uid': uid, 'ban': ban});

  Future<Map<String, dynamic>?> chatMute(String uid, int muteUntil) =>
      _post({'action': 'CHAT_MUTE', 'uid': uid, 'muteUntil': muteUntil});

  // ── Profile Picture ────────────────────────────────────────

  Future<Map<String, dynamic>?> saveProfilePic(String uid, String imageData) =>
      _post({'action': 'SAVE_PROFILE_PIC', 'uid': uid, 'imageData': imageData}, timeoutSec: 60);

  // ── Settings ───────────────────────────────────────────────

  Future<Map<String, dynamic>?> saveSetting(String uid, String key, dynamic value) =>
      _post({'action': 'SAVE_SETTING', 'uid': uid, 'key': key, 'value': value});

  Future<Map<String, dynamic>?> getSettings(String uid) =>
      _post({'action': 'GET_SETTINGS', 'uid': uid});

  Future<Map<String, dynamic>?> getSubscriptionConfig() =>
      _post({'action': 'GET_SUBSCRIPTION_CONFIG'});

  Future<Map<String, dynamic>?> saveSubscriptionConfig(Map<String, dynamic> config) =>
      _post({'action': 'SAVE_SUBSCRIPTION_CONFIG', 'config': config});

  Future<Map<String, dynamic>?> getProgramRequests() =>
      _post({'action': 'GET_PROGRAM_REQUESTS'});

  Future<Map<String, dynamic>?> saveProgramRequest(String uid, Map<String, dynamic> data) =>
      _post({'action': 'SAVE_PROGRAM_REQUEST', 'uid': uid, 'data': data});

  Future<Map<String, dynamic>?> pushUserSheet(String uid, Map<String, dynamic> snapshot) =>
      _post({'action': 'UPDATE_USER_SHEET', 'uid': uid, 'snapshot': snapshot}, timeoutSec: 60);

  Future<Map<String, dynamic>?> testConnection() =>
      _post({'action': 'PING'});

  Future<Map<String, dynamic>?> getAuditLog() =>
      _post({'action': 'GET_AUDIT_LOG'});
}
