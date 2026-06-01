# Wave loop mechanics

Load this before running the first wave. It expands Phase 2 of the
SKILL body.

## The loop

```
for wave in waves:            # topo order, leaves first
    re-read invariants + security anchor    # B8 drift guard
    fan-out react-migrator per unit in wave # parallel, fresh ctx
    fan-in
    verify = scripts/verify.sh target       # S7, $0 LLM
    if verify FAIL:
        go to RE-PLAN (this wave only)
    sast = scripts/sast.sh target           # S7, $0 LLM
    spawn security-deep + security-scan lenses (parallel)
    collect JSON receipts
    if any BLOCKER finding:
        go to REMEDIATE (this unit only)
    spawn verify-synth -> per-wave attestation
    mark wave units done in plan             # only you write
```

## RE-PLAN (verify failed)

Do NOT restart from wave 0. The failure is local to the units just
migrated. Steps:

1. Read the `scripts/verify.sh` JSON to find which unit(s) failed
   and why (compile error, failing test, type error, lint).
2. Re-spawn a `react-migrator` for ONLY the failing unit(s), passing
   the tool output as the brief (the error is the spec).
3. Re-run `scripts/verify.sh`. Loop until green or until the same
   unit fails 3 times -- then escalate to the human with the trace.

## REMEDIATE (security BLOCKER)

1. Route the finding (with its `where` + `fix`) to a `react-migrator`
   as a fix task. One finding, one minimal change.
2. Re-run `scripts/verify.sh` (a fix must not break behavior).
3. Re-run ONLY the lens that raised the BLOCKER.
4. Advance only when that lens returns PASS and verify is green.

## Why this shape is cheap

- The planner runs once; the bulk is implementer-class migrators.
- Verification is a deterministic script, not an LLM re-read -- the
  strongest gate is also the cheapest ($0 tokens).
- Re-plan is scoped to the failing unit, so a late failure does not
  re-pay for the whole wave.
- Shallow security lenses are trivial-class; only the genuinely
  cross-file lenses pay reviewer-class.
