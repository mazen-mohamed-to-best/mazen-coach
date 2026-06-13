# TO Best — دليل النشر (Deployment Guide)

---

## 📋 المتطلبات المسبقة

### أدوات التطوير
- Flutter SDK ≥ 3.19.0
- Dart SDK ≥ 3.2.0
- Android Studio أو VS Code
- Java JDK 17
- Git

### حسابات خارجية
- حساب Google (للـ Google Apps Script)
- حساب Codemagic (للـ CI/CD)
- Google Play Console (للنشر على Google Play)

---

## 🔧 1. إعداد Google Apps Script (Backend)

### الخطوات

1. افتح [Google Apps Script](https://script.google.com)
2. أنشئ مشروعاً جديداً
3. انسخ كود الـ backend من المشروع الأصلي (MAZEN COACH)
4. انشر كـ **WebApp**:
   - Execute as: **Me**
   - Who has access: **Anyone**
5. انسخ رابط الـ WebApp
6. احفظ الـ Secret Key الذي ستستخدمه في التطبيق

### ملاحظات مهمة
- تأكد من وجود Google Sheets مرتبطة بالمشروع
- الأعمدة المطلوبة: Users, WorkoutLogs, Attendance, Meals, Chat, Subscriptions, PromoCodes, GuestCodes
- اختبر الاتصال من التطبيق قبل النشر

---

## 🏗️ 2. بناء التطبيق محلياً

### Debug APK (للاختبار)

```bash
cd to_best
flutter pub get
flutter build apk --debug
# الملف في: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK (للنشر)

```bash
# 1. أنشئ keystore
keytool -genkey -v \
  -keystore ~/tobest-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias tobest

# 2. أنشئ key.properties في android/
cat > android/key.properties << EOF
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=tobest
storeFile=/path/to/tobest-keystore.jks
EOF

# 3. بناء APK
flutter build apk --release

# 4. بناء AAB (مطلوب لـ Google Play)
flutter build appbundle --release
```

### Android build.gradle (مرجعي)

تأكد من وجود هذه الإعدادات في `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.tobest.app"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

---

## 🚀 3. Codemagic CI/CD

### الإعداد

1. سجّل في [codemagic.io](https://codemagic.io)
2. اربط مستودع Git الخاص بك
3. اختر Flutter workflow
4. أضف متغيرات البيئة:

| المتغير | الوصف |
|---------|--------|
| `CM_KEYSTORE` | keystore file بصيغة base64 |
| `CM_KEYSTORE_PASSWORD` | كلمة مرور الـ keystore |
| `CM_KEY_PASSWORD` | كلمة مرور المفتاح |
| `CM_KEY_ALIAS` | اسم الـ alias |

### تحويل keystore إلى base64
```bash
base64 -i tobest-keystore.jks | pbcopy  # macOS
base64 -w 0 tobest-keystore.jks         # Linux
```

### الـ codemagic.yaml الجاهز

ملف `codemagic.yaml` موجود في جذر المشروع ويتضمن:
- **android-debug**: بناء APK للاختبار
- **android-release**: بناء APK + AAB للنشر على Google Play

---

## 📦 4. النشر على Google Play

### المتطلبات
- Google Play Console account ($25 رسوم تسجيل مرة واحدة)
- AAB ملف (وليس APK)
- Screenshots (مطلوب 2-8 لقطة شاشة)
- Feature graphic (1024x500 px)
- وصف التطبيق بالعربية والإنجليزية

### الخطوات
1. افتح Google Play Console
2. أنشئ تطبيقاً جديداً
3. أكمل Store Listing
4. Upload the AAB في Internal Testing أولاً
5. بعد الاختبار، انقل إلى Production

### المعلومات المطلوبة
- **Package name**: `com.tobest.app`
- **App name**: TO Best
- **Category**: Health & Fitness
- **Content rating**: Teen (13+)

---

## 🔄 5. التحديثات المستقبلية

### رفع نسخة جديدة

```bash
# في pubspec.yaml، غيّر version
version: 1.0.1+2  # (versionName+versionCode)

# أعد البناء
flutter build appbundle --release --build-number=2

# ارفع الـ AAB الجديد على Google Play Console
```

### عبر Codemagic
- زيادة BUILD_NUMBER تلقائياً
- تنزيل AAB من artifacts
- رفعه على Google Play يدوياً أو عبر API

---

## 🐛 حل المشاكل الشائعة

### خطأ: Gradle build failed
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### خطأ: SDK version mismatch
```bash
flutter upgrade
flutter doctor
```

### خطأ: Keystore not found
```
تأكد من المسار في android/key.properties
```

### خطأ: Google Apps Script 403
```
تأكد أن WebApp منشور بـ "Anyone can access"
```

---

## 📊 متطلبات الجهاز

| المتطلب | الحد الأدنى |
|---------|------------|
| Android | 5.0 (API 21) |
| RAM | 2 GB |
| Storage | 50 MB |
| Internet | مطلوب للمزامنة (يعمل offline مؤقتاً) |

---

## 🔐 الأمان

- جميع الطلبات تحتوي على `secret` key
- HTTPS إجباري (Google Apps Script)
- كلمات المرور مشفرة على الـ server
- Keystore محمية ومشفرة في Codemagic
- لا يُحفظ أي secret في الكود المصدري
