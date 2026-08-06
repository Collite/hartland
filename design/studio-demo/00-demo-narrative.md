# Studio demo — the narrative (draft v0)

> **The story input for the SD effort** (Tatrman Studio demo on the Hartland world). Sibling
> of [`../demo-transcript.md`](../demo-transcript.md) — same Hartland Stores setting, same
> personas, same data; a **different day and a different audience**. Where the Kantheon demo
> answers *"what happened?"* (agents, January, the meltdown found), this demo shows
> *"what do we do about it?"* (deterministic Studio apps, February, the plan). The final
> transcript is an SD-P5 deliverable; this draft fixes the arc, the beats, and every
> Requires line so the build phases have a target. **Naming register: FO-33/FO-30** —
> Tatrman Studio · the Studio shell · Studio Viewer / Modeler / Designer / Planner; on-stage
> vocabulary uses ONLY these names (internals keep technical names, never spoken).

## Setting

**Hartland Stores**, three weeks later — early **February 2026**. The January investigation
(the Kantheon demo) established the facts: Memphis DC dark for 17 weeks, Marketplace
−10.62% in the incident window, Web rerouted, Stores untouched. The board accepted the
post-mortem; now Finance wants the **FY 2026 plan** — with Marketplace *recovery* built in,
explicitly, defensibly. That is deterministic work: model it, compute it, plan it — the same
governed spine, no agent in the loop (PF invariant P-2).

**Cast:** *Maya Chen* (Senior Category Manager — now wearing her **planner** hat for her
categories) and *Dan Whitaker* (CFO — owns the planning **round**). Presenter: Bora.
One locale per delivery (BM-8 inherited): EN/`hartland_us` shown here; the CZ mirror
(Markéta/Tomáš over `hartland_cz`) is a straight translation, same numbers ×FX.

**On stage:** **Tatrman Studio** — one shell, one login (the same Keycloak realm and the
same personas as the Kantheon demo — deliberately: *same login, different kind of work*).
Launcher tiles: Viewer · Modeler · Designer · Planner. Substrate (never named): the merged
Designer (`@tatrman/designer` + `designer-authoring`), `ttr-designer-server` doors,
`:services:studio-planner` + `@tatrman/grid-core` on the `hartland_plan` store.

**The thread of the day:** *the model doesn't know what a "plan" is yet.* Beat M teaches it
(a plan cubelet, authored live). Beat D gives it eyes (plan-vs-actual program, authored,
validated, run, graduated). Beat P fills it (the FY26 round: spread, pin, preview,
check in). Close: every number traces — canvas → text → git; grid → entry record → round.

---

## Beat 0 — Cold open: one login, a different day

Bora logs in as **Maya** — the same "Log in with Keycloak" the audience saw in January —
and lands in the **Studio launcher**: four tiles.

> BORA: *"Same company, same login, same governed model. In January you watched agents
> investigate. Today nobody investigates anything — we know what happened. Today we plan.
> And planning is not a conversation; it's numbers you commit and defend. So today: no
> chat, no LLM anywhere on this stage. Everything you'll see is deterministic — and
> everything still explains itself."*

**Machinery:** Studio launcher (FO-P1) with Planner registered (A2-P5). Identity per the
⚑2 ruling: variant A runs dev-auth (maya/dan as distinct users) — the A-variant narration
speaks "one login" about the *platform* and the full Keycloak SSO beat is delivered
verbatim once the demo graduates to the hartland cluster (P4b), where the January realm
and personas are already live. **Requires:** launcher deployed with all four tiles; two
distinct user identities.

## Beat 1 — Studio Viewer: the model is the ground

Maya opens **Viewer** on the Hartland model: the md star — 7 cubelets around the conformed
dimensions (Product, Calendar, Customer, Store, DistributionCentre, Promotion,
ReturnReason). Drill into `marketplaceSales`; open the **member lineage** on
`revenue` (A1-W2): cubelet → er → db columns.

> BORA: *"This is the model the agents used in January — rendered, not summarized. Every
> measure walks back to the physical column. Notice what's NOT here: no `plan` anywhere.
> This model records what happened; it has no idea what *should* happen. Let's fix that —
> and let's fix it in front of you."*

**Machinery:** open-tier render (FO-4); lineage entry from the member detail panel.
**Requires:** hartland model loaded in the shell (Worker workspace, SD contracts §2);
member lineage live (A1-P2).

## Beat M — Studio Modeler: teach the model what a plan is

Same canvas, **Modeler** (the commercial authoring extension lights up — the doors appear;
Viewer-only builds simply don't have them, FO-21).

Maya authors, on canvas — via doors and ⌘K, never typing raw text:

1. `def dimension Version` — members `actual`, `plan-fy26` *(SD contracts §3 fixes the
   exact shape)*;
2. `def measure planRevenue` (Money, additive, sum);
3. `def cubelet revenuePlan { grain: [Channel, Product.categoryName, Calendar.month,
   Version], measures: [planRevenue] }` — **month × category × channel**, the grain
   planning actually happens at (not item×customer×day — that's recording grain, and
   the contrast is a spoken line).

Open the **TextDrawer**: the canonical TTR-M text the doors emitted, byte-identical,
diffable. Then the cameo: try to **remove** `revenue` — the removal flow refuses honestly,
naming its dependents (the three sales cubelets, the lexicon, the queries that read it).

> BORA: *"Two things just happened. One: the graph is a view — the artifact is text, in
> git, reviewable like any code. Two: the model defended itself. It didn't grey out a
> button; it told her exactly who depends on what she tried to break."*

**Machinery:** A1-W3 (doors, ⌘K, TextDrawer round-trip, remove-with-consequences); D-6
byte-identical emission. **Requires:** the plan-delta model change rehearsed + reversible
(demo-reset restores the pre-beat model state); the *committed* version of the delta is
what SD-P1 ships (the beat *re-enacts* it live — see architecture §4 "twice-authored").

## Beat D — Studio Designer: plan-vs-actual, authored and proven

Switch tile: **Designer** (TTR-P). Maya assembles `q.hartland.plan_vs_actual` on the
processing canvas: read `revenuePlan` (plan slice) + monthly actuals; join on
channel×category×month; derive `variance` and `variancePct`.

The A1-W4 loop, all four states visible on the AuthorPanel:

1. **author** — doors emit canonical TTR-P text (TextDrawer shows it);
2. **validate** — `ttrp/validate`; one *staged* mistake (e.g. a mistyped member) shows the
   problems strip, fixed live;
3. **preview-run** — the draft runs against Hartland data; the Arrow result lands in the
   ResultDrawer: FY25 actuals vs the (still half-empty) plan;
4. **graduate** — the program persists to the workspace; it appears in the **catalog**,
   deep-linkable.

> BORA: *"Author, validate, run, keep. The program she just drew is text — same review
> path as the model. And it ran against the real warehouse before she saved it. In January
> an agent wrote SQL in front of you; today an analyst drew a pipeline — same spine
> underneath, same provenance."*

**Machinery:** A1-W4 (ProcessingDoors, `ttrp/validate`, preview-run, graduate).
**Requires:** SD-P0 probe verdict on running draft TTR-P against live Postgres (A1-CAP-003
posture decides the beat variant — live-run [preferred] vs fixture-run with the narration
adjusted; see plan SD-⚑3).

## Beat P — Studio Planner: the FY26 round (the centerpiece)

Tile: **Planner**. The round **"FY 2026 Revenue Plan — Round 1"** is open (version
`plan-fy26` OPEN); form "Revenue plan by channel × category × month".

The loop, exactly as shipped by FO-A2:

1. **Open** the view read-only — FY25 actuals as reference rows, FY26 plan rows seeded
   at last year's shape. **"Start editing"** → check-out of Maya's slice (the Marketplace
   plane). Reservation is honest pessimism: *"cube data does not merge."*
2. **The headline gesture:** Maya types the FY26 **Marketplace total**: `$755M` (+10.5% —
   recovery to trend). The **spread** cascades down months × categories, honoring the
   seed's seasonal shape. Cells light with provenance.
3. **Pins:** the board is cautious about Q1 while the Memphis WMS post-mortem lands. Maya
   **pins Jan+Feb at conservative values** → re-types the total → the spread compensates
   *around* the pins (CL-β pin-sum + compensation; the op-chain inspector shows each
   cell's derivation chain).
4. **Block scale:** Electronics +12% for H2 (the win-back promo category) — one gesture
   over a block.
5. **Zero-base cameo:** a new category/DC combination has no history — seed-from-zero-base,
   explicit marks; *nothing spreads into cells that have no basis without saying so*.
6. **Preview & check-in:** the verdict chips — reservation ✓ · version OPEN ✓ · write
   allowed ✓ · zero-base ✓ — and the storage-grain expansion (old→new per assignment).
   **Check in** → the committed pass runs `revenuePlan-entry-apply`; a **PlannerEntryRecord**
   exists; pins re-pin at the new values.
7. **The contrast:** second browser profile — **Dan** opens the same form → *"checked out
   by Maya Chen"*, read-only. No merge dialog exists, on purpose. Maya **releases + marks
   done**; Dan's **round dashboard** flips her slice green; Dan adds the round note.
8. **The proof:** re-run Beat D's `plan_vs_actual` (or open its pinned result): the plan
   column is now *full*; variance-to-recovery visible per month.

> BORA: *"Watch what she never did: she never edited a database. She proposed a batch, the
> platform previewed exactly what would change at storage grain, and one deterministic
> program committed it — and left a record that will replay in an audit. The spreadsheet
> feel, without the spreadsheet lie."*

**Machinery:** A2-W1…W5 end-to-end (grid-core solver, grid shell, reservation, preview
door, commit door, entry record, drafts, form, round dashboard, done flag).
**Requires:** `hartland_plan` store seeded (SD-P1); planning form fixture; both personas;
demo-reset restoring seed + releasing reservations + reopening the version.

## Close — the funnel line

> BORA: *"One model. In January it answered questions in sentences. Today it took a plan —
> modeled live, computed live, committed with provenance. Same login, same governance, same
> git. That's the offering: the open Server renders and explains everything; the Studio is
> where your people *work* in it."* *(FO design.md §12, compressed.)*

## Satellites & pockets (if time)

- **Satellite T (text-first honesty):** open the graduated program / the plan-delta commit
  in VS Code — the same text the doors emitted; the open tier authors everything (P-1).
- **Satellite R (governance):** attempt check-in on a slice **outside** Maya's write scope
  → structured refusal (write-RLS verdict chip red). Requires a second scoped persona or a
  scoped form slice — SD-⚑4.
- **Pocket:** the Designer catalog deep-link pasted into a fresh tab → same program, same
  result (deep-link contract).

---

## Beat → build map (what each phase must deliver)

| Beat | Depends on | Built in |
|---|---|---|
| 0 login/launcher | launcher + SSO/dev-auth | SD-P4 (env), SD-P0 probe |
| 1 Viewer/lineage | hartland model in shell | SD-P1 (workspace), SD-P2 |
| M Modeler | plan-delta model change, rehearsed | SD-P1 (the delta), SD-P2 |
| D Designer | plan_vs_actual program + run posture | SD-P1 (program), SD-P2, SD-⚑3 |
| P Planner | hartland_plan store + seed + form + round | SD-P1 (data), SD-P3 |
| Close/satellites | all | SD-P5 (script, rehearsal) |
