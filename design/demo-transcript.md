# Kantheon capabilities demo — the transcript

> **This document is the design artifact** (Bora, 2026-07-09 · W-1): the demo *is* its
> transcript. No separate `design.md`/`detailed-design.md` exists; the architecture is
> Kantheon itself. Companion documents: the **control-room decision log**
> (`00-control-room.md` — every *why*), `05-d-ttrm-spec.md` (the hartland model + both
> Shems), `07-f-script.md` (presenter operations: timing boxes, fallbacks L0–L4, rehearsal
> ladder R0–R5), and **`olymp/clusters/hartland/plan-cluster.md`** (the demo-cluster plan).
> For /planning: every turn below carries a **Requires:** line; the rollup in Appendix A is
> the build checklist.
>
> **R0 frozen 2026-07-18** (Stage 1.6). All `⟨R0⟩` placeholders below are filled from
> `data/recon/R0.md` — the authoritative source if this transcript and R0.md ever drift.
> A Czech mirror of this transcript (CZ delivery) is Appendix C.

## Setting

**Hartland Stores** — Tennessee retailer; six stores across TN (HQ Nashville), nationwide
**Web** shop (hartland.com, fulfills from all five DCs with auto-rerouting), and a
**Marketplace** where third-party sellers sell through Hartland's platform and **Hartland
does the fulfillment** from five DCs — Memphis, Columbus, Dallas, Reno, Allentown — with the
Marketplace pipeline **pinned to its warehouse**. Annual revenue ≈ $2.1B (Stores $1.02B ·
Marketplace $726M · Web $365M).

**The authored ground truth** (seeded; C-3a): the **Memphis DC melts down late July 2025**
(weeks 31–47: inventory zero-streak; weeks 32–48: ~60% of Memphis-fulfilled Marketplace
lines lost, with matching returns removed; weeks 33–49: "Did not get it on time" skew on
surviving Memphis returns). Web reroutes around it; Stores untouched; everything else in the
data is genuinely flat — every wrong hypothesis dies on real evidence.

**Cast:** *Maya Chen*, Senior Category Manager (category P&L across all three channels) —
`maya@hartland.example`. *Dan Whitaker*, CFO — `cfo@hartland.example` (cameo). Presenter/actor:
Bora. Narrative present: a Monday morning, mid-January 2026 — "we just closed 2025" (spoken
only; all on-screen content is period-labeled, S-12).

**Agents on stage:** golem-hartland ("Hartland Analytics"), Pythia, Themis (invisible router),
Metis (via Pythia), Hebe, Iris; golem-hartland-finance ("Hartland Finance") — CFO-visible only.
Substrate (never named; visible only inside ⓘ→SQL): theseus→proteus→argos→kyklop→arges on
connection `pg-hartland`, `db=hartland`.

---

## Beat 1 — Cold open: the Monday briefing

Maya opens Iris. The inbox badge shows one item that **arrived overnight** — nobody asked
anything yet.

> **INBOX · "Monday channel health brief"** *(TurnOrigin.SCHEDULED — Hebe routine)*
>
> Markdown summary + KPI table + trend chart:
>
> | Channel | FY 2025 | vs 2024 | H2 2025 vs H2 2024 |
> |---|---|---|---|
> | Stores | $1,024.8M | +0.5% | +0.15% |
> | Web | $365.0M | −2.2% | −1.69% |
> | **Marketplace** | $683.4M | **−6.18%** | **−8.65%** |
>
> The incident's own 17-week window (wks 32–48, not calendar H2) is worse: **−10.62%** — the
> number the briefing actually leads with. Worst month: **November −12.33%** (2024 $119.1M →
> 2025 $104.4M). Chart: monthly Marketplace revenue 2024 vs 2025 —
> the autumn ramp visibly missing its step from August. Every block carries ⓘ.

BORA: *"Nobody wrote this. A routine Maya set up watches channel health every week, and this
week it flagged something: Marketplace — a nine-figure channel — double-digits down, half-year
on half-year. Let's find out why. Note: every number on this screen opens down to the SQL
that produced it. We'll use that."*

**Machinery:** Hebe scheduled turn → iris-bff (`TurnOrigin.SCHEDULED`) → inbox item; briefing
blocks rendered from `q.hartland.channel_revenue_yoy` (#2) + `q.hartland.channel_revenue_monthly` (#1).
**Requires:** Hebe P4 + routine fixture "Monday channel health brief" (fired pre-show); Iris P4
inbox; envelope-render; queries #1/#2 on `pg-hartland`.

---

## Beat 2 — Orient: conversational Q&A with Golem

**MAYA:** `How did Marketplace revenue develop in 2025?`

> Monthly line chart, Marketplace 2025: seasonal base Jan–Jul (~$40M/mo), the Aug–Oct 2.2×
> step **flattened**, November peak **−12.33% vs 2024's $119.1M** (2025: $104.4M). Table beneath. Chips:
> *by category* · *compare with 2024* · *only Q4* · **Investigate**.

BORA opens ⓘ on the chart → the SQL expander: the exact SQL, `db=hartland`, timestamp.
*"One input box. The platform classified the question, routed it to the right agent, compiled
it against a governed model of the warehouse, executed it — and here's the proof. Nothing on
this stage is a mock-up."*

**Machinery:** Themis PROCEDURAL → golem-hartland → **pattern plan** `q.hartland.channel_revenue_monthly`
(channel=Marketplace, 2025) → theseus.compile→…→arges → table+chart blocks + BlockProvenance.

**MAYA:** `Compare Web and Marketplace revenue, 2024 vs 2025`

> Grouped bars: Web $373.1M → $365.0M (−2.2%, within the canvas's natural ±2% noise);
> Marketplace $728.3M → $683.4M (**−6.18% FY**, all of it H2 — H1 is flat YoY).

BORA: *"So it's not e-commerce softness — Web is noise-level. Something is eating exactly
one channel."*

**Machinery:** pattern plan #1 two-channel cut (or #2); Stacks carry the channel filter.

**MAYA:** `Which categories drove the H2 2025 drop?`

> Ten categories (Books … Women), incident-window (wks 32–48) YoY bars: the drop is **spread
> across all ten, −7.3% to −13.7%** (Home lowest, Jewelry highest) — no category stands out
> as *the* cause.

BORA: *"Maya's a category manager — her reflex is 'which of my categories broke?' Answer:
all of them, evenly. That's the moment your mental model fails: a product problem hits
products. This hit a channel."*

**Machinery:** pattern plan `q.hartland.category_revenue` (#3).

**MAYA:** `What was the average order value on Marketplace vs Web in December 2025?`

> Small table: Marketplace AOV **$22,863/order** vs Web **$30,341/order** (December 2025) —
> both ~unchanged YoY (AOV isn't the story — order *volume* on Marketplace is).
> ⓘ shows **generated SQL** — plan source `free_sql`, visibly no prepared pattern.

BORA: *"That one is NOT in any playbook. The agent wrote that SQL itself, inside the same
governed model, and shows its work the same way. It's not a decision tree; it's an analyst."*

**Machinery:** Themis PROCEDURAL → golem-hartland → **free_sql** plan (confidence gate passes;
shape join+group within proven unparse space).

**MAYA:** `What did the slump cost us in profit?`

> Graceful gap: *profitability isn't part of the governed model* — offers revenue,
> quantities, returns instead.

BORA: *"And when it doesn't know, it says so. Profitability isn't modeled in this deployment
(deliberately — D-6a), so it won't invent a number. In a room full of AI demos, this is the
most important answer you'll see today."*

**Machinery:** model-level gap (no profit measures exist in the hartland TTR-M); GapKind
response. *(Baseline validates the exclusion: raw `net_profit` is dsdgen-negative — Stores
2025 = −$444M at line level.)*

**Requires (beat 2):** golem-hartland Shem + hartland model (19 entities); pattern plans
#1/#2/#3; free-SQL path + gate; D-6a exclusion enforced; chips (Filter/Project/Sort stacks);
ChartIntent→Vega-Lite; BlockProvenance everywhere.

---

## Beat 3 — Investigate: Pythia RCA (the centerpiece)

**MAYA:** clicks **Investigate** on the category answer.

> Pythia investigation opens: question restated *("Why did Marketplace revenue drop in
> H2 2025?")*, **budget meter visible**, and the **hypothesis-tree pane** — live.

BORA: *"A different kind of work, so the platform hands it to a different agent — an
investigator. Watch two things: the budget meter — this work has a visible cost, not a
runaway bill — and this pane: the investigator's actual working memory. Not a slide."*

**Machinery:** InvestigateChip → routing_hint re-route through Iris/Themis (never
Golem→Pythia direct); HandoffContext carries the conversation — nothing is re-asked.

The tree unfolds (evidence per branch; order may vary live, evidence is deterministic):

| Hypothesis | Evidence (query) | Verdict |
|---|---|---|
| Customers shifted to Web | #10 `customer_channel_overlap` + #1 Web trend | **dies** — overlap constant, Web flat/noise (S5 OFF: no uptick) |
| Demographics shifted | #12 `buyer_age_profile` | **dies** — buyer age flat at ~45.0, every channel every year |
| Promotions starved the channel | #13 `promo_share` | **dies** — promo linkage ~98–100%, dense as always |
| It's regional | #11 `revenue_by_customer_state` | **dies** — drop even across states |
| Fulfillment / operations | #6 `returns_by_reason`: **"Did not get it on time" spikes Q3–Q4 — 39.10% of surviving Memphis returns vs 2.87% baseline** → corroborated. #4 `marketplace_revenue_by_warehouse`: four DCs flat at $144.2M–$145.6M, **Memphis collapses −58.99% in wks 32–48** (FY: $102.8M, −29% vs peers). #8/#9 `warehouse_stockout_weeks` / `inventory_on_hand_series`: **17-week zero-on-hand streak, weeks 31–47/2025, Memphis only, 22.8% of item-weeks** (baseline zero-rate everywhere else: 0.09–0.10%) | **survives** |

> **CONCLUSION** *(hypothesis_id-linked provenance on every evidence block)*:
> *Memphis DC stopped fulfilling for ~17 weeks (late July – mid November 2025). Marketplace
> orders are warehouse-pinned, so its volume collapsed through the autumn ramp into the
> holiday peak; Web rerouted around it. Estimated H2 revenue impact: −$44.9M (calendar H2,
> −8.65%) / −$36.8M in the incident's own 17-week window (−10.62%).*
> **LooseEnds:** residual delta unexplained is within rounding of the seed's 60% deletion rate;
> inventory data ends wk 52 as expected; recommend ops post-mortem on the Memphis WMS.

BORA: *"Branches died on real numbers — you watched it happen. What survived: one building
went dark for seventeen weeks, and because Marketplace fulfillment is pinned to its warehouse
while Web reroutes, a warehouse failure surfaced as a channel problem. And notice it tells
you what it's still not sure about."*

**MAYA** (the human hand back on the wheel): `Which items were out of stock at Memphis DC in October 2025?`

> Item-level streak table, October slice — pattern plan #8/#9.

**Requires (beat 3):** Pythia P1–P4 (budget, tree pane via Iris PD-2, conclusion+LooseEnds);
HandoffContext (PD-1/PD-4); evidence queries #4/#6/#8/#9/#10/#11/#12/#13; **the seeds S1–S4
in the demo dump**; Pythia finds Memphis unaided within rehearsed budget (E-5 item 5).

---

## Beat 4 — Act: pin it

**MAYA:** pins the conclusion block + the monthly channel chart → **"Channel Health"** dashboard.

BORA: *"Two clicks: the finding and the chart she'll keep watching. The chart re-executes on
refresh — a living view. The conclusion's evidence is frozen — a record. Replay versus
reproduce; your auditors will care even if nobody else does."*

**Machinery/Requires:** Iris P4 artifacts (PD-6) — pin with provenance + display state;
replay vs reproduce semantics.

---

## Beat 5 — Look forward: forecast + what-if

**MAYA:** `What should we expect for holiday 2026, by channel?`

> Per-channel forecast curves with **confidence intervals**; the learned seasonal shape
> (Jan–Jul base → Aug–Oct ≈2.2× → Nov–Dec ≈3.4×) projected onto 2026. ⓘ names the model fit;
> Charon surfaces only here, as provenance lore ("source: worker session").

BORA: *"Different intent, different machinery: a statistical engine fits five years of
seasonality and projects the holiday. The shaded bands are honesty again — a forecast
without uncertainty is a guess."*

**Machinery:** Themis FORECAST → Pythia → Metis Fit/Project on the #1 series (Charon staging
under the hood).

**MAYA:** `Assume Memphis is back to normal from June and we run a win-back promotion on
Marketplace in November — what does Q4 look like then?`

> Scenario curve side-by-side with baseline; delta quantified live by Metis Simulate at demo
> time (Marketplace Q4 recovering to trend + promo lift) — this is a runtime what-if, not an
> R0-frozen fact, since Memphis-back-to-normal + a promo are hypothetical inputs, not seeded
> data. *(The promo is a scenario input — no data change; F-7.)*

**Requires (beat 5):** Metis arc + Pythia P4 S4.2 (Fit/Project/Simulate); Charon P3;
NATS/Seaweed/Polars worker on-cluster.

---

## Beat 6 — Close the loop (the ending)

**MAYA:** `Set this up as my Monday morning brief — channel health, flag anything unusual.`

> Hebe routine created from chat: schedule (Mondays), scope (channel health) visible.

BORA: *"And that is the routine that wrote the briefing we opened with. Detection, diagnosis,
decision, watch — not a workflow someone wired together. One conversation, and it just closed
its own loop."*

**Requires:** Hebe P4 create-from-chat; (the standing fixture and this created routine are
reconciled by demo-reset — see 07-f/E-4).

---

## Satellite G — Governance cameo (after the ending)

BORA switches to the second browser — **Dan Whitaker, CFO**.

> Dan's **Discover** page: **two** domain cards — *Hartland Analytics* and *Hartland Finance*.

**DAN:** `What is our total returns exposure in dollars for 2025?`

> Answered by **golem-hartland-finance**, ⓘ as always. *(Baseline: returns ≈ 5% of revenue,
> every channel.)*

BORA switches back to Maya's Discover: **one card**. *"For Maya the finance agent isn't
locked or greyed out — it does not exist in her world. Identity travels with every request
down to the database; the security model isn't in the UI, so there's nothing to click around.
Same platform, different worlds."* (Audit trail: one mention.)

**Machinery/Requires:** F-1 — `golem-hartland-finance` (same model, `visibility_roles:
[kantheon-role-finance]`); Themis visibility-filtered routing; Iris Discover; Keycloak demo
realm with both personas. Rehearsed Q&A for "what does Finance see that Maya's doesn't" —
see 07-f.

## Satellite D — Discover closer

> Maya's Discover: the Hartland Analytics DomainCard + its six example-question chips —
> every chip a question that just worked live.

BORA: *"How does anyone start? They open this page. No training course, no query language.
That's the pitch: your data, answering in sentences, showing its work."*

## If-time pocket & ε coda

- **SPLIT** (pocket): `Compare Web and Marketplace for 2025 — and why did returns spike in
  Q3?` → Themis decomposes; Golem + Pythia answer one turn (PD-13).
- **Feedback** (pocket): 👍 on the forecast; one sentence on learning + reask.
- **ε coda** (conditional-go, F-2): one–two live audience questions in a fresh throwaway
  session (Maya's login, S-11); in-model → pattern/free-SQL with provenance; out-of-model →
  the counter_example gap, narrated as the feature it is. Protocol + go-criteria: 07-f.

---

## Appendix A — Requirements rollup (the /planning checklist)

**Repo `Collite/hartland`** (D-7; Q-10 tree at build): hartland agent def + TTR model
packages (19 entities, D-5) + `q.hartland.*` preferred queries #1–#15 (D-2; CASE-sum shapes
need new Proteus goldens) + naming/synonym layer (D-6, D-6a exclusions) + **both** Shem
overlays (golem-hartland "Hartland Analytics", golem-hartland-finance "Hartland Finance",
F-1) + prompts `en/`.

**Data** (kantheon `surgery/`): seed scripts S1–S4 (`02-seed-*`, idempotent, hash-keyed) +
dim display-name UPDATEs (S-7 stores keyed on `s_store_id`, S-8 warehouses, S-9 reasons) →
re-run recon variants → **final demo dump** → `tpcds-staging/hartland/` (S-10). Q-4 tuning:
see Appendix B.

**Cluster** (olymp `clusters/hartland/` — `plan-cluster.md`): fork of bp-dsk, pinned MP-4
tags, E-3 estate (incl. themis/pythia/hebe/iris-P4/metis/charon/both golems, prometheus with
real LLM keys), dedicated warehouse CNPG (S-14) restored from the demo dump, `pg-hartland`
connection + Kyklop mapping, Keycloak demo realm (Maya, Dan), `hartland-query` run-set,
`demo-reset` recipe + standing fixtures.

**Readiness:** E-5 bar 1–7 (06-e) + rehearsal ladder R0–R5 (07-f). R0 replaces every ⟨R0⟩
above with frozen values.

## Appendix B — Baseline numbers & Q-4 guidance (recon 2026-07-09, pre-seed hartland)

- Channel FY revenue (flat 2021–2025): Stores ~$1.02–1.04B · Marketplace ~$726–730M · Web
  ~$362–373M. 2026 = one tail week.
- **r13 (Q-6 ✅ clean):** five warehouses at ~20% Marketplace share each ($144–148M/yr, ±1%).
  **Memphis DC := the NULL-named warehouse** — highest 2025 share, 20.13%, $146.1M (S-8a;
  it needed a display name anyway).
- Seasonality: Jan–Jul base → Aug–Oct ≈2.2× → Nov–Dec ≈3.4× (every channel, every year).
- Returns ≈ 5% of revenue; reason mix near-uniform across 35 reasons. Stockout baseline:
  0.09–0.10% isolated zero-weeks. Buyer age 45.0 flat. Promo linkage 97.7–100%.
- `net_profit` structurally negative (Stores 2025: −$444M) — D-6a exclusion validated.
- **Q-4 arithmetic check:** weeks 32–48 ≈ 49% of annual revenue (seasonal weights); deleting
  60% of Memphis (20.1% share) removes ≈ 5.9% of FY ⇒ **H2 ≈ −8.4%**, November ≈ −12% ✓.
  The spec'd November figure holds, but the *H2 −10..12% headline* needs either deletion
  ≈ 75–80%, a wider week window, or re-labeling the briefing KPI to the November/wks-32–48
  figure. Decide at seed build; freeze at R0.
  **Resolved 2026-07-18 (Stage 1.6):** kept the deletion at 60%; the incident's own weeks-32–48
  window measures **−10.62%**, inside the target range exactly — the briefing leads with that
  window, not calendar H2. Full figures: `data/recon/R0.md`.

---

## Appendix C — Czech mirror (CZ delivery, BM-8)

One locale per delivery (BM-8, resolved): the demo runs *entirely* in English over
`hartland_us` **or** entirely in Czech over `hartland_cz` — never both, no on-stage switch.
This appendix is the straight translation of the same beats for a Czech delivery: same story,
same percentages (BM-7 parity — see `data/recon/R0.md`), Kč instead of $, Brno instead of
Memphis.

**Setting (cs).** **Hartland Stores** — český maloobchodní řetězec; šest prodejen (HQ Praha),
celostátní **Web** obchod (hartland.cz, expeduje z pěti distribučních center s automatickým
přesměrováním) a **Marketplace**, kde prodejci třetích stran prodávají přes platformu Hartland
a **Hartland zajišťuje expedici** z pěti DC — Brno, Praha, Ostrava, Plzeň, Hradec Králové —
s pipeline pevně vázanou na sklad. Roční obrat ≈ 47,7 mld. Kč (Prodejny 23,6 mld. Kč ·
Marketplace 15,7 mld. Kč · Web 8,4 mld. Kč).

**Autorizovaná skutečnost (seed; C-3a mirror, BM-7).** **Distribuční centrum Brno kolabuje
koncem července 2025** (týdny 31–47: nulový stav zásob; týdny 32–48: ~60 % objednávek
Marketplace expedovaných z Brna ztraceno, včetně odpovídajících vratek; týdny 33–49:
"Nedorazilo včas" u přeživších vratek z Brna). Web se přesměrovává; prodejny nedotčeny;
všechno ostatní je skutečně ploché — každá špatná hypotéza umírá na reálných datech.

**Obsazení:** *Markéta Nováková*, Senior Category Manager (Q-BM-4a) — `marketa@hartland.example`.
CZ finanční ředitel/ka (Q-BM-4a, cameo). Přítomný čas: pondělí ráno, polovina ledna 2026 —
"právě jsme uzavřeli rok 2025".

**Agenti na scéně:** stejní jako US (golem-hartland assembluje s `locale: cs`), cs prompt
bundle (`agents/golem/shems/prompts/cs/`). Substrát: `pg-hartland-cz`, `db=hartland_cz`.

**R0 (CZK, frozen 2026-07-18):**

| Signal | Hodnota (cs) | Ekvivalent (en, pro ověření) |
|---|---|---|
| Marketplace, týdny 32–48/2025 meziročně | **−10,62 %** | −10.62% |
| Marketplace, kalendářní H2 2025 meziročně | **−8,65 %** | −8.65% |
| Listopad 2025 meziročně | **−12,33 %** | −12.33% |
| Nulový stav zásob v Brně (týdny) | **17 týdnů** (31.–47.) | 17 weeks |
| Podíl důvodu "Nedorazilo včas" u přeživších brněnských vratek (báze ~2,87 %) | **39,10 %** | 39.10% |
| Čtyři nezasažená DC, obrat 2025 | **3 317–3 349 mil. Kč** | $144.2M–$145.6M |
| Brno DC, obrat 2025 | **2 364 mil. Kč** (−29 % vs. sousedé) | $102.79M |
| Marketplace AOV, prosinec 2025 | **~526 tis. Kč/objednávka** | ~$22,863/order |

Every beat, chip, and machinery note from the English transcript translates directly —
only the surface strings and the connection (`pg-hartland-cz`) change; the pattern plans,
provenance, and governed-execution story are identical (that *is* BM-2's point).
