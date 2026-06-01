# Java -> React/JS migration rules

Loaded by `react-migrator` per unit. These are translation contracts,
not suggestions. Preserve behavior; do not invent features.

## Mapping table

| Java / legacy unit            | React / JS target                         |
|-------------------------------|-------------------------------------------|
| JSP / JSF / Stripes view      | React function component (.tsx) + hooks    |
| Servlet / Action / Controller | API route handler (server) + fetch in UI   |
| Form bean / DTO / POJO        | TypeScript type/interface + zod schema     |
| Service / Manager class       | JS service module (pure functions)         |
| Taglib / EL expression        | JSX expression / component                 |
| Session-scoped state          | server session + client state (no secrets) |
| Server-side validation        | KEEP server-side; mirror in client for UX  |
| `web.xml` / filter chain      | middleware (auth, CSRF, headers)           |

## Hard rules

1. PRESERVE behavior and contracts. The migrated unit must pass the
   same logical tests as the original. If the Java unit had a test,
   port it; if not, write one that pins current behavior.
2. TYPES FIRST. Every DTO/bean becomes an explicit TypeScript type
   plus a runtime validator (zod or equivalent) at every trust
   boundary. No `any` on data crossing client<->server.
3. SECURITY-PRESERVING by construction (see security-rubric.md):
   - Authorization stays server-side. A client component never
     decides access; it only reflects a server decision.
   - Never embed secrets, keys, or DB connection details in code
     shipped to the browser.
   - Encode all output; never `dangerouslySetInnerHTML` untrusted
     data.
   - Preserve CSRF tokens on state-changing requests.
4. NO NEW DEPENDENCIES without flagging. If a translation needs a
   package, name it in the receipt for the security panel to vet;
   do not silently add unpinned deps.
5. SMALL UNITS. One Java unit -> one cohesive module/component. Do
   not bundle unrelated units; do not refactor neighbors.
6. STRUCTURED RECEIPT. Return what you changed, the new file paths,
   any new dependency requested, and any behavior you could not
   prove equivalent (so the synth + security panel can focus there).

## Migrator receipt schema

```
{ "unit": "<id>",
  "produced": [ "<path>", ... ],
  "test": "<path or 'ported:<orig>'>",
  "new_deps": [ { "name","version","why" } ],
  "unproven": [ "<behavior not yet covered by a test>" ],
  "notes": "..." }
```
