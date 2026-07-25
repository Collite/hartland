# SD-P4 — Rig hardening + identity

> Contracts §7–§8. **Flags RULED 2026-07-23:** ⚑1 = A on Bora's machine (Rancher Desktop
> docker) then C; ⚑2 = identity RELAXED for A — dev-auth fine, real Keycloak verified at
> C graduation. P4b (cluster graduation, ruled IN) is a separate olymp-side task list
> authored when P4b opens, after the P5 dry-run (plan §SD-P4).

- [ ] **T1 — Rig entry points final on Rancher Desktop.** `rig/up.sh` (cold start ≤ 10 min
  on RD docker — include the RD VM sizing pre-check/`rdctl` hint, the PG restore needs
  headroom; health table; exit non-zero on any red) · `rig/reset.sh` (= SD-R1, already
  built P1 — harden: `--with-warehouse` flag, fixture checklist print) · `rig/preshow.sh`
  (SD-R2: reset → up-check → warm all four tiles → seed oracle spot-check → stage-numbers
  print → login checklist print).
- [ ] **T2 — Identity, A-variant (⚑2 relaxed).** Wire the SIMPLEST auth that yields two
  distinct users: FO-29 dev-auth mode with `maya` + `dan` identities (planner-service
  bearer expectations per the P0.T4 probe — dev tokens or auth-off ingress, whichever the
  shipped config supports). Adjust the Beat-0 narration to its A-variant line ("one
  login" spoken about the *platform*, demonstrated fully at the cluster graduation) —
  record the delta in the narrative. A local Keycloak is OPTIONAL — only if it costs
  nothing; do not sink time into realm wiring that P4b redoes properly.
- [ ] **T3 — Two-user flow across tiles.** maya and dan usable simultaneously (two
  browser profiles or two dev identities); all four tiles reachable per user; documented
  in `rig/README.md` §browsers. (Full SSO/logout round-trip = P4b scope.)
- [ ] **T4 — Bearer path as-shipped.** The walk (`acceptance-walk-demo.mjs`) + the S1
  refusal asserts re-run under the T2 auth mode (dev tokens for maya/dan); reservation
  holder names surface correctly ("checked out by Maya Chen") — that string is a beat.
- [ ] **T5 — TLS/origin posture recorded.** Variant A = plain `http://localhost` (no cert
  story on stage); record it in rig/README §tls, plus the note that C graduation flips to
  the cluster's https + private-CA story (`../demo-ops-manual.md` §2 applies there).
- [ ] **T6 — Operator README.** `rig/README.md` complete: prerequisites (versions from
  P0 pins), the three commands, the two-profile browser setup, the fixture inventory,
  the troubleshooting table (seed from `../studio-demo-quirks.md`). A non-builder brings
  the rig up from the README alone on a clean machine — that run IS this task's test.
- [ ] **T7 — Bar items.** Record SD-B 1–2 + 6 (cold-start, oracle, reset-and-repeat) in
  `../readiness/` with date + SHAs. Check boxes.

## Verify block

```sh
git clone <hartland> fresh && cd fresh && rig/up.sh          # from README alone, ≤10min
rig/preshow.sh                                               # PASS tail printed
# maya login → 4 tiles; dan parallel profile; walk green under real tokens
```
