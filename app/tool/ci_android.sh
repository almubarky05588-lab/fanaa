#!/usr/bin/env bash
# بناء فناء لأندرويد (APK موقّع) — يُستدعى من .github/workflows/android.yml
set -euo pipefail
cd "$(dirname "$0")/.."   # app/

step() { echo; echo "==================== $* ===================="; }

step "Flutter"
flutter --version

step "مشروع أندرويد"
if [ ! -d android/app ]; then
  flutter create --org sa.almubarky --project-name fenaa --platforms=android . > /tmp/flutter_create.log
  tail -3 /tmp/flutter_create.log
  rm -f test/widget_test.dart
fi

step "تحويلات الكود (codemods)"
if ls tool/codemods/pending/*.py >/dev/null 2>&1; then
  for f in tool/codemods/pending/*.py; do echo "▶ $f"; python3 "$f" .; done
  touch /tmp/codemods_applied
else
  echo "لا توجد تحويلات معلّقة"
fi

step "رقم النسخة"
export BUILD_NUMBER=$(( 1000 + ${GITHUB_RUN_NUMBER:-1} ))
sed -i -E "s/^version: (.*)\+.*/version: \1+$BUILD_NUMBER/" pubspec.yaml
grep '^version:' pubspec.yaml

step "الأيقونة والحزم"
python3 -m pip install --quiet pillow 2>/dev/null || python3 -m pip install --quiet --break-system-packages pillow
python3 tool/make_icon.py assets/brand
sed -i 's/^  android: false/  android: true/' pubspec.yaml
flutter pub get > /tmp/pub.log 2>&1 || { cat /tmp/pub.log; exit 1; }
tail -3 /tmp/pub.log
dart run flutter_launcher_icons | tail -3

step "تحليل الكود"
flutter analyze --no-fatal-infos --no-fatal-warnings > /tmp/analyze.log 2>&1 || { cat /tmp/analyze.log; echo "❌ أخطاء في الكود"; exit 1; }
tail -1 /tmp/analyze.log

step "تجهيز أندرويد"
python3 tool/patch_android.py android

step "التوقيع"
if [ -n "${ANDROID_SIGNING:-}" ]; then
  PW="${ANDROID_SIGNING%%:*}"
  printf '%s' "${ANDROID_SIGNING#*:}" | base64 -d > android/app/fenaa.p12
  printf 'storeFile=fenaa.p12\nstorePassword=%s\nkeyAlias=fenaa\nkeyPassword=%s\n' "$PW" "$PW" > android/key.properties
  echo "✅ توقيع فناء الدائم"
else
  echo "⚠️ ANDROID_SIGNING غير موجود — توقيع مؤقت (لن تُثبَّت التحديثات فوق هذه النسخة)"
fi

step "بناء APK"
flutter build apk --release --build-number="$BUILD_NUMBER"
mkdir -p /tmp/out && cp build/app/outputs/flutter-apk/app-release.apk /tmp/out/fenaa.apk
ls -lh /tmp/out/fenaa.apk

step "✅ اكتمل — نسخة أندرويد $BUILD_NUMBER"
