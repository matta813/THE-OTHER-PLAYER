# Chapter 1 — Connection

Current status: a complete **technical chapter route**, not yet a verified 30–45 minute content/art pass. The original first-contact slice is the opening of this chapter; `ChapterOneController` continues after east power is restored. No second-player body or online dependency exists.

## Physical route

Arrival Room → Service Corridor → Electrical Room → connected service spine. Open bays off the spine are Storage, Security Office, Generator Room and Transfer Room. The central route includes Maintenance Tunnel, Observation Corridor, Communications and Exit Airlock. Side openings and the main corridor are collision-tested; the airlock inner/outer bulkheads are physical gates. Wall signs, a service schematic, capacity label, inspection notices, cable trays, housings and differently lit zones orient the player.

## Required cooperative tasks

1. **First contact:** use the Arrival terminal; the unseen partner remotely unlocks the first door after a delay.
2. **East power:** reach Electrical and enable the local circuit. The partner acknowledges; delayed acknowledgement can test an established expectation.
3. **Camera guidance:** in Security, compare STORAGE (relay active) and GENERATOR (contactor open) feeds, then report the live relay. A wrong report gets a short correction and does not block progress. Only the selected feed renders, for eight seconds.
4. **Physical transfer:** take the 35A fuse from Storage, carry it to Transfer, deposit and seal the hatch. The partner receives the fuse and returns an access card. The hatch rejects unrelated items. Remote scheduling has a fallback if a return action is lost.
5. **Power routing:** the 10-unit bus initially uses CCTV 3 + doors 2 + ventilation 3. Starter needs 5; turning ventilation off permits starter on while preserving cameras and doors. CCTV and airlock access react to their circuits. Overload attempts are harmless and logged.
6. **Generator and link:** use the returned card at the local starter; the partner holds a remote contactor. Test the communications panel after the generator comes online.
7. **Exit airlock:** unlock/open the inner bulkhead, use the physical cycle control (or experience a high-confidence anticipatory cycle), wait for sealing/pressurizing/opening, then cross the outer threshold. The chapter fades to `CONNECTION ESTABLISHED` after the final terse message.

## Adaptive moments and restraint

- Repeated, time-separated checks of the first locked door can cause early light assistance.
- Repeated fast cooperation can make the returned card arrive before a request for it.
- Approaching the enabled airlock after reliable cooperation may trigger a predicted cycle before the player presses the control; `"thought you were ready. sorry"` is the plausible explanation.

`AdaptiveEventDirector` applies confidence, trust, suspicion, category cooldown and cross-category pacing. High suspicion or weak evidence chooses ordinary reactive help. None of the above is necessary for progression. If a remote task is lost, the hatch and generator have safety timeouts. The player can always use the physical airlock control when available.

## Checkpoints and debug

Automatic checkpoints: first contact, east power, Security reached, generator online, airlock cycle, chapter end. They write `user://checkpoint.json`; F5/F9 remain the manual save/load pair. Both formats preserve chapter/adaptive state. F3 shows task, circuit load, reciprocity, camera/hatch/airlock state. In debug builds with F3 open, F6 teleports to the current task, F7 prepares a trusting/low-suspicion state, and F8 advances pending remote actions.

## Current limits

Automated tests complete the path and check navigation gaps, power dependencies, hatch return, checkpoint round-trip, airlock interlocks and adaptive eligibility. Forward+ launch was validated. No first-time human playtime measurement or complete hands-on chapter playtest has been performed. The wing uses modular/procedural geometry and synthesized placeholder audio; authored props, decals, signage typography, sound design and substantial lighting/material QA are still required before calling it a polished 30–45 minute chapter.
