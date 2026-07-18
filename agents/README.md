# agents — the Hartland agent def + both Golem Shems (D-7, BM-9)

`hartland.yaml` is the ai-models-analog agent definition (Ariadne's Git source, per BM-9's
"model repo -> Ariadne -> assembled Shem" onboarding path). `golem/shems/` holds the two
assembled-Shem overlays (kantheon canon: identity+model from the agent def, area terminology
from the model, the per-agent residue in `shem.yaml`, template constants at boot).

## Persona -> `visibility_roles` mapping (Q-BM-4a, Stage 2.6 T5)

| Persona | World | Role | Shem(s) it grants |
|---|---|---|---|
| Maya | US | `kantheon-area-hartland` | golem-hartland ("Hartland Analytics") |
| Markéta Nováková (Senior Category Manager) | CZ | `kantheon-area-hartland` | golem-hartland |
| Dan (CFO) | US | `kantheon-role-finance` | golem-hartland-finance ("Hartland Finance") |
| CZ CFO | CZ | `kantheon-role-finance` | golem-hartland-finance |

**The governance-cameo contrast (F-1, verify in Stage 2.6 T6 / live in Phase 3 H3.2):**
`golem-hartland`'s `visibility_roles` = `[kantheon-area-hartland]` only;
`golem-hartland-finance`'s = `[kantheon-role-finance]` only — the two role sets are
disjoint, so the finance Shem is structurally unroutable for Maya/Markéta (B-2α) and the
main Shem is absent for the CFO personas in Discover **and** in Themis routing. The actual
Keycloak realm-role wiring (mapping real user accounts to these two roles) is Phase 3
H3.2 — here the Shems only carry the declared contract.

## Prompts

`golem/shems/<shem>/prompts/{en,cs}/system.yaml` — per-Shem system prompts (BM-6: cs is in
scope, not "unused per FI-4" as in the pre-delta ai-models precedent). Adapted from
ai-models' generic golem intent-classifier prompt (`prompts/golem/{en,cs}/intent.yaml`) with
the domain framing swapped to Hartland retail analytics; the classifier role and JSON output
contract are unchanged. Per the golem-ucetnictvi precedent, prompts belong to the Shem, not
the model.
