class AppConstants {
  AppConstants._();

  static const String appName = 'TO Best';
  static const String appVersion = 'v1.0.0';
  static const String bundleId = 'com.tobest.app';

  // Roles
  static const String roleSuperAdmin = 'SUPER_ADMIN';
  static const String roleAdmin = 'ADMIN';
  static const String roleCoach = 'COACH';
  static const String roleTrainee = 'TRAINEE';
  static const String roleViewer = 'VIEWER';

  // User status
  static const String statusActive = 'active';
  static const String statusPending = 'pending';
  static const String statusRejected = 'rejected';
  static const String statusInactive = 'inactive';

  // Subscription status
  static const String subActive = 'active';
  static const String subPending = 'payment_pending';
  static const String subExpired = 'expired';
  static const String subNone = 'none';

  // Subscription types
  static const String subLight = 'light';
  static const String subFull = 'full';

  // Chat rooms
  static const String chatGeneral = 'general';
  static const String chatAnnouncements = 'announcements';
  static const String chatSupport = 'support';

  // Programs
  static const List<String> programIds = ['UL', 'AP', 'FB', 'ARNOLD', 'PPL', 'CUSTOM'];

  // Attendance marks
  static const String attGym = 'GYM';
  static const String attAbsent = 'ABS';
  static const String attRest = 'REST';

  // Sync
  static const int syncCycleMs = 30000;
  static const int pullCooldownMs = 25000;
  static const int sheetSyncFreqMs = 300000;
  static const int debounceMs = 800;

  // Local DB
  static const String dbName = 'to_best_cache.db';
  static const int dbVersion = 1;

  // SharedPrefs keys
  static const String prefUserId = 'user_id';
  static const String prefUserData = 'user_data';
  static const String prefWebAppUrl = 'web_app_url';
  static const String prefSecretKey = 'secret_key';
  static const String prefLanguage = 'language';
  static const String prefTheme = 'theme';
  static const String prefAccentColor = 'accent_color';
  static const String prefHandMode = 'hand_mode';
  static const String prefRestTimer = 'rest_timer';
  static const String prefRestSound = 'rest_sound';
  static const String prefShowOldValues = 'show_old_values';
  static const String prefShowEpley = 'show_epley';
  static const String prefShowRpe = 'show_rpe';
  static const String prefShowRepSuggest = 'show_rep_suggest';
  static const String prefShowVolume = 'show_volume';
  static const String prefWakeLock = 'wake_lock';
  static const String prefNotifications = 'notifications';
  static const String prefSelectedProgram = 'selected_program';
  static const String prefProgramDays = 'program_days';
  static const String prefGymDays = 'gym_days';
  static const String prefMotivationalMsgs = 'motivational_msgs';

  // Default values
  static const String defaultTheme = 'dark';
  static const String defaultAccent = '#7C6EFF';
  static const int defaultRestTimer = 180;
  static const String defaultRestSound = 'bell';
  static const bool defaultShowOldValues = true;
  static const bool defaultShowEpley = true;
  static const bool defaultShowRpe = true;
  static const bool defaultShowRepSuggest = true;
  static const bool defaultShowVolume = true;
  static const bool defaultWakeLock = true;
  static const bool defaultNotifications = true;
  static const String defaultProgram = 'UL';
  static const int defaultProgramDays = 4;
  static const List<int> defaultGymDays = [6, 0, 1, 3];

  // Stagnation
  static const int stagnationWeeks = 3;
  static const int repsUpThreshold = 12;
  static const int repsDownThreshold = 4;

  // Sounds
  static const List<String> sounds = ['bell', 'beep', 'chime', 'whistle', 'silent'];

  // Subscription durations
  static const List<int> subDurations = [1, 2, 3, 6, 12];

  // Chat
  static const int chatPollIntervalMs = 8000;
  static const int chatMaxMessages = 100;
}
