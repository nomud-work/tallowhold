# Tallowhold - design

An original roguelike autobattler in the style of How Many Dudes? (Butterscotch Shenanigans).
Theme, name, units and text are my own: an army of living candles holding a hall against moths of the Gloom.

## Loop
1. **Candle Market**: 3 offers per shop from a seeded shuffle bag (recruit squads or relics). Gold is an int wallet.
   Reroll costs 2 gold, then +1 per reroll in the same shop.
2. **Battle**: fully automatic. Candles start on the left, the Gloom arrives from the right in three pulses.
3. **Result**: a win pays the wave's gold plus a 4 gold bonus. A loss puts out one of 3 wicks but still pays the wave gold.
   Waves 1-6 move on either way. The boss wave repeats until it's beaten or the wicks are gone.

## Families (synergy = squads of that family in the army)
| Family | Units | 2 squads | 4 squads |
|---|---|---|---|
| WAX | Tallowguard (tank), Wickthrower (ranged), Drip Matron (summons Waxlings) | Wax +50% HP | all +30% HP |
| FLAME | Sparkrunner (fast striker), Fusepot (bursts on death), Flarecaster (long range) | Flame +50% damage | all 30% faster |
| GLASS | Lensmender (heals weakest ally), Prismshot (slowing shots) | heals and slows +80% | all start with a 40 shield |

Relics: Trimmed Wicks, Beeswax Coat, Bellows, Powder Horn, Dew Lens, Spare Mold, Tip Jar.

## Enemies
Moth (swarm melee), Gloomwisp (ranged), Husk (tank), and the boss, The Gloom Matriarch (ground slam plus moth summons).
7 battles: 6 escalating waves, then the boss.

## Tech
- Data: every number lives in `.tres` Resources under `data/` (UnitDef, RelicDef, SynergyDef, WaveDef). These are flyweights; runtime state is in SimUnit.
- Sim: a single RefCounted `BattleSim` steps all units at a fixed 1/60 s. It uses a 32 px spatial grid for separation and re-targets every 15 ticks (staggered). Battles have no per-unit nodes and no per-unit `_process`. It's seeded and deterministic.
- View: one `_draw` for floor, units, shots, particles (packed arrays), rings and damage numbers. Trauma/noise camera shake.
- Shop autopilot styles: PLANNER (chases synergies, fills tank/healer roles), RANDOM, AFK.
