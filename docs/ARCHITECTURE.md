# Architecture

`GameRuntime` is a small autoload registry for behaviour telemetry, asymmetric trust, predictions, the Other Player agent, story phase, and stable-ID facility lookup. Scene-owned interactables register stable IDs and expose `remote_action`, `state_dict`, and `load_state`; they do not know narrative sequencing.

`vertical_slice.gd` owns only this slice's authored flow and presentation. `OtherPlayerAgent` schedules contextual actions using complexity, behavioural hesitation, confidence, simulated activity, and deterministic variation. `PredictionSystem` issues, expires, evaluates, and serializes predictions. Reusable material resources and a procedural detail builder keep geometry text-based.

The detail builder adds architectural cladding, service ducts, fixtures, equipment housings, expansion joints and two colliding thresholds. Large concrete and floor surfaces use a world-space procedural PBR shader so scale remains consistent across differently sized meshes. The east luminaire diffuser changes material with the power circuit.

The player node is centered around the collision capsule at roughly one metre above the floor; the camera sits about 0.6 metres above that center. Crouching lowers both the camera and collider center while keeping the capsule bottom grounded.

The project currently has no general Event Director. The vertical-slice sequence is the active authored director; a data-driven director remains future work.
