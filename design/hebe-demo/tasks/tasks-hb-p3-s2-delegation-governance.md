# HB-P3 · S2 — Beats 3/4/5/6 (delegation · routines · hand-back · governance)

> Narrative Beats 3–6 → beat sheets `../beats/beat-{3,4,5,6}.md`. Pre-flight: S1 pattern
> established; ⚑4 verdict for Beat-6 scope (default: all three strikes).

- [ ] **T1 — Beat 3: the delegation turn.** Pin the question ("How did Marketplace revenue
  develop last week?" — wording tuned so golem resolves it to a pattern plan without
  clarification; lowercase channel token per quirks §3.3). Run: Hebe → iris-bff as maya →
  answer + deep link on the channel. Verify in Iris: the turn in **Maya's** history with
  the origin badge. Oracle: the weekly figure from the run-set oracle. Sheet + shots.
- [ ] **T2 — Beat 3 identity proof.** The "identity travels" moment needs evidence on
  screen: the Iris session shows maya; optionally the receipts view shows the acting
  identity on the turn's receipt. Record which surface the narration points at.
- [ ] **T3 — Beat 4: create-from-chat.** The exact sentence (fixture §4.2 wording) →
  routine appears in the console monitor → **diff vs `friday-returns.md` fixture**
  (schedule/body/delivery match = PASS) → manual fire → delivery on the phone. If
  create-from-chat parses the sentence differently across runs: pin the sentence that
  works 3/3 and record the L1 fallback (pre-created routine, narrate creation).
- [ ] **T4 — Beat 5: engineer the clarification.** Find the question that reliably parks:
  probe golem's param-fill (quirks §5.3 — one parameter at a time) with candidate
  wordings until one triggers a clarification 3/3 → pin it into
  `data/hebe/routines/clarify-demo.md` (replacing the placeholder). Then the full loop:
  fire → `AWAITING_AGENT` → phone message + deep link → resume in Iris → completion +
  final delivery. Sheet with every state.
- [ ] **T5 — Beat 6 strike 1: posture.** `Run a shell command…` → refusal; capture the
  exact refusal text + the refusal receipt in the receipts view. (If the shipped posture
  config permits the tool: that's a P1 config gap — restricted posture is the k8s default
  per the integration arc — fix via values, re-verify.)
- [ ] **T6 — Beat 6 strikes 2–3: receipts + stranger.** Chain verify run live (console or
  CLI `--verify`) → PASS output captured. Second Telegram account texts the bot →
  rejection per the P1.T5 recorded behavior. Cost line per P1.T7 verdict (show the
  gateway view or drop the line). Sheet with all three + ⚑4 scope note.
- [ ] **T7 — Failure drill (feeds P4 R2).** One deliberately broken run: scale iris-bff
  to 0 (or netpol it) mid-routine → the delivery **failure notification** arrives (never
  silent); restore; retry succeeds. Record — this is the strongest reliability line in
  the show if it's drilled, and a liability if it isn't.
- [ ] **T8 — Reset + sequence + non-builder.** HB-R1 → Beats 3–6 in sequence twice, same
  facts, ≤ 10 min; non-builder run from sheets; check boxes.

## Verify block

```sh
data/hebe/reset-hebe.sh
# Beat 3: figure == run-set oracle; turn in Maya's Iris history
# Beat 4: created routine diff-clean vs fixture; delivery arrives
# Beat 5: AWAITING_AGENT → resume → completion, 3/3 on the pinned wording
# Beat 6: refusal receipted · chain verify PASS · stranger rejected
```
