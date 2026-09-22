# Save System

Save schema version 2 persists player transform, story phase, facility state by stable ID, asymmetric trust, raw telemetry, derived model confidence and samples, prediction history/statistics, and Other Player memory/task queue. Scheduled actions serialize remaining delay rather than process-local timestamps. Power-request elapsed time also survives loading.

Version 1 data loads with safe defaults. Loading applies state without reconnecting signals or replaying one-time narrative actions. Saves use JSON at `user://save.json`.
