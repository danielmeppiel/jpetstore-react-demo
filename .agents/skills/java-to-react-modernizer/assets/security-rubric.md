# Security rubric -- banking / regulated (OWASP-aligned)

Loaded before spawning `security-deep`. The shallow lenses
(`security-scan`) use the CHECKLIST section; the deep lenses use the
JUDGEMENT section. Every finding maps to one invariant below and
carries a severity.

## Banking invariants (the non-negotiables)

I1 SECRETS: no secrets, API keys, private keys, or connection
   strings in any client-shipped bundle. (BLOCKER on hit.)
I2 AUTHN: no endpoint or route becomes unauthenticated by the
   migration. Session/token handling preserved. (BLOCKER.)
I3 AUTHZ: authorization decisions stay server-side; the client only
   reflects them. No client-only access control. (BLOCKER.)
I4 INPUT VALIDATION: every input validated server-side; client
   validation is UX only and never the trust boundary. (HIGH+.)
I5 OUTPUT ENCODING / XSS: all output encoded; no
   `dangerouslySetInnerHTML` on untrusted data. (BLOCKER on hit.)
I6 SENSITIVE DATA: no PII/PAN/tokens in logs, URLs, query strings,
   or browser storage. (HIGH+.)
I7 CSRF: state-changing requests carry CSRF protection. (HIGH+.)
I8 CRYPTO: no hand-rolled crypto in JS; vetted libs / server only.
   (BLOCKER on reimplementation.)
I9 DEPENDENCIES: no unpinned/unvetted new packages; integrity
   preserved. (HIGH+.)
I10 AUDIT: transaction/audit logging behavior preserved. (HIGH.)

## JUDGEMENT lenses (security-deep, reviewer-class, cross-file)

- AUTH FLOW: trace each migrated route to its auth/authz check.
  Flag any path that reaches a protected action without a
  server-side check (I2/I3).
- INJECTION / TAINT: follow untrusted input from entry to sink
  (DB query, command, HTML, redirect). Flag unparameterized or
  unencoded sinks (I4/I5).
- CRYPTO + SECRET FLOW: find any key material or crypto operation;
  confirm it did not move client-side (I1/I8).
- SENSITIVE DATA FLOW: trace PII/financial fields to logs, URLs,
  storage (I6).

## CHECKLIST lenses (security-scan, trivial-class, shallow)

- Hardcoded secret patterns in changed files (I1).
- `dangerouslySetInnerHTML` / `eval` / `innerHTML` usage (I5).
- Sensitive data in `console.log` / localStorage / sessionStorage
  (I6).
- New dependencies present and pinned (I9).
- Security headers / CSRF middleware present where expected (I7).

## Severity -> action

- BLOCKER: wave is blocked; remediate and re-scan before advancing.
- HIGH: must be resolved or explicitly accepted by the human at the
  B10 checkpoint, recorded with rationale.
- MEDIUM/LOW: record in the attestation; fix opportunistically.
