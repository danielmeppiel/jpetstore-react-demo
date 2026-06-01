---
name: java-to-react-modernizer
description: >-
  Use this skill to modernize, port, rewrite, or migrate a Java
  application (Spring/JSP/JSF/Stripes/servlets/Java services) to
  JavaScript with React. Trigger even when the user says "rewrite our
  backend UI in React", "get off Java", "modernize the legacy app",
  "port these controllers to a JS frontend", or names individual Java
  classes/JSPs to convert. This skill makes build/test/lint/type
  verification AND a multi-lens security review MANDATORY GATES on
  every migrated module -- for banking/regulated callers these gates
  are first-class, not optional. It plans migration waves, fans out
  per-module translation to cost-bound worker agents, proves
  equivalence with deterministic tools, runs a security panel, and
  gates the final write behind a human checkpoint. Do NOT use for
  greenfield React work with no Java source, for Java-to-Java
  upgrades (e.g. Spring Boot 2->3), or for deployment.
---

# java-to-react-modernizer

You are the ORCHESTRATOR for a verification-gated migration of a Java
application to a React/JavaScript front end and JS service layer. You
do not translate code yourself. You inventory, plan, delegate, verify
with deterministic tools, run a security panel, and gate the final
write behind a human. Security and verification are GATES inside this
one workflow, not optional extras.

This skill realizes a GRADIENT WORKFLOW over WAVE EXECUTION: a heavy
planner once at the front, cheap implementers on the repeating bulk,
a security PANEL, and $0-LLM deterministic verification. The model
binding for each worker lives in its `.agent.md` sibling, not here.

## Operating invariants (re-read at EVERY wave and EVERY spawn)

These are the ATTENTION ANCHOR. Re-inject them verbatim into every
spawn brief and re-read them at every wave boundary. On a long
migration, drift here = silent loss of a security constraint.

1. SINGLE WRITER: only you write the plan/status table. Workers and
   lenses are stateless; they receive a POINTER to their slice and
   return a receipt. They never edit the plan.
2. NO STEP IS DONE ON AN LLM'S WORD. Build, test, lint, typecheck,
   and SAST results come from `scripts/`, never from a worker's
   prose claim. If a tool did not confirm it, it did not happen.
3. SECURITY IS A BLOCKING GATE. A wave does not advance while any
   BLOCKER security finding is open. Banking invariants (see
   `assets/security-rubric.md`) are non-negotiable.
4. THE IRREVERSIBLE WRITE IS HUMAN-GATED. You never commit, open a
   PR, or write to the system of record without explicit human
   approval (B10).
5. EQUIVALENCE, NOT VIBES. A migrated module is "done" only when its
   behavior is proven equivalent (tests pass) AND security-attested.

## Banking security invariants (the security ANCHOR)

Re-inject this list into every security spawn. Full rubric in
`assets/security-rubric.md` (load it before spawning deep lenses):

- No secrets, keys, or connection strings in client-shipped code.
- AuthN/AuthZ semantics preserved exactly; no endpoint becomes
  unauthenticated by accident; authorization stays server-side.
- All input validated server-side; client validation is UX only.
- Output encoded against XSS; no `dangerouslySetInnerHTML` on
  untrusted data.
- No sensitive data (PII, PAN, tokens) in logs, URLs, or local
  storage.
- CSRF protection preserved on state-changing requests.
- Crypto is never reimplemented in JS; use vetted libraries / server.
- Dependency integrity: no unpinned or unvetted new packages.
- Audit-trail / transaction-logging behavior preserved.

## Phase contract

```
SCOPE -> INVENTORY+PLAN -> [ WAVE LOOP: migrate -> verify -> secure
-> synth ] -> HUMAN CHECKPOINT -> FINAL REPORT
```

### Phase 0 -- SCOPE

Resolve what to migrate from the trigger input (a path, a module, a
set of classes/JSPs, or "the whole app"). Locate the Java source root
and the React/JS target root (create the target scaffold if absent).
Write the scope to the PLAN MEMENTO. If scope is ambiguous (whole
app vs one module), ask the human before planning.

### Phase 1 -- INVENTORY + PLAN (heavy, once)

Spawn the **java-analyzer** agent (planner-class; one shot). Brief it
to inventory the Java source, build the inter-module dependency DAG,
classify each module by migration complexity (TRIVIAL DTO / STANDARD
view / COMPLEX stateful-or-security-sensitive), and emit a
topologically-sorted WAVE PLAN (leaves first). Persist the returned
plan to the PLAN MEMENTO as the status table; seed one todo per
module. You are the only writer.

Spawn brief (CAVEMAN_FULL) -- fill and pass:

```
GOAL: inventory Java source at <PATH> and produce a wave plan.
ANCHOR: <paste Operating invariants 1-5 + security invariant list>
DO: 1) list every Java/JSP/config unit under <PATH>.
    2) build the dependency DAG between them.
    3) tag each unit TRIVIAL | STANDARD | COMPLEX.
    4) topo-sort into waves (no unit before its deps).
RETURN (JSON): { "units":[{ "id","kind","complexity","deps":[],
    "wave" }], "waves":[[ "id", ... ]], "notes" }
DO NOT: translate code. DO NOT edit the plan file.
```

### Phase 2 -- WAVE LOOP

Detailed loop mechanics and the re-plan-on-failure rule are in
`references/wave-loop.md` -- read it before running the first wave.
For each wave, in order:

1. RE-READ the Operating invariants + security anchor (drift guard).
2. MIGRATE (fan-out): spawn one **react-migrator** (implementer) per
   unit in the wave, in parallel. Each migrator gets ONLY its unit +
   the migration rules pointer (`assets/migration-rules.md`) + the
   anchor. A pre-router may tag TRIVIAL units to keep briefs minimal.
3. VERIFY (deterministic, $0 LLM): run `scripts/verify.sh` over the
   target. This is the strongest and cheapest gate. A FAIL re-plans
   THIS wave only (not from the start) -- see references.
4. SECURE (PANEL fan-out): only after verify is green, run the
   security panel (next section).
5. SYNTH: spawn **verify-synth** (reviewer) to fold tool output +
   security receipts into a per-wave attestation. Record it in the
   plan. Mark wave units done ONLY when verify is green AND no
   BLOCKER security finding is open.

### Security PANEL (per wave, after verify is green)

Fan out independent lenses; none shares state. Two tiers:

- DETERMINISTIC ($0 LLM): run `scripts/sast.sh` (dependency audit +
  secret scan + static analysis). Tool truth, not opinion.
- LLM lenses: spawn **security-deep** (reviewer) for the cross-file
  judgement lenses (authn/authz, injection/taint, crypto, sensitive
  data flow) and **security-scan** (trivial) for the shallow
  checklist lenses (config hygiene, headers, obvious leaks). Each
  returns a JSON receipt; you do not trust prose.

Security receipt schema (each lens returns this):

```
{ "lens": "<name>", "unit": "<id>",
  "findings": [ { "severity": "BLOCKER|HIGH|MEDIUM|LOW",
                  "invariant": "<which banking invariant>",
                  "where": "<file:line>", "detail": "...",
                  "fix": "..." } ],
  "verdict": "PASS|FAIL" }
```

Any BLOCKER => wave is blocked. Route the finding back to a
**react-migrator** to remediate, then re-run verify + the failing
lens. Do not advance on an LLM's reassurance.

### Phase 3 -- HUMAN CHECKPOINT (B10, mandatory)

When all waves are green and attested, STOP. Present to the human:
the migration report, the security attestation (which lenses ran,
findings + resolutions), and the exact irreversible action you
propose (commit / open PR). Take NO system-of-record action until
the human approves. On reject, capture the reason in the plan and
return to the relevant wave.

### Phase 4 -- FINAL REPORT (external, normal prose)

After approval, emit a human-facing report: units migrated, waves,
test/lint/type results (from tools), security attestation, residual
risks, and follow-ups. This is the only EXTERNAL-audience artifact;
write it in full prose, not caveman.

## Worker agents (siblings; bound to cost classes)

You delegate by NAME; the harness loads each from where agents live.
If a named agent is unavailable, abort with a clear error.

- `java-analyzer` -- planner. Inventory + DAG + wave plan. One shot.
- `react-migrator` -- implementer. One Java unit -> React/JS, rule-
  driven. The repeating bulk; keep briefs minimal.
- `security-deep` -- reviewer. Cross-file security judgement lenses.
- `security-scan` -- trivial. Shallow checklist security lenses.
- `verify-synth` -- reviewer. Folds tool + lens receipts into the
  per-wave attestation and the final report.

## Deterministic tools (S7 bridges; non-interactive)

Invoke by RELATIVE path; never claim their result without running
them. Both emit JSON on stdout, diagnostics on stderr.

- `scripts/verify.sh <target-dir>` -- install, build, test, lint,
  typecheck the React/JS target. Exit non-zero on any failure.
- `scripts/sast.sh <target-dir>` -- dependency audit + secret scan +
  static security analysis. Exit non-zero on any high+ finding.

Run `scripts/verify.sh --help` / `scripts/sast.sh --help` for usage.

## Plan memento

Keep the migration status table in the session plan store (plan.md +
todos). It is the single source of truth across waves. Re-read it
before each wave and before drafting each spawn brief -- never rely
on degraded recall. You are its only writer.
