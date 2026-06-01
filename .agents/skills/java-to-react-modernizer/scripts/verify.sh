#!/usr/bin/env bash
# verify.sh -- deterministic build/test/lint/typecheck gate (S7 bridge).
# Non-interactive. Emits a JSON summary on stdout, diagnostics on stderr.
# Exit 0 only if every present stage passed; non-zero otherwise.
#
# Usage: verify.sh <target-dir>
#        verify.sh --help
#
# Stages are auto-detected from package.json scripts; missing stages
# are reported as "skipped" (not failed). This is the strongest and
# cheapest verification gate -- prefer it over any LLM "looks correct".

set -u

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

TARGET="${1:-.}"
cd "$TARGET" 2>/dev/null || { echo "{\"error\":\"no such dir: $TARGET\"}"; exit 2; }

if [ ! -f package.json ]; then
  echo "{\"error\":\"no package.json in $TARGET\",\"hint\":\"scaffold the React target first\"}"
  exit 2
fi

run_stage() {
  # $1 = stage name, $2 = npm script name
  if node -e "process.exit(require('./package.json').scripts?.['$2']?0:1)" 2>/dev/null; then
    if npm run "$2" --silent 1>&2; then echo "pass"; else echo "fail"; fi
  else
    echo "skipped"
  fi
}

echo "[verify] installing deps..." 1>&2
if [ -f package-lock.json ]; then npm ci 1>&2 || npm install 1>&2; else npm install 1>&2; fi
INSTALL=$?

BUILD=$(run_stage build build)
TEST=$(run_stage test test)
LINT=$(run_stage lint lint)
TYPECHECK=$(run_stage typecheck typecheck)
[ "$TYPECHECK" = "skipped" ] && TYPECHECK=$(run_stage typecheck "type-check")

FAIL=0
for s in "$BUILD" "$TEST" "$LINT" "$TYPECHECK"; do
  [ "$s" = "fail" ] && FAIL=1
done
[ "$INSTALL" -ne 0 ] && FAIL=1

printf '{"install":%s,"build":"%s","test":"%s","lint":"%s","typecheck":"%s","ok":%s}\n' \
  "$([ "$INSTALL" -eq 0 ] && echo true || echo false)" \
  "$BUILD" "$TEST" "$LINT" "$TYPECHECK" \
  "$([ "$FAIL" -eq 0 ] && echo true || echo false)"

exit "$FAIL"
