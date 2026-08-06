# Beat 1 — the overnight inbox item belongs to Hebe, and only to Hebe

> **Analysis, 2026-07-27.** Written after a proposed shortcut for Beat 1 of the *Kantheon*
> demo turned out not to work. Bora's ruling on reading it: **skip the shortcut — handle
> inboxes properly when Hebe is implemented.** This document records why, so the question is
> not re-opened from the proto comment alone.
>
> Companion to [`probes.md`](./probes.md), which covers the two blockers on the OBO path.

---

## 1. What Beat 1 asks for

The transcript opens with Maya arriving to a briefing that was produced overnight, unasked:
an inbox item carrying markdown, a KPI table, and a trend chart, badged as having come from a
scheduled run rather than from something she typed.

## 2. The shortcut that was proposed — and why it fails

`iris/v1.ChatTurnRequest` carries the origin fields, and the proto comment is unambiguous:

```proto
TurnOrigin origin = 6;          // SCHEDULED = 2 (Hebe routine)
optional string origin_ref = 7; // routine_id for SCHEDULED
// scheduled turns are persisted/routed/rendered exactly like user turns;
// origin is metadata … iris-bff must NOT gate on it.
```

Read alone, that says a script holding Maya's bearer could POST a turn with `origin: SCHEDULED`
and get a Beat-1 artefact indistinguishable from Hebe's. **It cannot.** Two independent
reasons, either sufficient:

**(a) `origin` is not reachable from the REST surface.** The proto field exists; the BFF's DTO
does not expose it. `ChatTurnRequestDto` is `(sessionId, question, desiredFormat,
routingHintAgentId)`, and the handler calls

```kotlin
dispatcher.runTurn(caller, sessionId, req.question, req.desiredFormat, corr, req.routingHintAgentId)
```

— origin is never threaded through. The column is written on `iris_turns`, but no HTTP path
sets it to anything but the default, and there is no service-ingest route that would.

**(b) The inbox is not a message inbox.** `InboxService.build(caller)` calls
`pythia.listInvestigations(caller.userId, caller.bearer)` and hands the result to
`InboxAggregator`. **An inbox item is a Pythia investigation.** A chat turn — whatever its
origin — produces no inbox item at all. `origin` surfaces only as a *badge* on an
investigation that already exists:

```kotlin
origin = join?.origin ?: if (inv.callerKind.equals("SCHEDULED", true)) "scheduled" else "user"
```

So the shortcut fails at both ends: it cannot set the field, and the field would not have
put anything in the inbox even if it could.

## 3. The real gap

This is not a missing config or an unwired client. The transcript and the implementation
describe **different artefacts**:

| | Transcript's Beat 1 | What the inbox renders today |
|---|---|---|
| Artefact | a *briefing* — markdown + KPI table + trend chart | a Pythia **investigation** |
| Producer | a Hebe routine firing overnight | Pythia, via `POST /v1/investigations` |
| Origin | `TurnOrigin.SCHEDULED` on a chat turn | `callerKind` on the investigation |

The origin *vocabulary* is shared, which is what makes the proto comment so easy to
over-read. The **carrier** is not.

## 4. Options that were on the table

| Option | Produces | Cost |
|---|---|---|
| **A.** Seed a Pythia investigation as Maya with `caller_kind: SCHEDULED` | a real inbox item, correctly badged | script only — *if* Pythia accepts caller kind on submit (unverified; `LivePythiaClient.submit` forwards an opaque `questionJson`) |
| **B.** Pre-run the question in Maya's session before the demo | the brief in session history; **no inbox item, no badge** | trivial, lowest fidelity |
| **C.** Extend iris-bff — expose `origin` on the DTO, surface scheduled turns in the inbox | Beat 1 as written | kantheon code + an image |

**Ruled: none of them now.** A and B are demo scaffolding that would have to be unwound; C is
real work that belongs with the feature, not ahead of it. Beat 1 waits for Hebe.

## 5. What this implies for the Hebe arc

The delivery path Beat 1 needs is a Hebe concern end to end, and it is **not** the
`kantheon_question` routine path that [`probes.md`](./probes.md) §1 finds unwired. That path
makes Hebe *ask the constellation a question*; Beat 1 additionally needs the **answer to land
in Maya's inbox**. Those are separate seams:

1. **Hebe → constellation** — the OBO + `IrisBffClient` wiring (probes.md §1/§2). Necessary,
   not sufficient.
2. **Result → inbox** — currently only Pythia investigations reach the inbox. A scheduled
   Hebe brief must either become an investigation, or the inbox must aggregate a second
   source. **This is an unmade design decision, and it is the one Beat 1 actually turns on.**

⚑ **For the Hebe arc:** decide the carrier before building the delivery. Options are (i) Hebe
submits a Pythia investigation with `callerKind = HEBE | SCHEDULED` and inherits the whole
inbox surface for free; (ii) `InboxAggregator` grows a second source over scheduled turns,
which makes `TurnOrigin.SCHEDULED` load-bearing at last and gives the proto comment its
intended meaning. (i) is far cheaper and reuses a working surface; (ii) is closer to what the
protos already say. Worth ruling explicitly — HB-P1's own DONE criteria are silent on it.

## 6. Lesson worth keeping

The proto comment describes an intent that the BFF does not yet implement. `origin` is
declared, persisted, and documented as end-to-end — and is unreachable from every caller.
Before scripting against a contract, check the DTO and the aggregator, not the `.proto`.
