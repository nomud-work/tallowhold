# Balance plan (GDAS godot-monte-carlo-balancer, Phase 0)

| Abstraction | Tallowhold |
|---|---|
| Session | One run: up to 7 battles (6 waves + boss), 3 wicks |
| Threat | Gloom waves (WaveDef: counts, hp_scale, damage_scale) |
| Defense / agency | Shop picks: recruit squads, relics, rerolls |
| Faults | none (battles are automatic) - deleted |
| Resources | Gold (int wallet) |
| In-run economy | Wave reward + 4 gold win bonus, Tip Jar relic |
| Meta economy | none - deleted |
| Grade | Primary metric: run win rate (boss beaten) |

Physics/AI waiver: not needed. The simulator is the game's own BattleSim, stepped headless (same code, same .tres data), so there is no separate model to calibrate.

## Play styles and bands (set before tuning)
| Style | Behaviour | Win-rate band |
|---|---|---|
| PLANNER | chases family thresholds, keeps tanks/healers, values relics by army | 55% - 90% |
| RANDOM | buys random affordable offers | 15% - 60% |
| AFK | never buys | 0% - 10% (the shop must matter) |

## Result (tools/balance_runner.gd, 200 seeded runs per style, seeds 1000-1199)
| Style | Win rate | 95% Wilson CI | Verdict |
|---|---|---|---|
| PLANNER | 80.5% | 74.5% - 85.4% | OK |
| RANDOM | 32.0% | 25.9% - 38.8% | OK |
| AFK | 0.0% | 0.0% - 1.9% | OK |

Highest unit count seen at once across these runs: 140.
Tuning passes (60 then 40 runs per style) moved wave hp/damage scaling and gold rewards. Then I made armies and waves denser for readability and re-tuned.
