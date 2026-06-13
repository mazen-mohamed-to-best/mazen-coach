# دليل إدارة الإصدارات — TO Best

---

## كيف يعمل النظام

```
التطبيق يشتغل
     ↓
يسأل السيرفر (GAS): ما أحدث إصدار؟ وما أقل إصدار مسموح؟
     ↓
┌─────────────────────────────────────────────────────┐
│ إصدار المستخدم < الحد الأدنى (minBuild)           │
│ → تحديث إجباري — التطبيق مقفل حتى يُحدَّث       │
├─────────────────────────────────────────────────────┤
│ إصدار المستخدم < أحدث إصدار (latestBuild)         │
│ → بانر اختياري في أعلى الشاشة                    │
├─────────────────────────────────────────────────────┤
│ إصدار المستخدم = أحدث إصدار                       │
│ → كل شيء طبيعي، لا رسائل                         │
└─────────────────────────────────────────────────────┘
```

---

## إعداد جدول الإصدارات في Google Sheets

أنشئ **Sheet** باسم `AppVersion` بهذه الأعمدة:

| key              | value                                               |
|------------------|-----------------------------------------------------|
| minBuild         | 1                                                   |
| latestBuild      | 2                                                   |
| latestVersionName| 1.1.0                                               |
| downloadUrl      | https://play.google.com/store/apps/details?id=com.tobest.app |
| notesAr          | إصلاح أخطاء وتحسين الأداء                          |
| notesEn          | Bug fixes and performance improvements              |
| isSupported      | true                                                |

---

## كود Google Apps Script — إضافة حالة CHECK_VERSION

أضف هذا الـ case داخل دالة `doPost` في ملف `Code.gs`:

```javascript
case 'CHECK_VERSION': {
  const sheet = SpreadsheetApp.getActiveSpreadsheet()
                              .getSheetByName('AppVersion');
  if (!sheet) return buildResponse({ ok: false, error: 'AppVersion sheet not found' });

  const rows = sheet.getDataRange().getValues();
  const data = {};
  rows.forEach(([key, value]) => { data[key] = value; });

  const currentBuild = parseInt(payload.build) || 0;
  const minBuild     = parseInt(data.minBuild)  || 1;
  const isSupported  = String(data.isSupported).toLowerCase() !== 'false';

  return buildResponse({
    ok:                true,
    minBuild:          minBuild,
    latestBuild:       parseInt(data.latestBuild)     || 1,
    latestVersionName: String(data.latestVersionName) || '1.0.0',
    downloadUrl:       String(data.downloadUrl)       || '',
    notesAr:           String(data.notesAr)           || '',
    notesEn:           String(data.notesEn)           || '',
    isSupported:       isSupported && currentBuild >= minBuild,
  });
}
```

---

## كيفية إصدار تحديث جديد

### الخطوة 1 — رفع إصدار التطبيق في `pubspec.yaml`

```yaml
# format: versionName+buildNumber
version: 1.1.0+2   # ← غيّر هنا (build number يزيد دايماً)
```

| الحقل | الوصف |
|-------|--------|
| `1.1.0` | اسم الإصدار (للعرض للمستخدمين) |
| `+2` | رقم البناء (build number) — يجب أن يزيد في كل إصدار |

### الخطوة 2 — بناء ملف AAB/APK

**عبر Codemagic (بدون كمبيوتر):**
1. ادفع التغييرات لـ GitHub
2. Codemagic يبني تلقائياً (راجع `codemagic.yaml`)
3. أو افتح Codemagic → Start build

**عبر سطر الأوامر:**
```bash
flutter build appbundle --release
# الملف في: build/app/outputs/bundle/release/app-release.aab
```

### الخطوة 3 — رفع للـ Play Store

1. افتح [Google Play Console](https://play.google.com/console)
2. Production / Internal Testing → Create new release
3. ارفع ملف `.aab`
4. انشر

### الخطوة 4 — تحديث جدول الإصدارات في Sheets

| الحقل | القيمة الجديدة | متى؟ |
|-------|----------------|------|
| `latestBuild` | رقم البناء الجديد (مثل `2`) | فوراً بعد النشر |
| `latestVersionName` | اسم الإصدار (مثل `1.1.0`) | فوراً |
| `notesAr` / `notesEn` | ملاحظات الإصدار | اختياري |
| `minBuild` | اتركه كما هو إلا إذا أردت إجبار الكل | عند الضرورة فقط |

---

## متى ترفع الـ minBuild (إجباري)؟

```
رفع minBuild = إجبار جميع المستخدمين على التحديث
```

**ارفعه فقط في هذه الحالات:**
- تغيير جذري في بنية قاعدة البيانات أو الـ API
- إصلاح ثغرة أمنية خطيرة
- نسخة قديمة تسبب تلف البيانات

**مثال:**
```
قبل: minBuild = 1  latestBuild = 5
بعد: minBuild = 5  latestBuild = 5   ← الكل يُجبر على التحديث
```

---

## التخزين المؤقت (Cache)

- النظام يحفظ نتيجة فحص الإصدار لمدة **6 ساعات**
- إذا فشل الاتصال، يعرض آخر نتيجة محفوظة
- إذا لم توجد نتيجة محفوظة وفشل الاتصال → `Unknown` (لا حجب)
- المستخدم يمكنه "تخطي" التحديث الاختياري → يُحفظ في SharedPreferences

---

## اختبار النظام

```dart
// في settings_screen.dart أو developer menu
// لمسح الكاش واختبار التحديث من جديد:
await VersionCheckService.instance.clearCache();
ref.read(versionProvider.notifier).refresh();
```
