# Behaviour System

`BehaviourEvent` stores timestamp, type, position, stable target ID, context, response time, previous related event, and metadata. The recorder caps history at 512 meaningful events and supports recent-event inspection and counts.

The model derives bounded metrics from weighted evidence. Each metric exposes value, confidence, sample count, and last-change reason. Weight decays modestly with samples so one action cannot permanently label the player. The slice records locked-door retries and rechecks, optional inspections, room entry, terminal returns, delayed requests, completion, response time, and unnecessary toggles. F3 exposes the model only in the developer overlay.
