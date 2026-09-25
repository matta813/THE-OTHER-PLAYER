# Architecture

`GameRuntime` is the existing autoload registry for telemetry, the derived model, habit memory/detection, asymmetric trust, expectations, suspicion, predictions, the Other Player scheduler, adaptive event selection, story phase, and stable-ID facility lookup. Scene-owned interactables register stable IDs and expose `remote_action`, `state_dict`, and `load_state`; they do not know narrative sequencing.

`vertical_slice.gd` still owns the opening contact and power flow. `ChapterOneController` is a scene-owned sibling controlling later chapter tasks; it serializes through stable ID `chapter_one` and does not replace the opening. `ChapterWingBuilder` creates the connected wing and registers reusable interactables. `ChapterPowerGrid`, `ReciprocityModel`, `TransferHatch`, `SecurityCameraConsole`, and `AirlockSystem` contain their respective rules instead of placing them in the player controller. `ChapterDialogueBank` reads terse lines from `resources/dialogue/chapter_01.json`.

`HabitDetector` maps meaningful events into `BehaviourMemory`; `AdaptiveEventDirector` scores candidate sets in `SliceEventOptions` and `ChapterEventOptions` under trust, confidence, suspicion and category cooldown constraints. `OtherPlayerAgent` schedules remote actions. `PredictionSystem` records actual, expired or preempted results. `TerminalTypewriter` handles the shared terminal presentation. Only the selected CCTV feed renders, for a short viewing window.

The detail builder adds architectural cladding, service ducts, fixtures, equipment housings, expansion joints and two colliding thresholds. Large concrete and floor surfaces use a world-space procedural PBR shader so scale remains consistent across differently sized meshes. The east luminaire diffuser changes material with the power circuit.

The player node is centered around the collision capsule at roughly one metre above the floor; the camera sits about 0.6 metres above that center. Crouching lowers both the camera and collider center while keeping the capsule bottom grounded.

The director remains a reusable scoring/pacing component rather than a general authored-event pipeline. It now also weighs an early hatch return and an anticipatory airlock cycle. Physical story beats remain scene-owned. The wing is procedural, text-editable architecture with distinct practical-light palettes, but it is not a finished art pass.

## Production shell

`main_menu.tscn` is the boot scene; `chapter_01.tscn` is the playable scene. `GameFlow` owns scene transitions and resets `GameRuntime` before starting a session. `GameSettings` stores preferences separately in `user://settings.json`, applies video/audio/input settings, and exposes scene environment settings. `MenuUI` is shared between the main menu and pause overlay. The pause overlay uses Always processing while the game tree pauses, including the remote action clock. `SubtitlePresenter` displays queued communication captions independently of the terminal. `ReleaseInfo.VERSION` is the canonical semantic version.

`SaveSystem` keeps schema version 4, adds optional metadata and four manual slot paths, and validates save data before applying it. The prior quick-save and checkpoint paths remain compatible. The exporter uses the Linux preset and `tools/export_release.sh`; no build output belongs in source control.
