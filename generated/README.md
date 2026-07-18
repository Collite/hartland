# generated — committed build artifacts

`resolved-packages.json` — the deterministic `packages`/`entities`/`areas` snapshot from the
tatrman Modeler CLI (`just resolve-packages`), mirroring the `ai-models` repo's convention.
Regenerate after any `model/` change: `just resolve-packages`. `just check-model` verifies the
committed snapshot isn't stale (no CI wired yet — Phase 3 adds it, per BM-10's shared-fixture
gate; until then, regenerate by hand before committing a `model/` change).
