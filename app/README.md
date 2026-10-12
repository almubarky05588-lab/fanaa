# فناء — تطبيق Flutter

تطبيق واحد بتجربتين مفصولتين (عميل / تاجر) يُوجَّه المستخدم بينهما حسب دوره بعد تسجيل الدخول.

## الإعداد المحلي (مرة واحدة)

```bash
# 1) أنشئ مشروع Flutter بنفس الاسم لتوليد مجلدات android/ و ios/
flutter create --org sa.fenaa --project-name fenaa fenaa_bootstrap

# 2) انسخ المجلدين المولَّدين إلى هذا المجلد
cp -r fenaa_bootstrap/android fenaa_bootstrap/ios ./
rm -rf fenaa_bootstrap

# 3) ثبّت الحزم
flutter pub get
```

## مفاتيح خرائط قوقل

- **Android**: `android/app/src/main/AndroidManifest.xml` داخل `<application>`:
  `<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_KEY"/>`
- **iOS**: `ios/Runner/AppDelegate.swift`: `GMSServices.provideAPIKey("YOUR_KEY")`

## الأذونات

- **iOS** `ios/Runner/Info.plist`: `NSLocationWhenInUseUsageDescription`, `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`
- **Android** `AndroidManifest.xml`: `ACCESS_FINE_LOCATION`, `CAMERA`

## التشغيل

```bash
flutter run --dart-define=SUPABASE_URL=https://kzeawenrpvkfmeslxylz.supabase.co \
            --dart-define=SUPABASE_KEY=sb_publishable_XT_5L19jAeOu-jOa6Ag61A_Sv1MgoSX
```

## البنية

```
lib/
  core/        الثيم والتوكنز والموجّه والأدوات المشتركة
  data/        النماذج والمستودعات (Supabase)
  features/
    auth/      اختيار الحساب، الدخول بالجوال، OTP
    customer/  الرئيسية، المتاجر، المنتج، السلة، الطلب، الدفع، التتبع، الفاتورة، الحساب
    merchant/  اللوحة، الطلبات، المنتجات، المحفظة، الإعدادات
```
