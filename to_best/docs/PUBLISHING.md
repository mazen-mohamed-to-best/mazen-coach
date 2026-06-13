# دليل النشر الاحترافي — TO Best (بدون كمبيوتر)

---

## ملاحظة مهمة

> بناء تطبيق Flutter يتطلب عملية compile لا تتم مباشرة على الهاتف.
> لكن يمكن إدارة كل شيء عبر **خدمات CI/CD السحابية** من هاتفك.

---

## الطريقة 1 — Codemagic (الأسهل — موصى بها ✅)

**المتطلبات:** حساب GitHub + حساب Codemagic

### الإعداد (مرة واحدة فقط)

1. **ارفع المشروع على GitHub** (من هاتفك عبر تطبيق GitHub):
   - افتح [github.com](https://github.com) → New repository
   - اسمه مثلاً: `to-best-app`

2. **ادفع الكود** عبر [Working Copy](https://workingcopyapp.com/) (تطبيق Git للـ iPhone/iPad):
   ```
   iOS: Working Copy — مجاني مع ميزات أساسية
   Android: MGit أو GitJournal
   ```

3. **اربط Codemagic بـ GitHub**:
   - افتح [codemagic.io](https://codemagic.io) → Sign in with GitHub
   - Add application → اختر مستودعك
   - يكتشف `codemagic.yaml` تلقائياً

4. **أضف Keystore للتوقيع** في Codemagic:
   - Settings → Code signing → Android → Upload keystore
   - أدخل alias + passwords

5. **أضف Google Play Service Account** في Codemagic:
   - Settings → Integrations → Google Play
   - ارفع ملف JSON لـ service account

### نشر إصدار جديد (من الهاتف)

```
1. عدّل الكود في IDE موبايل (Spck Editor / DroidEdit)
   أو مباشرة في GitHub web editor
2. اعدّل version في pubspec.yaml → 1.1.0+2
3. commit + push
4. Codemagic يبني تلقائياً ويرفع لـ Play Store
```

**الوقت:** حوالي 15-25 دقيقة بدون أي تدخل منك.

---

## الطريقة 2 — GitHub Actions (مجاني بالكامل)

**المتطلبات:** حساب GitHub فقط

### ملف `.github/workflows/release.yml`

```yaml
name: Build & Deploy

on:
  push:
    tags:
      - 'v*'        # يشتغل عند push tag مثل v1.1.0

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.22.0'
          channel: 'stable'

      - name: Get dependencies
        run: flutter pub get
        working-directory: to_best

      - name: Build App Bundle
        run: |
          flutter build appbundle --release \
            --dart-define=BUILD_ENV=production
        working-directory: to_best

      - name: Sign AAB
        uses: r0adkll/sign-android-release@v1
        with:
          releaseDirectory: to_best/build/app/outputs/bundle/release
          signingKeyBase64: ${{ secrets.KEYSTORE_BASE64 }}
          alias: ${{ secrets.KEY_ALIAS }}
          keyStorePassword: ${{ secrets.KEYSTORE_PASSWORD }}
          keyPassword: ${{ secrets.KEY_PASSWORD }}

      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.SERVICE_ACCOUNT_JSON }}
          packageName: com.tobest.app
          releaseFiles: to_best/build/app/outputs/bundle/release/*.aab
          track: internal
```

### إضافة Secrets في GitHub (من الهاتف)

1. افتح مستودعك على [github.com](https://github.com)
2. Settings → Secrets and variables → Actions → New secret
3. أضف:
   - `KEYSTORE_BASE64` — ملف keystore مشفر بـ base64
   - `KEY_ALIAS` — اسم الـ alias
   - `KEYSTORE_PASSWORD` — كلمة مرور الكيستور
   - `KEY_PASSWORD` — كلمة مرور المفتاح
   - `SERVICE_ACCOUNT_JSON` — محتوى ملف JSON

### نشر من الهاتف

```bash
# أي متصفح — GitHub website
1. اذهب للمستودع
2. Releases → Create new release
3. Tag: v1.1.0
4. Publish release
→ يبدأ GitHub Actions تلقائياً ✅
```

---

## الطريقة 3 — Bitrise

**المتطلبات:** حساب Bitrise

1. اذهب لـ [bitrise.io](https://bitrise.io) → Add new app
2. اربطه بـ GitHub
3. اختر Flutter workflow
4. أضف Google Play deployment step
5. اضغط "Start build" من الموبايل

**مميز Bitrise:** يدعم iOS و Android. مجاني للمشاريع الصغيرة.

---

## الطريقة 4 — رفع APK يدوياً (أبسط — بدون Play Store)

### بناء APK عبر Replit أو أي بيئة سحابية

```bash
# في Cloud IDE (Gitpod / Codespaces / Replit)
cd to_best
flutter build apk --release --split-per-abi

# ملفات APK في:
# build/app/outputs/flutter-apk/
#   app-arm64-v8a-release.apk   ← أجهزة 64-bit الحديثة
#   app-armeabi-v7a-release.apk ← أجهزة قديمة
#   app-x86_64-release.apk      ← emulator
```

### توزيع APK مباشرة (بدون Play Store)

| الخيار | الوصف |
|--------|--------|
| **Firebase App Distribution** | أفضل للاختبار مع مجموعة محدودة |
| **رابط Drive مباشر** | بسيط — ارفع APK على Drive وشارك الرابط |
| **Telegram بوت** | ارسل APK في مجموعة المتدربين |
| **APKPure / Aptoide** | متاجر APK بديلة |

---

## إعداد Keystore (مرة واحدة)

الـ Keystore هو ملف التوقيع الرقمي — **احفظه في مكان آمن للأبد**.

```bash
# في أي Terminal (Cloud Shell / Replit):
keytool -genkey -v \
  -keystore to_best_keystore.jks \
  -alias to_best \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# يسألك:
# - كلمة مرور الكيستور
# - معلومات الشركة (اسمك، البلد)
```

**تحويل لـ base64** (للـ GitHub Secrets):
```bash
base64 -w 0 to_best_keystore.jks
```

### ملف `android/key.properties`
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=to_best
storeFile=../to_best_keystore.jks
```

> ⚠️ أضف `key.properties` و `*.jks` لـ `.gitignore`

---

## إعداد Google Play Service Account

1. افتح [Google Play Console](https://play.google.com/console)
2. Setup → API access → Create service account
3. انتقل لـ [Google Cloud Console](https://console.cloud.google.com)
4. Service Accounts → المستخدم الجديد → Create key → JSON
5. حمّل الملف JSON

### صلاحيات Play Console

1. اذهب لـ Play Console → Users and permissions
2. Invite user → أدخل email الـ service account
3. منح صلاحية: Release manager

---

## مقارنة الطرق

| الطريقة | السهولة | التكلفة | السرعة | مناسبة لـ |
|---------|---------|---------|--------|-----------|
| **Codemagic** | ⭐⭐⭐⭐⭐ | مجاني (500 min/mo) | ✅ تلقائي | نشر Production |
| **GitHub Actions** | ⭐⭐⭐⭐ | مجاني كلياً | ✅ تلقائي | مشاريع مفتوحة المصدر |
| **Bitrise** | ⭐⭐⭐ | مجاني محدود | ✅ تلقائي | فرق كبيرة |
| **APK يدوي** | ⭐⭐⭐⭐⭐ | مجاني | ⚡ فوري | اختبار سريع |

---

## الخلاصة — أسرع طريقة من الهاتف

```
1. Codemagic متصل بـ GitHub ✓
2. عدّل pubspec.yaml → version: 1.x.0+BUILD
3. commit + push من Working Copy (iOS) أو MGit (Android)
4. انتظر 20 دقيقة → التطبيق في Play Store ✓
5. عدّل خلية latestBuild في Google Sheets → التحديث يظهر للمستخدمين ✓
```
