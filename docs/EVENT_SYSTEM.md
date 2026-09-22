# Event System

`AdaptiveEventDirector` evaluates candidate dictionaries against story stage, trust, suspicion, habit and expectation confidence, then scores eligible choices for cooperation, prediction confidence, deception value, cost, and reveal risk. Category cooldowns (`AMBIENT`, `COOPERATIVE`, `SUSPICIOUS`, `MANIPULATIVE`) and a cross-category quiet period prevent stacked anomalies. The last decision records debug-only rationale, expected result, score, and alternatives.

`SliceEventOptions` currently supplies three small choice sets: anticipatory light versus holding it, prompt/delayed/reassuring power acknowledgement, and optional reassurance when the player returns to the terminal. This is not yet a general event-authoring pipeline or a large narrative system. The director controls the psychological beat; scene logic still performs physical actions.

`ChapterEventOptions` adds early card return and airlock anticipation. The latter requires a live approach prediction and enough reciprocal trust. A preempted player interaction is recorded without corrupting prediction accuracy. If category pacing, low confidence or suspicion disqualifies it, the player completes the same physical airlock operation manually.
