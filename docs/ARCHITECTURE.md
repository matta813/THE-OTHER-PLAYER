# Architecture

`GameRuntime` is a small autoload registry for behaviour telemetry, asymmetric trust, predictions, the Other Player agent, story phase, and stable-ID facility lookup. Scene-owned interactables register stable IDs and expose `remote_action`, `state_dict`, and `load_state`; they do not know narrative sequencing.

`vertical_slice.gd` owns only this slice's authored flow and presentation. `OtherPlayerAgent` schedules contextual actions using complexity, behavioural hesitation, confidence, simulated activity, and deterministic variation. `PredictionSystem` issues, expires, evaluates, and serializes predictions. Reusable material resources and a procedural detail builder keep geometry text-based.

The project currently has no general Event Director. The vertical-slice sequence is the active authored director; a data-driven director remains future work.
