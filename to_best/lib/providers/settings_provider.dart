import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';
import '../services/sync_service.dart';

class AppSettings {
  final String theme;
  final Color accentColor;
  final String language;
  final String handMode;
  final int restTimerDuration;
  final String restTimerSound;
  final bool showOldValues;
  final bool showEpley;
  final bool showRpe;
  final bool showRepSuggest;
  final bool showVolume;
  final bool wakeLock;
  final bool notifications;
  final String selectedProgram;
  final int programDays;
  final List<int> gymDays;
  final bool motivationalMsgs;

  const AppSettings({
    required this.theme,
    required this.accentColor,
    required this.language,
    required this.handMode,
    required this.restTimerDuration,
    required this.restTimerSound,
    required this.showOldValues,
    required this.showEpley,
    required this.showRpe,
    required this.showRepSuggest,
    required this.showVolume,
    required this.wakeLock,
    required this.notifications,
    required this.selectedProgram,
    required this.programDays,
    required this.gymDays,
    required this.motivationalMsgs,
  });

  factory AppSettings.fromService() {
    final s = SettingsService.instance;
    return AppSettings(
      theme: s.theme,
      accentColor: s.accentColor,
      language: s.language,
      handMode: s.handMode,
      restTimerDuration: s.restTimerDuration,
      restTimerSound: s.restTimerSound,
      showOldValues: s.showOldValues,
      showEpley: s.showEpley,
      showRpe: s.showRpe,
      showRepSuggest: s.showRepSuggest,
      showVolume: s.showVolume,
      wakeLock: s.wakeLock,
      notifications: s.notifications,
      selectedProgram: s.selectedProgram,
      programDays: s.programDays,
      gymDays: s.gymDays,
      motivationalMsgs: s.motivationalMsgs,
    );
  }

  bool get isArabic => language == 'ar';
  Locale get locale => Locale(language);
  ThemeMode get themeMode => theme == 'light' ? ThemeMode.light : ThemeMode.dark;
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings.fromService());

  void reload() => state = AppSettings.fromService();

  Future<void> setTheme(String theme) async {
    await SettingsService.instance.setTheme(theme);
    state = AppSettings.fromService();
  }

  Future<void> setAccentColor(Color color) async {
    await SettingsService.instance.setAccentColor(color);
    state = AppSettings.fromService();
  }

  Future<void> setLanguage(String lang) async {
    await SettingsService.instance.setLanguage(lang);
    state = AppSettings.fromService();
  }

  Future<void> setHandMode(String mode) async {
    await SettingsService.instance.setHandMode(mode);
    state = AppSettings.fromService();
  }

  Future<void> setRestTimerDuration(int seconds) async {
    await SettingsService.instance.setRestTimerDuration(seconds);
    state = AppSettings.fromService();
  }

  Future<void> setRestTimerSound(String sound) async {
    await SettingsService.instance.setRestTimerSound(sound);
    state = AppSettings.fromService();
  }

  Future<void> setShowOldValues(bool v) async {
    await SettingsService.instance.setShowOldValues(v);
    state = AppSettings.fromService();
  }

  Future<void> setShowEpley(bool v) async {
    await SettingsService.instance.setShowEpley(v);
    state = AppSettings.fromService();
  }

  Future<void> setShowRpe(bool v) async {
    await SettingsService.instance.setShowRpe(v);
    state = AppSettings.fromService();
  }

  Future<void> setShowRepSuggest(bool v) async {
    await SettingsService.instance.setShowRepSuggest(v);
    state = AppSettings.fromService();
  }

  Future<void> setShowVolume(bool v) async {
    await SettingsService.instance.setShowVolume(v);
    state = AppSettings.fromService();
  }

  Future<void> setWakeLock(bool v) async {
    await SettingsService.instance.setWakeLock(v);
    state = AppSettings.fromService();
  }

  Future<void> setNotifications(bool v) async {
    await SettingsService.instance.setNotifications(v);
    state = AppSettings.fromService();
  }

  Future<void> setSelectedProgram(String program) async {
    await SettingsService.instance.setSelectedProgram(program);
    state = AppSettings.fromService();
  }

  Future<void> setProgramDays(int days) async {
    await SettingsService.instance.setProgramDays(days);
    state = AppSettings.fromService();
  }

  Future<void> setGymDays(List<int> days) async {
    await SettingsService.instance.setGymDays(days);
    state = AppSettings.fromService();
  }

  Future<void> setMotivationalMsgs(bool v) async {
    await SettingsService.instance.setMotivationalMsgs(v);
    state = AppSettings.fromService();
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);

final localeProvider = Provider<Locale>((ref) {
  return ref.watch(settingsProvider).locale;
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});

final accentColorProvider = Provider<Color>((ref) {
  return ref.watch(settingsProvider).accentColor;
});
