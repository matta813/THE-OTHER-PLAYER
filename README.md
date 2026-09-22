# THE OTHER PLAYER

An offline Godot 4 first-person psychological-horror vertical slice. The current build focuses on grounded movement and an unseen cooperative partner that observes player behaviour.

## Current playable flow

Wake in Room A, inspect the facility, discover the remotely locked door, and use the physical link terminal. The Other Player answers after a contextual delay and unlocks the door. Cross the service corridor into Room B, where the partner requests the east power circuit. Exploration, repeated door checks, terminal returns, delayed response, and completion are recorded. Powering the circuit lights the room and completes the slice. Repeated early door checks can produce one subtle anticipatory lighting assist.

```bash
./tools/run.sh
```

Controls: WASD move, mouse look, Shift sprint, Ctrl crouch, E interact, Esc release/capture mouse, F3 developer overlay, F5 save, F9 load.

Validation: `./tools/check.sh` and `./tools/test.sh`. Audio emitters and interaction hooks exist, but authored sound assets are not yet included.
