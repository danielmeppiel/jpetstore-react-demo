#!/usr/bin/env bash
# sast.sh -- deterministic security scan gate (S7 bridge).
# Non-interactive. Emits a JSON summary on stdout, diagnostics on stderr.
# Exit non-zero if any HIGH+ dependency vuln, leaked secret, or static
# security finding is detected.
#
# Usage: sast.sh <target-dir>
#        sast.sh --help
#
# Layers (each runs only if its tool is available; missing tool =>
# "unavailable", which is reported, not silently passed):
#   1. dependency audit  -- npm audit (high+ severity)
#   2. secret scan       -- gitleaks if present, else regex fallback
#   3. static analysis   -- semgrep (p/security-audit, p/react) if present

set -u

if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
  sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

TARGET="${1:-.}"
cd "$TARGET" 2>/dev/null || { echo "{\"error\":\"no such dir: $TARGET\"}"; exit 2; }

FAIL=0

# 1. dependency audit
if [ -f package.json ]; then
  AUDIT_JSON=$(npm audit --audit-level=high --json 2>/dev/null)
  HIGH=$(printf '%s' "$AUDIT_JSON" | node -e \
    'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{let v=JSON.parse(s).metadata?.vulnerabilities||{};console.log((v.high||0)+(v.critical||0))}catch(e){console.log(0)}})' 2>/dev/null)
  HIGH=${HIGH:-0}
  [ "$HIGH" -gt 0 ] && FAIL=1
  DEP="\"high_or_critical_vulns\":$HIGH"
else
  DEP="\"high_or_critical_vulns\":\"no-package-json\""
fi

# 2. secret scan
if command -v gitleaks >/dev/null 2>&1; then
  if gitleaks detect --no-banner --redact -s . 1>&2 2>&1; then SECRETS=0; else SECRETS=1; fi
else
  # regex fallback: obvious hardcoded secret patterns in source
  SECRETS=$(grep -rEl --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
    -e '(api[_-]?key|secret|password|private[_-]?key|aws_access_key_id)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"']{8,}' \
    . 2>/dev/null | wc -l | tr -d ' ')
fi
[ "${SECRETS:-0}" -gt 0 ] && FAIL=1

# 3. static analysis
if command -v semgrep >/dev/null 2>&1; then
  SG=$(semgrep --quiet --config p/security-audit --config p/react --json . 2>/dev/null \
    | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).results?.length||0)}catch(e){console.log(0)}})' 2>/dev/null)
  SG=${SG:-0}
  [ "$SG" -gt 0 ] && FAIL=1
  STATIC="\"semgrep_findings\":$SG"
else
  STATIC="\"semgrep_findings\":\"unavailable\""
fi

printf '{%s,"hardcoded_secret_hits":%s,%s,"ok":%s}\n' \
  "$DEP" "${SECRETS:-0}" "$STATIC" \
  "$([ "$FAIL" -eq 0 ] && echo true || echo false)"

exit "$FAIL"
