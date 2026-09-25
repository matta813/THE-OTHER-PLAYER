# Save System

Save schema version 4 adds the carried item ID to version 3 data. The registered `chapter_one` facility state persists chapter stage, elapsed task time, checkpoint marker, viewed CCTV feeds, power budget, reciprocity, hatch/generator progress and airlock phase. Individual interactables persist through stable IDs. Scheduled actions serialize remaining delay rather than process-local timestamps. Saves are written to a temporary file and renamed into place.

Version 1/2 data migrates with safe adaptive defaults; version 3 loads with an empty hand and chapter defaults where data is absent. Old pending predictions are superseded because their process-local timestamps are not comparable. Loading applies state without reconnecting signals or replaying one-time narrative actions. F9 also rebuilds door indicators, lighting, power dependencies and pending-reply presentation. Manual saves use `user://save.json`; chapter milestones write separately to `user://checkpoint.json`. `BehaviourProfile` is an internal, versioned aggregate format for future New Game+, not player-facing.


## Player-facing slots

Manual slots are `user://slot_1.json` through `slot_4.json`. Quick save remains `user://save.json`; automatic chapter checkpoints remain `user://checkpoint.json`. Continue selects the newest valid file across those paths. Optional metadata records project version, chapter, location, playtime and Unix timestamp without changing schema version 4. Old saves display legacy metadata and continue to load. Invalid or unsupported files show an invalid slot state and are never applied. New Game resets runtime state and preserves manual slots; its next checkpoint replaces the checkpoint file. Settings live separately in `user://settings.json`.
