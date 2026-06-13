import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._();
  SettingsService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ── Theme ────────────────────────────────────────────────────

  String get theme => _prefs.getString(AppConstants.prefTheme) ?? AppConstants.defaultTheme;
  Future<void> setTheme(String value) => _prefs.setString(AppConstants.prefTheme, value);

  ThemeMode get themeMode => theme == 'light' ? ThemeMode.light : ThemeMode.dark;

  Color get accentColor {
    final hex = _prefs.getString(AppConstants.prefAccentColor) ?? AppConstants.defaultAccent;
    return _hexToColor(hex);
  }

  Future<void> setAccentColor(Color color) =>
      _prefs.setString(AppConstants.prefAccentColor, _colorToHex(color));

  // ── Language ──────────────────────────────────────────────────

  String get language => _prefs.getString(AppConstants.prefLanguage) ?? 'ar';
  Future<void> setLanguage(String value) => _prefs.setString(AppConstants.prefLanguage, value);

  Locale get locale => Locale(language);
  bool get isArabic => language == 'ar';

  // ── User ──────────────────────────────────────────────────────

  String? get userId => _prefs.getString(AppConstants.prefUserId);
  Future<void> setUserId(String uid) => _prefs.setString(AppConstants.prefUserId, uid);

  String? get userData => _prefs.getString(AppConstants.prefUserData);
  Future<void> setUserData(String json) => _prefs.setString(AppConstants.prefUserData, json);

  Future<void> clearUser() async {
    await _prefs.remove(AppConstants.prefUserId);
    await _prefs.remove(AppConstants.prefUserData);
  }

  // ── Workout Settings ──────────────────────────────────────────

  String get handMode => _prefs.getString(AppConstants.prefHandMode) ?? 'right';
  Future<void> setHandMode(String v) => _prefs.setString(AppConstants.prefHandMode, v);

  int get restTimerDuration => _prefs.getInt(AppConstants.prefRestTimer) ?? AppConstants.defaultRestTimer;
  Future<void> setRestTimerDuration(int v) => _prefs.setInt(AppConstants.prefRestTimer, v);

  String get restTimerSound => _prefs.getString(AppConstants.prefRestSound) ?? AppConstants.defaultRestSound;
  Future<void> setRestTimerSound(String v) => _prefs.setString(AppConstants.prefRestSound, v);

  bool get showOldValues => _prefs.getBool(AppConstants.prefShowOldValues) ?? AppConstants.defaultShowOldValues;
  Future<void> setShowOldValues(bool v) => _prefs.setBool(AppConstants.prefShowOldValues, v);

  bool get showEpley => _prefs.getBool(AppConstants.prefShowEpley) ?? AppConstants.defaultShowEpley;
  Future<void> setShowEpley(bool v) => _prefs.setBool(AppConstants.prefShowEpley, v);

  bool get showRpe => _prefs.getBool(AppConstants.prefShowRpe) ?? AppConstants.defaultShowRpe;
  Future<void> setShowRpe(bool v) => _prefs.setBool(AppConstants.prefShowRpe, v);

  bool get showRepSuggest => _prefs.getBool(AppConstants.prefShowRepSuggest) ?? AppConstants.defaultShowRepSuggest;
  Future<void> setShowRepSuggest(bool v) => _prefs.setBool(AppConstants.prefShowRepSuggest, v);

  bool get showVolume => _prefs.getBool(AppConstants.prefShowVolume) ?? AppConstants.defaultShowVolume;
  Future<void> setShowVolume(bool v) => _prefs.setBool(AppConstants.prefShowVolume, v);

  bool get wakeLock => _prefs.getBool(AppConstants.prefWakeLock) ?? AppConstants.defaultWakeLock;
  Future<void> setWakeLock(bool v) => _prefs.setBool(AppConstants.prefWakeLock, v);

  bool get notifications => _prefs.getBool(AppConstants.prefNotifications) ?? AppConstants.defaultNotifications;
  Future<void> setNotifications(bool v) => _prefs.setBool(AppConstants.prefNotifications, v);

  // ── Program Settings ──────────────────────────────────────────

  String get selectedProgram => _prefs.getString(AppConstants.prefSelectedProgram) ?? AppConstants.defaultProgram;
  Future<void> setSelectedProgram(String v) => _prefs.setString(AppConstants.prefSelectedProgram, v);

  int get programDays => _prefs.getInt(AppConstants.prefProgramDays) ?? AppConstants.defaultProgramDays;
  Future<void> setProgramDays(int v) => _prefs.setInt(AppConstants.prefProgramDays, v);

  List<int> get gymDays {
    final raw = _prefs.getString(AppConstants.prefGymDays);
    if (raw == null) return List.from(AppConstants.defaultGymDays);
    return raw.split(',').map((s) => int.tryParse(s) ?? 0).toList();
  }

  Future<void> setGymDays(List<int> days) =>
      _prefs.setString(AppConstants.prefGymDays, days.join(','));

  bool get motivationalMsgs => _prefs.getBool(AppConstants.prefMotivationalMsgs) ?? true;
  Future<void> setMotivationalMsgs(bool v) => _prefs.setBool(AppConstants.prefMotivationalMsgs, v);

  // ── API Config ────────────────────────────────────────────────

  String get webAppUrl => _prefs.getString(AppConstants.prefWebAppUrl) ?? '';
  String get secretKey => _prefs.getString(AppConstants.prefSecretKey) ?? '';

  Future<void> setApiConfig(String url, String secret) async {
    await _prefs.setString(AppConstants.prefWebAppUrl, url);
    await _prefs.setString(AppConstants.prefSecretKey, secret);
  }

  // ── Helpers ───────────────────────────────────────────────────

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    if (h.length == 8) return Color(int.parse(h, radix: 16));
    return const Color(0xFF7C6EFF);
  }

  String _colorToHex(Color color) =>
      '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
}
