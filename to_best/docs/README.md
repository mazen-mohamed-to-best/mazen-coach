# TO Best — Flutter App

> تطبيق احترافي لإدارة التدريب والتغذية — مبني بـ Flutter ومدعوم بـ Google Apps Script

---

## 🌟 نظرة عامة

**TO Best** هو إعادة بناء كاملة لتطبيق MAZEN COACH بلغة Flutter. يوفر التطبيق نظاماً متكاملاً لإدارة التدريب والتغذية والحضور والتواصل بين المدربين والمتدربين.

### الميزات الرئيسية

| الميزة | الوصف |
|--------|--------|
| 🏋️ **التمرين** | 5 برامج تدريبية + مخصص، سجل الجلسات، مؤقت الراحة، تتبع الأوزان |
| 🥗 **التغذية** | تتبع الماكرو، سجل الوجبات، تتبع الماء |
| 📅 **الحضور** | تقويم شهري، تسجيل حضور/غياب/راحة، إحصائيات الإلتزام |
| 📊 **التقدم** | القياسات الجسمانية، الرسوم البيانية، تتبع الأرقام القياسية |
| 💬 **الشات** | غرف متعددة، AI مساعد، رد ومحادثة ورسائل مثبتة |
| 💳 **الاشتراكات** | خطة خفيفة وكاملة، كود خصم، رفع إيصال الدفع |
| 🔧 **الإدارة** | إدارة المستخدمين، موافقة الاشتراكات، سجل التعديلات |
| ⚙️ **الإعدادات** | ثيم داكن/فاتح، عربي/إنجليزي RTL/LTR، تخصيص كامل |

---

## 🏗️ البنية المعمارية

```
to_best/
├── lib/
│   ├── main.dart                    # نقطة البداية
│   ├── app.dart                     # Router + MaterialApp
│   ├── core/
│   │   ├── config/
│   │   │   └── app_theme.dart       # ثيمات داكن/فاتح + ألوان
│   │   ├── constants/
│   │   │   ├── app_colors.dart      # تعريف الألوان
│   │   │   ├── app_constants.dart   # الثوابت العامة
│   │   │   └── exercise_data.dart   # بيانات التمارين (كاملة)
│   │   └── l10n/
│   │       └── app_localizations.dart  # ترجمة AR/EN
│   ├── models/                      # نماذج البيانات
│   │   ├── user_model.dart
│   │   ├── workout_log_model.dart
│   │   ├── meal_model.dart
│   │   ├── attendance_model.dart
│   │   ├── chat_model.dart
│   │   ├── subscription_model.dart
│   │   ├── exercise_model.dart
│   │   └── notification_model.dart
│   ├── services/                    # طبقة الخدمات
│   │   ├── api_service.dart         # HTTP + Google Apps Script
│   │   ├── local_db_service.dart    # SQLite cache
│   │   ├── sync_service.dart        # المزامنة (30s دورة)
│   │   └── settings_service.dart    # SharedPreferences
│   ├── providers/                   # Riverpod state
│   │   ├── auth_provider.dart
│   │   ├── settings_provider.dart
│   │   └── sync_provider.dart
│   ├── features/                    # الميزات
│   │   ├── auth/                   # تسجيل دخول/خروج
│   │   ├── home/                   # الرئيسية
│   │   ├── workout/                # التمارين + الجلسات
│   │   ├── nutrition/              # التغذية + الماء
│   │   ├── attendance/             # الحضور
│   │   ├── progress/               # التقدم + القياسات
│   │   ├── chat/                   # الشات
│   │   ├── settings/               # الإعدادات
│   │   ├── admin/                  # لوحة الإدارة
│   │   └── subscription/           # الاشتراكات + الدفع
│   └── widgets/                    # ودجات مشتركة
│       └── common/
├── assets/
│   ├── images/
│   └── icons/
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml
├── pubspec.yaml
├── codemagic.yaml
└── docs/
    ├── README.md       ← هذا الملف
    ├── DEPLOYMENT.md
    └── QUICKSTART.md
```

---

## 🛠️ Stack التقني

| المكون | التقنية |
|--------|---------|
| **Framework** | Flutter 3.x (Dart 3.2+) |
| **State Management** | flutter_riverpod ^2.5.1 |
| **Navigation** | go_router ^13.2.4 |
| **Local Cache** | sqflite ^2.3.3 |
| **Settings** | shared_preferences ^2.2.3 |
| **HTTP** | http ^1.2.1 |
| **Charts** | fl_chart ^0.68.0 |
| **Fonts** | google_fonts (Cairo) |
| **Animation** | flutter_animate, lottie |
| **Backend** | Google Apps Script (WebApp URL) |
| **Database** | Google Sheets (via Apps Script) |

---

## 🔐 نظام الأدوار

| الدور | الصلاحيات |
|------|------------|
| `SUPER_ADMIN` | كامل الصلاحيات + إدارة الأدمنز |
| `ADMIN` | إدارة المستخدمين والاشتراكات |
| `COACH` | موافقة المستخدمين + عرض البيانات |
| `TRAINEE` | وصول حسب نوع الاشتراك |
| `VIEWER` | عرض محدود (ضيف) |

---

## 💳 نظام الاشتراكات

| الميزة | خفيف | كامل |
|--------|------|------|
| التمرين | ✅ | ✅ |
| الحضور | ✅ | ✅ |
| الشات العام | ✅ | ✅ |
| التغذية | ❌ | ✅ |
| التقدم والقياسات | ❌ | ✅ |
| الشات مع المدرب | ❌ | ✅ |
| AI مساعد | ❌ | ✅ |

**مدد الاشتراك:** 1 / 2 / 3 / 6 / 12 شهر مع خصومات تصاعدية

---

## 🔄 آلية المزامنة

```
Cloud (Google Sheets) ←→ API Service ←→ SQLite Cache ←→ UI
```

- **دورة**: كل 30 ثانية
- **Debounce**: 800ms بعد كل تغيير
- **Pull Cooldown**: 25 ثانية بين كل سحب
- **Sheet Sync**: كل 5 دقائق (snapshot كامل)
- **Offline Queue**: العمليات المعلقة تُحفظ وتُرسل عند الاتصال

---

## 📱 البرامج التدريبية

| البرنامج | الأيام | الجلسات |
|---------|--------|---------|
| **UL** (Upper/Lower) | 4 | Upper A, Lower A, Upper B, Lower B |
| **AP** (Anterior/Posterior) | 4 | Anterior A/B, Posterior A/B |
| **FB** (Full Body) | 3 | Full Body #1, #2, #3 |
| **ARNOLD** | 5 | Chest&Back, Shoulders&Arms, Lower A, Upper, Lower B |
| **PPL** (Push/Pull/Legs) | 5 | PUSH, PULL, Lower, Upper, Lower |
| **CUSTOM** | 3-6 | مخصص |

---

## 📲 التثبيت

```bash
# 1. clone المشروع
git clone <repo-url>
cd to_best

# 2. تثبيت الحزم
flutter pub get

# 3. تشغيل التطبيق
flutter run

# 4. بناء APK
flutter build apk --release

# 5. بناء AAB (Google Play)
flutter build appbundle --release
```

---

## ⚙️ الإعداد الأول

1. افتح التطبيق
2. اضغط على "الاتصال" في صفحة تسجيل الدخول
3. أدخل رابط Google Apps Script WebApp
4. أدخل مفتاح الأمان (Secret Key)
5. اضغط "اختبار الاتصال"
6. قم بتسجيل الدخول

---

## 🤝 المساهمة

1. Fork المشروع
2. أنشئ فرع جديد: `git checkout -b feature/new-feature`
3. Commit: `git commit -m 'Add new feature'`
4. Push: `git push origin feature/new-feature`
5. افتح Pull Request
