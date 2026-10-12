#!/usr/bin/env bash
# ينشر سجل البناء في فرع ci-report حتى يُقرأ ويُصلح من المحادثة مباشرة.
# لا يفشل أبدًا — أي خطأ فيه يُتجاهل حتى لا يخفي خطأ البناء الأصلي.
set +e
STATUS="${1:-unknown}"
NAME="${2:-testflight}"
LOG="${CI_LOG:-/tmp/ci.log}"
REPO_URL="https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
DIR=/tmp/ci-report

rm -rf "$DIR"
if ! git clone -q --depth 1 --branch ci-report "$REPO_URL" "$DIR" 2>/dev/null; then
  mkdir -p "$DIR" && cd "$DIR" && git init -q && git checkout -q -b ci-report && git remote add origin "$REPO_URL"
fi
cd "$DIR" || exit 0
git config user.name "fenaa-ci"
git config user.email "ci@fenaa.local"

{
  echo "status: $STATUS"
  echo "run: ${GITHUB_RUN_NUMBER:-?} (${GITHUB_RUN_ID:-?})"
  echo "commit: ${GITHUB_SHA:-?}"
  date -u
  echo
  echo "==================== الأخطاء المباشرة ===================="
  grep -nE "❌|error:|Error:|ERROR|FAILED|Exception|Could not|\[!\]" "$LOG" 2>/dev/null | tail -n 60
  echo
  echo "==================== آخر السجل ===================="
  tail -n 400 "$LOG" 2>/dev/null
  echo
  echo "==================== أخطاء xcodebuild ===================="
  for f in "$HOME"/Library/Logs/gym/*.log; do
    [ -f "$f" ] && grep -nE "error:|ARCHIVE FAILED|PhaseScriptExecution" "$f" | tail -n 80
  done
} > "$NAME.txt" 2>&1

git add -A
git commit -q -m "$NAME #${GITHUB_RUN_NUMBER:-?} $STATUS" 2>/dev/null
git push -q origin ci-report 2>/dev/null || { git pull -q --rebase origin ci-report && git push -q origin ci-report; }
echo "📝 التقرير منشور في فرع ci-report/$NAME.txt"
exit 0
