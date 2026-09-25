# Roadmap

## Current Chapter 1 production state

The complete Chapter 1 flow and adaptive events run in automated scene tests. Phase 6 added a 29-part generated Blender kit, original GLB props, more constrained airlock architecture, integrated physical fixtures, color and lighting adjustments, moving door/hatch/breaker mechanisms, room-dependent procedural audio, a shared menu theme, interaction progress, accessibility toggles, a Linux CI workflow and local build parity. The Linux release exports and boots outside the editor.

The visual pass is still uneven. Long wall runs, some collision-backed housings and monitor surfaces still read as simple geometry; the Security Office and Generator Room need stronger authored composition. The procedural sound is functional but lacks recorded machinery and room impulse responses. The terminal and loading presentation need a full production design pass. First-time human playtime and route-wide GPU stability have not been established, so the game's 30–45 minute target is unverified.

## Recommended next phase

Conduct first-time Chapter 1 playtests, measure completion time and wayfinding failures, and prioritize the spaces that look weak in real Forward+ captures. Refine Security, Generator and Airlock as authored set pieces; add restrained decals, varied wear and room-specific recordings. Complete terminal interaction, loading and accessibility QA, then profile sustained FPS, VRAM and shader stalls at multiple route points. Preserve the existing stable-ID interaction and adaptive hooks. Do not start Chapter 2 until Chapter 1 quality gates are met.
