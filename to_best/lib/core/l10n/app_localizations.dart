import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  bool get isAr => locale.languageCode == 'ar';

  String get appName => 'TO Best';
  String get tagline => isAr ? 'نظام التدريب والتغذية الاحترافي' : 'Professional Training & Nutrition System';
  String get version => isAr ? 'الإصدار' : 'Version';

  // ── Update system ────────────────────────────────────────────
  String get updateAvailable => isAr ? 'تحديث متاح' : 'Update Available';
  String get updateRequired => isAr ? 'تحديث إجباري مطلوب' : 'Update Required';
  String get updateForced => isAr ? 'إجباري' : 'Required';
  String get updateOptional => isAr ? 'اختياري' : 'Optional';
  String get updateNow => isAr ? 'تحديث الآن' : 'Update Now';
  String get updateLater => isAr ? 'لاحقاً (تذكيري لاحقاً)' : 'Later (Remind me)';
  String get updateBannerText => isAr ? 'يوجد إصدار جديد من التطبيق' : 'A new version is available';
  String get updateUrlMissing => isAr ? 'رابط التحديث غير متاح' : 'Update link not available';
  String get updateOpenFailed => isAr ? 'تعذر فتح متجر التطبيقات' : 'Could not open the app store';
  String get updateRequiredDescAr =>
      'هذه النسخة من التطبيق قديمة جداً ولا تعمل بشكل صحيح. يجب التحديث للاستمرار.';
  String get updateRequiredDescEn =>
      'This version of the app is too old and no longer works correctly. Please update to continue.';
  String get updateOptionalDescAr =>
      'يوجد إصدار جديد من التطبيق يحتوي على تحسينات وإصلاحات. ننصح بالتحديث.';
  String get updateOptionalDescEn =>
      'A newer version is available with improvements and fixes. We recommend updating.';
  String get login => isAr ? 'تسجيل الدخول' : 'Login';
  String get register => isAr ? 'إنشاء حساب' : 'Sign Up';
  String get logout => isAr ? 'تسجيل الخروج' : 'Logout';
  String get email => isAr ? 'البريد الإلكتروني' : 'Email';
  String get password => isAr ? 'كلمة المرور' : 'Password';
  String get fullName => isAr ? 'الاسم الكامل' : 'Full Name';
  String get phone => isAr ? 'رقم الهاتف' : 'Phone';
  String get confirmPass => isAr ? 'تأكيد كلمة المرور' : 'Confirm Password';
  String get loginBtn => isAr ? 'دخول' : 'Login';
  String get registerBtn => isAr ? 'إنشاء حساب' : 'Create Account';
  String get guestLogin => isAr ? 'دخول كضيف' : 'Guest Login';
  String get guestCode => isAr ? 'كود الضيف' : 'Guest Code';
  String get forgotPassword => isAr ? 'نسيت كلمة المرور؟' : 'Forgot Password?';
  String get resetPassword => isAr ? 'إعادة تعيين كلمة المرور' : 'Reset Password';

  String get pendingApproval => isAr ? 'في انتظار موافقة المدرب' : 'Waiting for Coach Approval';
  String get pendingDesc => isAr
      ? 'تم إرسال طلبك للمدرب. ستصلك إشعار عند الموافقة.'
      : 'Your request was sent to the coach. You will be notified when approved.';
  String get rejected => isAr ? 'تم رفض حسابك' : 'Account Rejected';
  String get rejectedDesc => isAr ? 'تواصل مع المدرب لمزيد من التفاصيل.' : 'Contact your coach for more details.';
  String get backToLogin => isAr ? 'رجوع لتسجيل الدخول' : 'Back to Login';

  String get home => isAr ? 'الرئيسية' : 'Home';
  String get workout => isAr ? 'التمرين' : 'Workout';
  String get nutrition => isAr ? 'التغذية' : 'Nutrition';
  String get attendance => isAr ? 'الإلتزام' : 'Commitment';
  String get progress => isAr ? 'التقدم' : 'Progress';
  String get chat => isAr ? 'الشات' : 'Chat';
  String get settings => isAr ? 'الإعدادات' : 'Settings';
  String get admin => isAr ? 'الإدارة' : 'Admin';

  String get todaySession => isAr ? 'تمرين اليوم' : "Today's Session";
  String get restDay => isAr ? 'يوم راحة' : 'Rest Day';
  String get noSession => isAr ? 'لا يوجد تمرين اليوم' : 'No workout today';
  String get totalSessions => isAr ? 'إجمالي الجلسات' : 'Total Sessions';
  String get streak => isAr ? 'سلسلة الأيام' : 'Streak';
  String get quickAccess => isAr ? 'وصول سريع' : 'Quick Access';
  String get latestPRs => isAr ? 'أحدث أرقام قياسية' : 'Latest PRs';
  String get noPRs => isAr ? 'لا توجد أرقام قياسية بعد' : 'No PRs yet';
  String get noPRsDesc => isAr ? 'أكمل جلسات التمرين لتسجيل أرقامك القياسية' : 'Complete workout sessions to record your PRs';
  String get greetingMorning => isAr ? 'صباح الخير ☀️' : 'Good Morning ☀️';
  String get greetingAfternoon => isAr ? 'مساء الخير 🌤' : 'Good Afternoon 🌤';
  String get greetingEvening => isAr ? 'مساء النور 🌙' : 'Good Evening 🌙';

  String get warmupProtocol => isAr ? '🔥 بروتوكول الإحماء' : '🔥 Warm-up Protocol';
  String get warmupDone => isAr ? 'انتهيت من الإحماء ✓' : 'Warm-up Done ✓';
  String get reps => isAr ? 'عدات' : 'Reps';
  String get sets => isAr ? 'مجاميع' : 'Sets';
  String get weight => isAr ? 'وزن' : 'Weight';
  String get rest => isAr ? 'راحة' : 'Rest';
  String get kg => 'kg';
  String get prev => isAr ? 'السابق' : 'Previous';
  String get notes => isAr ? 'ملاحظات' : 'Notes';
  String get video => isAr ? 'فيديو' : 'Video';
  String get alt => isAr ? 'بديل' : 'Alternative';
  String get main => isAr ? 'أساسي' : 'Main';
  String get rpe => isAr ? 'مستوى الجهد' : 'RPE';
  String get epley => isAr ? 'أقصى قوة (1RM)' : '1RM (Epley)';
  String get volume => isAr ? 'الحجم' : 'Volume';
  String get startRest => isAr ? 'بدء وقت الراحة' : 'Start Rest Timer';
  String get stopRest => isAr ? 'إيقاف' : 'Stop';
  String get resetTimer => isAr ? 'إعادة' : 'Reset';
  String get restDone => isAr ? 'انتهت الراحة! 💪' : 'Rest Done! 💪';
  String get finishSession => isAr ? 'إنهاء الجلسة' : 'Finish Session';
  String get sessionDone => isAr ? '🎉 أحسنت! انتهت الجلسة' : '🎉 Great work! Session done';
  String get increaseWeight => isAr ? '↑ زيادة وزن' : '↑ Increase Weight';
  String get decreaseWeight => isAr ? '↓ تقليل وزن' : '↓ Decrease Weight';
  String get newPR => isAr ? '🏆 رقم قياسي جديد!' : '🏆 New Personal Record!';

  String get gym => isAr ? 'حضور ✔' : 'Present ✔';
  String get absent => isAr ? 'غياب ✘' : 'Absent ✘';
  String get restMark => isAr ? 'راحة 🛌' : 'Rest 🛌';
  String get thisMonth => isAr ? 'هذا الشهر' : 'This Month';
  String get markToday => isAr ? 'سجّل اليوم' : 'Mark Today';
  String get gymDays => isAr ? 'أيام حضور' : 'Gym Days';
  String get absentDays => isAr ? 'أيام غياب' : 'Absent Days';
  String get restDays => isAr ? 'أيام راحة' : 'Rest Days';
  String get commitment => isAr ? 'الإلتزام' : 'Commitment';

  String get calories => isAr ? 'سعرات' : 'Calories';
  String get protein => isAr ? 'بروتين' : 'Protein';
  String get carbs => isAr ? 'كربوهيدرات' : 'Carbs';
  String get fat => isAr ? 'دهون' : 'Fat';
  String get fiber => isAr ? 'ألياف' : 'Fiber';
  String get water => isAr ? 'ماء' : 'Water';
  String get noFoodToday => isAr ? 'لا يوجد وجبات مسجلة اليوم' : 'No food logged today';
  String get searchFood => isAr ? 'ابحث عن طعام…' : 'Search food…';
  String get addFood => isAr ? 'إضافة طعام' : 'Add Food';
  String get mealPlan => isAr ? 'خطة الوجبات' : 'Meal Plan';
  String get loggedMeals => isAr ? 'وجباتك اليوم' : 'Today\'s Meals';
  String get remaining => isAr ? 'المتبقي' : 'Remaining';
  String get consumed => isAr ? 'المستهلك' : 'Consumed';
  String get target => isAr ? 'الهدف' : 'Target';
  String get breakfast => isAr ? 'الإفطار' : 'Breakfast';
  String get lunch => isAr ? 'الغداء' : 'Lunch';
  String get dinner => isAr ? 'العشاء' : 'Dinner';
  String get snack => isAr ? 'وجبة خفيفة' : 'Snack';
  String get waterTracker => isAr ? 'تتبع الماء' : 'Water Tracker';

  String get appearance => isAr ? 'المظهر' : 'Appearance';
  String get theme => isAr ? 'الثيم' : 'Theme';
  String get accentColor => isAr ? 'لون التمييز' : 'Accent Color';
  String get language => isAr ? 'اللغة' : 'Language';
  String get arabic => 'عربي';
  String get english => 'English';
  String get direction => isAr ? 'اتجاه التطبيق' : 'App Direction';
  String get handMode => isAr ? 'وضع اليد' : 'Hand Mode';
  String get rightHand => isAr ? 'يد يمين (افتراضي)' : 'Right Hand (Default)';
  String get leftHand => isAr ? 'يد يسار' : 'Left Hand';
  String get workoutSettings => isAr ? 'إعدادات التمرين' : 'Workout Settings';
  String get programSettings => isAr ? 'إعدادات البرنامج' : 'Program Settings';
  String get restTimerSound => isAr ? 'صوت مؤقت الراحة' : 'Rest Timer Sound';
  String get showOldValues => isAr ? 'إظهار القيم القديمة' : 'Show Previous Values';
  String get showEpley => isAr ? 'إظهار 1RM (Epley)' : 'Show 1RM (Epley)';
  String get showRPE => isAr ? 'إظهار مستوى الجهد' : 'Show RPE';
  String get showVolume => isAr ? 'إظهار الحجم الكلي' : 'Show Total Volume';
  String get showRepSuggest => isAr ? 'اقتراح الوزن' : 'Weight Suggestion';
  String get wakeLock => isAr ? 'منع قفل الشاشة أثناء التمرين' : 'Prevent Screen Lock During Workout';
  String get notifications => isAr ? 'الإشعارات' : 'Notifications';
  String get connection => isAr ? 'الاتصال' : 'Connection';
  String get webAppUrl => isAr ? 'رابط WebApp' : 'WebApp URL';
  String get secretKey => isAr ? 'مفتاح الأمان' : 'Secret Key';
  String get testConnection => isAr ? 'اختبار الاتصال' : 'Test Connection';
  String get syncNow => isAr ? 'مزامنة الآن' : 'Sync Now';
  String get syncDone => isAr ? 'تمت المزامنة ✓' : 'Sync Done ✓';
  String get changePassword => isAr ? 'تغيير كلمة المرور' : 'Change Password';
  String get changeEmail => isAr ? 'تغيير البريد' : 'Change Email';
  String get changeName => isAr ? 'تغيير الاسم' : 'Change Name';
  String get oldPassword => isAr ? 'كلمة المرور الحالية' : 'Current Password';
  String get newPassword => isAr ? 'كلمة المرور الجديدة' : 'New Password';
  String get profile => isAr ? 'الملف الشخصي' : 'Profile';

  String get users => isAr ? 'المستخدمون' : 'Users';
  String get addUser => isAr ? '+ إضافة' : '+ Add';
  String get approveUser => isAr ? 'موافقة' : 'Approve';
  String get rejectUser => isAr ? 'رفض' : 'Reject';
  String get editUser => isAr ? 'تعديل' : 'Edit';
  String get deleteUser => isAr ? 'حذف' : 'Delete';
  String get viewAsUser => isAr ? 'تصفح كمستخدم' : 'View as User';
  String get role => isAr ? 'الدور' : 'Role';
  String get status => isAr ? 'الحالة' : 'Status';
  String get program => isAr ? 'البرنامج' : 'Program';
  String get active => isAr ? 'نشط' : 'Active';
  String get pending => isAr ? 'انتظار' : 'Pending';
  String get rejected2 => isAr ? 'مرفوض' : 'Rejected';
  String get trainee => isAr ? 'متدرب' : 'Trainee';
  String get viewer => isAr ? 'مشاهد' : 'Viewer';
  String get coach => isAr ? 'مدرب' : 'Coach';
  String get adminRole => isAr ? 'أدمن' : 'Admin';
  String get superAdmin => isAr ? 'سوبر أدمن' : 'Super Admin';
  String get auditLog => isAr ? 'سجل التعديلات' : 'Audit Log';
  String get programRequests => isAr ? 'طلبات تغيير البرنامج' : 'Program Change Requests';
  String get dailyCals => isAr ? 'السعرات اليومية' : 'Daily Calories';

  String get save => isAr ? 'حفظ' : 'Save';
  String get cancel => isAr ? 'إلغاء' : 'Cancel';
  String get confirm => isAr ? 'تأكيد' : 'Confirm';
  String get delete => isAr ? 'حذف' : 'Delete';
  String get edit => isAr ? 'تعديل' : 'Edit';
  String get add => isAr ? 'إضافة' : 'Add';
  String get close => isAr ? 'إغلاق' : 'Close';
  String get back => isAr ? 'رجوع' : 'Back';
  String get loading => isAr ? 'جارٍ التحميل…' : 'Loading…';
  String get syncing => isAr ? 'مزامنة…' : 'Syncing…';
  String get saved => isAr ? 'تم الحفظ ✓' : 'Saved ✓';
  String get error => isAr ? 'حدث خطأ' : 'An error occurred';
  String get offline => isAr ? 'أنت غير متصل بالإنترنت' : 'You are offline';
  String get offlineNote => isAr
      ? 'البيانات محفوظة محلياً وستُزامن عند الاتصال'
      : 'Data saved locally and will sync when online';
  String get yes => isAr ? 'نعم' : 'Yes';
  String get no => isAr ? 'لا' : 'No';
  String get ok => isAr ? 'موافق' : 'OK';

  String get generalChat => isAr ? 'المجموعة العامة' : 'General Group';
  String get coachChat => isAr ? 'المدرب' : 'Coach';
  String get announcements => isAr ? 'الإعلانات' : 'Announcements';
  String get supportChat => isAr ? 'الدعم الفني' : 'Support';
  String get aiChat => isAr ? 'مساعد TO Best' : 'TO Best AI';
  String get typeMessage => isAr ? 'اكتب رسالة…' : 'Type a message…';
  String get send => isAr ? 'إرسال' : 'Send';
  String get pinMessage => isAr ? 'تثبيت الرسالة' : 'Pin Message';
  String get unpinMessage => isAr ? 'إلغاء التثبيت' : 'Unpin';
  String get deleteMessage => isAr ? 'حذف الرسالة' : 'Delete Message';
  String get editMessage => isAr ? 'تعديل الرسالة' : 'Edit Message';
  String get replyTo => isAr ? 'الرد على' : 'Reply to';
  String get banUser => isAr ? 'حظر المستخدم' : 'Ban User';
  String get muteUser => isAr ? 'كتم المستخدم' : 'Mute User';
  String get messageDeleted => isAr ? 'تم حذف هذه الرسالة' : 'This message was deleted';
  String get messageEdited => isAr ? 'تم تعديله' : 'edited';
  String get pinnedMessage => isAr ? 'رسالة مثبتة' : 'Pinned Message';

  String get subscription => isAr ? 'الاشتراك' : 'Subscription';
  String get subscribeNow => isAr ? 'اشترك الآن' : 'Subscribe Now';
  String get subscriptionType => isAr ? 'نوع الاشتراك' : 'Subscription Type';
  String get subscriptionDuration => isAr ? 'مدة الاشتراك' : 'Duration';
  String get month => isAr ? 'شهر' : 'Month';
  String get months => isAr ? 'أشهر' : 'Months';
  String get subLight => isAr ? 'اشتراك خفيف' : 'Light Subscription';
  String get subFull => isAr ? 'اشتراك كامل' : 'Full Subscription';
  String get walletNumber => isAr ? 'رقم المحفظة للتحويل' : 'Wallet Number';
  String get uploadProof => isAr ? 'رفع إيصال التحويل' : 'Upload Transfer Proof';
  String get promoCode => isAr ? 'كود الخصم' : 'Promo Code';
  String get applyCode => isAr ? 'تطبيق الكود' : 'Apply Code';
  String get total => isAr ? 'الإجمالي' : 'Total';
  String get discount => isAr ? 'خصم' : 'Discount';
  String get submitRequest => isAr ? 'إرسال الطلب' : 'Submit Request';
  String get paymentPending => isAr ? 'طلب معلق' : 'Payment Pending';
  String get subscriptionActive => isAr ? 'الاشتراك نشط' : 'Subscription Active';
  String get subscriptionExpired => isAr ? 'انتهى الاشتراك' : 'Subscription Expired';
  String get expiresOn => isAr ? 'ينتهي في' : 'Expires on';
  String get renewSubscription => isAr ? 'تجديد الاشتراك' : 'Renew Subscription';
  String get manageSubscriptions => isAr ? 'إدارة الاشتراكات' : 'Manage Subscriptions';

  String get darkTheme => isAr ? 'داكن' : 'Dark';
  String get lightTheme => isAr ? 'فاتح' : 'Light';
  String get bell => isAr ? 'جرس' : 'Bell';
  String get beep => isAr ? 'صفير' : 'Beep';
  String get chime => isAr ? 'نغمة' : 'Chime';
  String get whistle => isAr ? 'صفارة' : 'Whistle';
  String get silent => isAr ? 'صامت' : 'Silent';
  String get connOK => isAr ? 'تم الاتصال بنجاح ✓' : 'Connected successfully ✓';
  String get connFail => isAr ? 'فشل الاتصال' : 'Connection failed';

  String get programChoose => isAr ? 'اختر برنامجك التدريبي' : 'Choose Your Training Program';
  String get daysPerWeek => isAr ? 'أيام في الأسبوع' : 'Days Per Week';

  String sat(bool short) => isAr ? (short ? 'سب' : 'السبت') : (short ? 'Sat' : 'Saturday');
  String sun(bool short) => isAr ? (short ? 'أح' : 'الأحد') : (short ? 'Sun' : 'Sunday');
  String mon(bool short) => isAr ? (short ? 'إث' : 'الاثنين') : (short ? 'Mon' : 'Monday');
  String tue(bool short) => isAr ? (short ? 'ثل' : 'الثلاثاء') : (short ? 'Tue' : 'Tuesday');
  String wed(bool short) => isAr ? (short ? 'أر' : 'الأربعاء') : (short ? 'Wed' : 'Wednesday');
  String thu(bool short) => isAr ? (short ? 'خم' : 'الخميس') : (short ? 'Thu' : 'Thursday');
  String fri(bool short) => isAr ? (short ? 'جم' : 'الجمعة') : (short ? 'Fri' : 'Friday');

  String dayName(int weekday, {bool short = false}) {
    switch (weekday % 7) {
      case 0: return sun(short);
      case 1: return mon(short);
      case 2: return tue(short);
      case 3: return wed(short);
      case 4: return thu(short);
      case 5: return fri(short);
      case 6: return sat(short);
      default: return '';
    }
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
