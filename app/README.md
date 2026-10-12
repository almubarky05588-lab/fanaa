# فناء — تطبيق Flutter

تطبيق واحد بتجربتين مفصولتين (عميل / تاجر) يُوجَّه المستخدم بينهما حسب دوره بعد تسجيل الدخول.
مبني مطابقًا لتصاميم Figma (التوكنز في `lib/core/theme/tokens.dart` مستخرجة حرفيًا من الملف).

## الإعداد المحلي (مرة واحدة)

```bash
cd app
# 1) توليد مجلدات المنصات — معرّف الحزمة sa.fenaa.app لأبل وأندرويد
flutter create --org sa.fenaa --project-name fenaa --platforms=ios,android .
# 2) الحزم
flutter pub get
```

> `flutter create .` في مجلد موجود يضيف `android/` و `ios/` فقط ولا يلمس `lib/`.

## إعدادات لازمة لكل منصة

### iOS — `ios/Runner/Info.plist`

```xml
<key>CFBundleDisplayName</key><string>فناء</string>
<key>NSLocationWhenInUseUsageDescription</key><string>نستخدم موقعك لعرض المشاتل القريبة وتحديد عنوان التوصيل</string>
<key>NSCameraUsageDescription</key><string>لتصوير المنتجات</string>
<key>NSPhotoLibraryUsageDescription</key><string>لاختيار صور المنتجات</string>
<key>LSApplicationQueriesSchemes</key><array><string>tel</string><string>https</string></array>
```

`ios/Runner/AppDelegate.swift` — مفتاح خرائط قوقل:

```swift
import GoogleMaps
// داخل application(_:didFinishLaunchingWithOptions:)
GMSServices.provideAPIKey("YOUR_IOS_MAPS_KEY")
```

`ios/Podfile`: `platform :ios, '14.0'`

### Android — `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>

<application android:label="فناء" ...>
  <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_ANDROID_MAPS_KEY"/>
</application>

<queries>
  <intent><action android:name="android.intent.action.DIAL"/></intent>
  <intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent>
</queries>
```

`android/app/build.gradle`: `minSdkVersion 23`

## Supabase

- المشروع: `kzeawenrpvkfmeslxylz` (فرانكفورت)
- **تسجيل الدخول بالجوال**: لوحة Supabase ← Authentication ← Providers ← **Phone** ← فعّل واربط مزوّد SMS (Twilio / MessageBird / Vonage).
  للاختبار بدون SMS: أضف أرقامًا تجريبية في **Test phone numbers** برمز ثابت.

## التشغيل

```bash
flutter run
```

## النشر

```bash
flutter build appbundle --release   # Google Play
flutter build ipa --release         # App Store (يتطلب Xcode)
```

## البنية

```
lib/
  core/        الثيم والتوكنز، الموجّه، المكوّنات المشتركة، الموقع
  data/        النماذج والمستودعات (Supabase)
  features/
    auth/      01 اختيار الحساب • 02/14 الدخول بالجوال • 02b/14b رمز التحقق
    customer/  03 الرئيسية • 04 المتاجر • 05 المتجر • 07 الخريطة • 08 المنتج • 09 السلة
               10 إتمام الطلب • 11 الدفع • 11b النجاح • 11c البطاقة • 12 التتبع
               12b الفاتورة • 13 حسابي • العناوين • طلباتي
    merchant/  إنشاء المتجر • 15 اللوحة • 16 الطلبات • 17 تفاصيل الطلب • 18 المنتجات
               19 إضافة منتج • 20 المحفظة • 21 الإعدادات
```

## متبقٍّ قبل الإطلاق

- ربط بوابة الدفع (Moyasar) عبر Edge Function + webhook ← `mark_order_paid`
- مزوّد SMS للـOTP
- مفاتيح Google Maps (iOS + Android)
- إشعارات Push (Firebase Cloud Messaging)
