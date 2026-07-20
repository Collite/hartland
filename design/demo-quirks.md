# Hartland demo — quirks & gotchas

> Operational field notes for the Kantheon bilingual (US/CZ) TPC-DS pattern-answering
> demo on the live `hartland` cluster. Everything here **bit us** during bring-up
> (Stage 3.3, Jul 2026). Read this before touching the demo model, the read spine, or
> the golems — most of these fail *silently* or with a misleading symptom.
>
> Companion docs: [`demo-transcript.md`](./demo-transcript.md) (the narrative),
> [`plan-demo-build.md`](./plan-demo-build.md) (the build). Deployment truth is in
> `olymp/clusters/hartland/`.

---

## 0. The meta-quirk — golem masks query failures as "0 rows"

**The single most misleading behaviour.** When a golem turn's query node fails downstream
(translator rejection, empty result, RLS zeroing), golem reports the turn as
`STATUS_DONE` with `rowCount = 0` — **not** an error. So "0 rows" can mean *the query was
rejected*, not *the data is empty*. Every time a query "returns nothing," the real cause
is usually upstream and only visible in the **query-service log** (`ttr-server/query-*`),
where you'll find the actual `translator_rejected` / error message.

**Rule:** never trust a 0-row turn at face value. Pull the `ttr-query` log for the
`correlation_id` and read the real response before concluding anything about the data.

---

## 1. Model serving (veles / Ariadne)

### 1.1 Package filtering is by FILE PATH, not the declared `package`
veles classifies a model object into a package by looking for `/<package>/` **in the
object's source-file path** (`MetadataServiceImpl.kt`), *not* by the `package hartland`
declaration in the `.ttrm`. The git-source `id` is hardcoded `github-model`
(`application.conf`), so the clone lands at `/tmp/metadata-git/github-model/…` — whose
paths contain no `/hartland/` segment. Result: `GetModel(["hartland"])` matched **zero**
files even though ResolveArea returned `["hartland"]`.

**Fix (live):** `METADATA_GIT_CHECKOUT_DIR=/tmp/metadata-git/hartland` in
`olymp/clusters/hartland/apps/veles/values.yaml`, so every source path carries
`/hartland/`.

### 1.2 Two refreshes are needed after a model edit — veles AND golem
veles pulls the model from `Collite/hartland` (branch `demo-p2`, subdir `model/`) on a
poll interval; golem fetches the **ModelBundle from veles once at boot and caches it**.
So after you push a model change:

1. **veles**: force a re-fetch — `VelesService/Refresh {force:true}` over gRPC (see §5.3),
   or wait for the poll. Confirm with `ListQueries` (parse status flips to PARSED).
2. **golem**: `kubectl rollout restart deployment/golem-hartland -n kantheon` (and
   `-finance`). Without this, golem keeps serving the **stale** pattern SQL — which then
   fails at the translator and surfaces as §0's phantom "0 rows."

Forgetting step 2 cost hours: veles showed 15/15 parsed while golem still sent the old SQL.

### 1.3 Parse status is async
Right after `Refresh`, `ListQueries` may show `PARSE_STATUS_PENDING` for a few queries —
parsing runs on a background worker. Poll until it settles to PARSED/FAILED.

### 1.4 veles gRPC has no server reflection
`grpcurl -plaintext … list` fails ("server does not support the reflection API"). Drive it
with the proto file:
`-import-path tatrman-server/shared/proto/src/main/proto -import-path <plan-proto extracted dir> -proto org/tatrman/meta/v1/meta.proto`.
The extracted plan/common protos live under a `build/extracted-include-protos/*` dir.

---

## 2. Query SQL — Calcite acceptance (the translator, not Postgres)

Pattern-query `sourceText` is parsed by **Calcite** (via the translator), which is
**stricter than Postgres**. A query can run fine against `hartland_us` in `psql` and still
report `PARSE_STATUS_FAILED` in veles. Seen so far:

### 2.1 Reserved words as identifiers
A CTE named `returns` → `parse_failed: Encountered ", returns"`. `returns` is a Calcite
reserved word. Rename the CTE (we used `rets`). Watch for other reserved words used as
table/CTE/column aliases.

### 2.2 GROUP BY / ORDER BY on a SELECT alias
`SELECT (y - birth_year) AS buyer_age … GROUP BY buyer_age` → `Column 'buyer_age' not
found`. Postgres allows grouping by a select alias; **Calcite forbids it** (aliases aren't
in scope for GROUP BY per the SQL standard). Group by the underlying column or repeat the
expression.

### 2.3 Named-parameter placeholders are single-curly `{name}` ONLY
The translator's `ParameterBridge` recognises **only** `{name}`. Colon (`:name`), at-sign
(`@name`), and double-curly (`{{name}}`) are **not** rewritten and Calcite chokes on the
raw character. All 15 demo queries originally used `:colon` params → all failed. Convert
every parameter reference to `{brace}`.

### 2.4 A query can parse yet return 0 rows through the pipeline (translator quirk)
`buyer_age_profile` in a derived-table + `GROUP BY <subquery col>` form **parses** but
returns **0 rows** through the full pipeline (identical SQL returns rows in raw Postgres).
The `GROUP BY birth_year` form serves rows but the translator appears to **drop the
`birth_year IS NOT NULL` filter** (a null-age bucket leaks into the output). Net: this one
query has a form-dependent translator interaction. Left in the row-serving form with an
inline NOTE; tracked as a demo-polish follow-up (a real translator issue, not a query bug).

---

## 3. Parameters, schema, language (the golem → query-mcp → spine hops)

### 3.1 A resolved pattern's `source_language` is a MODEL property, not the LLM's guess
golem originally forwarded the LLM's `source_language` guess; SQL patterns went out tagged
`transdsl` → `translator_rejected: "Expect message object but got SELECT"`. Fixed in
`MiniPlanExecutor` (use `pq.sourceLanguage`, fall back to the node value only if
unspecified) **and** by pinning `"source_language": "sql"` in the golem prompts.

### 3.2 query-mcp must set `source_schema=DB` for physical SQL
Physical (DB-level) SQL was parsed against the **ER** schema by default →
`'ss_sold_date_sk' is a db object; parsed against er`. query-mcp now defaults
`source_schema=DB` when `source_language=SQL`.

### 3.3 Text parameters are case-sensitive (being fixed in the toolchain)
`WHERE channel = {channel}` with the utterance "…for **Marketplace**" binds
`channel="Marketplace"`, but the data literal is lowercase `'marketplace'` → 0 rows. This
is **not** golem's job to normalise — it belongs in the parametrized-query normalization
pass (ttr-translator). Fix: text-parameter equality is case-folded in the translator so
"Marketplace"/"marketplace"/"MARKETPLACE" all match. (Until the toolchain release lands,
phrase demo utterances with the lowercase channel token.)

---

## 4. Governance — the validator (ttr-validate / Argos)

### 4.1 TopN is a HARD ceiling and `row_limit` is (currently) dead-plumbing
The validator injects a `LIMIT` (TopN) into **every** plan. Its service default
(`VALIDATE_DEFAULT_TOP_N`) is an **authoritative ceiling**: `effectiveCap =
min(caller.default_top_n, serviceDefault)` — a caller can only ask for *fewer* rows, never
more. Separately, `row_limit` set by query-mcp on `RunRequest` is **never read** by any
downstream service, and `ttr-query` never forwards the caller's budget into
`ValidationOptions.default_top_n`. So today the *only* lever is the service-wide default.

The default `30` silently truncated the 72-row monthly series (→ 2024 months 1–10). Set
to **100** on hartland (`olymp/clusters/hartland/apps/validate/values.yaml`,
`VALIDATE_DEFAULT_TOP_N=100`) so full aggregate series render whole **and** a deliberately
larger query is *visibly* capped — the governance beat in the narrative.

The design fix (caller `row_limit` → `default_top_n`, requestor states the *want*, validator
decides the *get*) is tracked as **NEW-4** in
`project/server/design-corpus/implementation/tasks/backlog-row-limit-vs-topn.md`.

### 4.2 Helm `extraEnv` REPLACES, it does not merge
Overriding `extraEnv` in an olymp values file **drops** the chart's default env list. When
you add `VALIDATE_DEFAULT_TOP_N`, you must repeat the chart's `VELES_HOST`/`VELES_GRPC_PORT`
entries verbatim, or the validator loses its veles wiring.

---

## 5. Deployment & live-verification mechanics

### 5.1 Images must be multi-arch — the hartland node is amd64
Local builds are arm64; jib non-CI builds only the local arch. Prefix `CI=true` to force a
multi-arch (arm64+amd64) build, or the node can't pull. golem's jib is parameterised
(`-PimageRepo -PimageTag`); query-mcp's `to.image` is hardcoded (override with
`-Djib.to.image=…`).

### 5.2 Port-forwards die when the Bash call returns
A background `kubectl port-forward` started in one tool call is killed when that call ends.
Run the whole token-mint → turn → resume flow in a **single** shell invocation.

### 5.3 The live-turn recipe (Maya persona)
- **Token (ROPC):** realm `kantheon`, public client `iris` (directAccessGrants),
  `POST /realms/kantheon/protocol/openid-connect/token`,
  `grant_type=password&client_id=iris&username=maya&password=Hartland!2026&scope=openid`.
  Keycloak svc `auth-keycloak-keycloakx-http` (ns `auth`, port 80).
- **Turn:** `POST /v1/answer/sync` to `golem-hartland` (ns `kantheon`, port 7420), body
  `{"id","golemId":"golem-hartland","question"}`; caller derived from the bearer.
- **Clarifications:** param-fill asks **one parameter at a time**; resume via
  `POST /v1/resume {resume_token, free_text_answer}`. The resume token is nested at
  `envelopes[0].pendingClarification.resumeToken`. Result rows land in the envelope's
  `contentJson`; step counts in `stepRecords[].rowCount`.
- **veles Refresh:** `VelesService/Refresh {force:true}` (grpcurl, §1.4 for proto paths).

### 5.4 ArgoCD sync
The hartland apps auto-sync from olymp `master` (HEAD) + tatrman-server master. Force a
re-read with
`kubectl annotate application <app> -n argocd argocd.argoproj.io/refresh=hard --overwrite`.
A `extraEnv` change is a Deployment-spec change, so ArgoCD rolls the pod automatically.

### 5.5 Namespaces
Spine (veles, query, validate, translate, dispatch, workers, query-mcp) → `ttr-server`.
Golems + capabilities-mcp → `kantheon`. Data (CNPG `hartland_us`/`hartland_cz`) → `data`.
Keycloak → `auth`. golem→veles/query-mcp cross-ns, so those hosts must be FQDNs
(`veles.ttr-server`, `query-mcp.ttr-server`), not bare names.

---

## 6. Data shape (hartland_us / hartland_cz)

- Two databases: `hartland_us`, `hartland_cz` (worker connections `pg-hartland-us`,
  `pg-hartland-cz`; also a `pg-tpcds`).
- Channel literals in the demo SQL are **lowercase** (`'store'`, `'web'`, `'marketplace'`)
  — see §3.3.
- Sales span 2024–2025 in full (24 months × 3 channels = 72 monthly rows); returns span
  2021–2026. `customer.c_birth_year` has a meaningful NULL population (drives the
  buyer_age null-age bucket, §2.4).
