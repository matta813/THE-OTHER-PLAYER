# THE OTHER PLAYER

An offline Godot 4 first-person psychological-horror project. Chapter 1, **Connection**, now extends the original first-contact slice through a small facility wing and a functional exit-airlock sequence. The unseen partner observes behaviour, helps remotely, and can act a little too early.

## Current playable flow

Wake in Arrival, use the link terminal, cross the remotely unlocked door and restore local power. The connected wing contains Storage, a Security Office, Transfer Room, Maintenance Tunnel, Generator Room, Observation Corridor, Communications and an Exit Airlock. Compare two CCTV feeds, report the active relay, carry a 35A fuse to the hatch, receive a card back, reroute a 10-unit power budget, start the generator with remote contactor help, test the link, and cycle the airlock. The ending fades without revealing the partner's nature. See [Chapter 1](docs/CHAPTER_01.md) for progression and current limits.

```bash
./tools/run.sh
```

Controls: WASD move, mouse look, Shift sprint, Ctrl crouch, E interact, Esc release/capture mouse, F3 developer overlay, F5 save, F9 load. With the debug overlay open in a debug build: F6 teleports to the current task, F7 sets a cooperative trust/low-suspicion state, F8 advances pending remote timers.

Validation: `./tools/check.sh` and `./tools/test.sh`. The F3 overlay exposes habits, trust, predictions, chapter state, power, reciprocity, hatch and airlock state; none appear in normal play. Current ambience, relay/motor cues and surface footsteps are procedurally generated offline. Authored facility audio, calibrated art assets, and a measured 30–45 minute first-time playtest are still needed.
