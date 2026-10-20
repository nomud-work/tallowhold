# Decisions (community GDAS skills used)

Skill pack: Game-Dev-Agentic-Skills (thedivergentai), community-made, LGPL-3.0, cloned at commit db004d7.

- godot-master routing: "Wave-based Action" -> waves + combat; "Simulation/RTS batch processing" for high unit counts; economy pacing -> Monte Carlo balancer.
  NEVER list applied: no per-entity `_process`, int currency, no group queries in hot loops.
- game-loop-waves: data-driven WaveDef resources; alive counters instead of counting children.
- resource-data-patterns: definitions as Resources (flyweights), runtime state in RefCounted.
- combat-system: one `deal_damage` entry point (shield first, then hp, then death handling).
- economy-system: Wallet validates before subtracting; UI/autopilot only send requests.
- genre-roguelike: an isolated seeded RNG and a shuffle bag for shop fairness. I wrote my own Fisher-Yates with the run RNG because `Array.shuffle` uses the global RNG.
- signal-architecture: the sim pushes events into an array that the view drains each frame (no high-frequency signals).
- camera-systems: trauma + FastNoiseLite shake. The skill's sample seeds the noise with `randi()`; I fixed the seed so recordings repeat.
- tweening: banner uses create_tween().bind_node(), EASE_OUT/TRANS_BACK.
- monte-carlo-balancer: Phase 0 plan in BALANCE_PLAN.md, play styles, 95% Wilson CI verdicts against bands.
  I ran the method directly on the game's own sim in headless Godot (tools/balance_runner.gd).
- testing-patterns: GdUnit4 (6.2.2) headless CLI, seeded tests, no wall-clock sleeps (simulate_frames).
