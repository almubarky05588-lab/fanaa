#!/usr/bin/env bash
# بناء فناء لـiOS ورفعه إلى TestFlight — يُستدعى من .github/workflows/testflight.yml
set -euo pipefail
cd "$(dirname "$0")/.."   # app/
APP_DIR=$(pwd)

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

step "fastlane + تجهيز حساب Apple"
gem install fastlane --no-document --silent
export FASTLANE_SKIP_UPDATE_CHECK=true FASTLANE_HIDE_CHANGELOG=true FASTLANE_OPT_OUT_USAGE=YES
PREP=/tmp/fl-prepare
rm -rf "$PREP" && mkdir -p "$PREP" && cp -R fastlane_ios "$PREP/fastlane"
(cd "$PREP" && fastlane prepare)

step "Flutter"
flutter --version

step "مشروع iOS"
if [ ! -d ios/Runner ]; then
  flutter create --org sa.almubarky --project-name fenaa --platforms=ios . > /tmp/flutter_create.log
  tail -3 /tmp/flutter_create.log
  rm -f test/widget_test.dart
fi
ls ios

step "تحويلات الكود (codemods)"
if ls tool/codemods/pending/*.py >/dev/null 2>&1; then
  for f in tool/codemods/pending/*.py; do echo "▶ $f"; python3 "$f" .; done
  touch /tmp/codemods_applied
else
  echo "لا توجد تحويلات معلّقة"
fi

step "رقم البناء"
export BUILD_NUMBER=$(( 100 + ${GITHUB_RUN_NUMBER:-1} ))
sed -i '' -E "s/^version: (.*)\+.*/version: \1+$BUILD_NUMBER/" pubspec.yaml
grep '^version:' pubspec.yaml

step "الأيقونة والحزم"
python3 -m pip install --quiet --break-system-packages pillow 2>/dev/null || python3 -m pip install --quiet --user pillow
python3 tool/make_icon.py assets/brand
flutter pub get > /tmp/pub.log 2>&1 || { cat /tmp/pub.log; exit 1; }
tail -3 /tmp/pub.log
dart run flutter_launcher_icons | tail -3

step "تحليل الكود"
flutter analyze --no-fatal-infos --no-fatal-warnings > /tmp/analyze.log 2>&1 || { cat /tmp/analyze.log; echo "❌ أخطاء في الكود"; exit 1; }
grep -E "error|warning" /tmp/analyze.log || true
tail -1 /tmp/analyze.log

step "تهيئة iOS"
flutter build ios --release --config-only --no-codesign

step "الأذونات والخرائط"
python3 tool/patch_ios.py ios

step "Pods"
(cd ios && pod install --repo-update)

step "البناء والرفع"
cd ios
rm -rf fastlane && cp -R ../fastlane_ios fastlane
export MATCH_GIT_BASIC_AUTHORIZATION=$(printf '%s' "x-access-token:$TOKEN" | base64 | tr -d '[:space:]')
fastlane beta

step "✅ اكتمل — النسخة مرفوعة إلى TestFlight (رقم $BUILD_NUMBER)"
