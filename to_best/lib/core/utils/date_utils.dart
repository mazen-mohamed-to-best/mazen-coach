/// Date utility helpers

class AppDateUtils {
  AppDateUtils._();

  /// Format date as YYYY-MM-DD
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format date as YYYY-MM
  static String formatMonth(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  /// Today's date key
  static String get todayKey => formatDate(DateTime.now());

  /// Current month key
  static String get currentMonthKey => formatMonth(DateTime.now());

  /// Parse YYYY-MM-DD to DateTime
  static DateTime? parseDate(String dateStr) {
    return DateTime.tryParse(dateStr);
  }

  /// Days in month
  static int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// First weekday of month (0=Sun, 1=Mon, ..., 6=Sat)
  static int firstWeekdayOfMonth(int year, int month) {
    return DateTime(year, month, 1).weekday % 7;
  }

  /// Format duration as MM:SS
  static String formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Format time as HH:MM
  static String formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// Days since date
  static int daysSince(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return 0;
    return DateTime.now().difference(d).inDays;
  }

  /// Calculate streak
  static int calcStreak(Set<String> workoutDates) {
    int streak = 0;
    var date = DateTime.now();
    for (int i = 0; i < 365; i++) {
      if (workoutDates.contains(formatDate(date))) {
        streak++;
        date = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// Month name in Arabic
  static String monthNameAr(int month) {
    const names = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return names[month - 1];
  }

  /// Month name in English
  static String monthNameEn(int month) {
    const names = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return names[month - 1];
  }

  /// Check if date is today
  static bool isToday(String dateStr) => dateStr == todayKey;

  /// Is this month
  static bool isCurrentMonth(String dateStr) {
    return dateStr.startsWith(currentMonthKey);
  }
}
