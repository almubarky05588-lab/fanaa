#!/usr/bin/env bash
# بناء فناء لـiOS ورفعه إلى TestFlight — يُستدعى من .github/workflows/testflight.yml
# كل المنطق هنا حتى يُعدَّل بدون المساس بملف الـworkflow.
set -euo pipefail
cd "$(dirname "$0")/.."   # app/

step() { echo; echo "==================== $* ===================="; }

step "Xcode"
XC=$(ls -d /Applications/Xcode_26* 2>/dev/null | sort -V | tail -1 || true)
if [ -n "$XC" ]; then sudo xcode-select -s "$XC/Contents/Developer"; fi
xcodebuild -version

step "الأسرار"
for v in MATCH_GIT_TOKEN MATCH_PASSWORD APP_STORE_CONNECT_KEY_ID APP_STORE_CONNECT_ISSUER_ID APP_STORE_CONNECT_KEY; do
  if [ -z "${!v:-}" ]; then echo "❌ السر $v غير موجود"; exit 1; fi
  echo "✅ $v"
done
TOKEN=$(printf '%s' "$MATCH_GIT_TOKEN" | tr -d '[:space:]')
CODE=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $TOKEN" \
  https://api.github.com/repos/almubarky05588-lab/share-certs)
echo "share-certs: $CODE"
[ "$CODE" = "200" ] || { echo "❌ MATCH_GIT_TOKEN لا يصل لمستودع share-certs"; exit 1; }

step "Flutter"
flutter --version

step "مشروع iOS"
if [ ! -d ios/Runner ]; then
  flutter create --org sa.almubarky --project-name fenaa --platforms=ios .
  rm -f test/widget_test.dart
fi
ls ios

step "رقم البناء"
export BUILD_NUMBER=$(( 100 + ${GITHUB_RUN_NUMBER:-1} ))
sed -i '' -E "s/^version: (.*)\+.*/version: \1+$BUILD_NUMBER/" pubspec.yaml
grep '^version:' pubspec.yaml

step "الأيقونة والحزم"
python3 -m pip install --quiet --break-system-packages pillow 2>/dev/null || python3 -m pip install --quiet --user pillow
python3 tool/make_icon.py assets/brand
flutter pub get
dart run flutter_launcher_icons

step "تحليل الكود"
flutter analyze --no-fatal-infos --no-fatal-warnings || { echo "❌ أخطاء في الكود — انظر أعلاه"; exit 1; }

step "تهيئة iOS"
flutter build ios --release --config-only --no-codesign

step "الأذونات والخرائط"
python3 tool/patch_ios.py ios

step "Pods"
(cd ios && pod install --repo-update)

step "fastlane"
gem install fastlane --no-document
cd ios
rm -rf fastlane && cp -R ../fastlane_ios fastlane
export MATCH_GIT_BASIC_AUTHORIZATION=$(printf '%s' "x-access-token:$TOKEN" | base64 | tr -d '[:space:]')
export FASTLANE_SKIP_UPDATE_CHECK=true
export FASTLANE_HIDE_CHANGELOG=true
fastlane beta

step "✅ اكتمل — النسخة مرفوعة إلى TestFlight (رقم $BUILD_NUMBER)"
