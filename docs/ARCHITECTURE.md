# Architecture
Scene-owned facility nodes implement a generic Interactable API and register stable IDs with the small GameRuntime service registry. Behaviour telemetry, derived metrics, trust, and saves are separate modules. Signals carry gameplay events; Other Player commands use remote_action APIs and never depend on visuals.
