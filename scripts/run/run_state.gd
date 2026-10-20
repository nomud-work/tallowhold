## Everything about one seeded run. Resets on a new run; nothing persists.
class_name RunState
extends RefCounted

const START_GOLD := 12
const START_WICKS := 3
const WIN_BONUS := 4
const START_ARMY: Array[StringName] = [&"tallowguard", &"wickthrower"]

var run_seed: int
var rng := RandomNumberGenerator.new()
var wallet := Wallet.new(START_GOLD)
var wicks := START_WICKS
var wave_index := 0
var army: Array[StringName] = []
var relics: Array[StringName] = []
var purchases: Array[String] = []
var battles_won := 0
var battles_fought := 0
var total_kills := 0
var peak_units := 0
var victory := false
var shop: Shop

func _init(seed_value: int) -> void:
	run_seed = seed_value
	rng.seed = seed_value
	army = START_ARMY.duplicate()
	shop = Shop.new(rng)

func current_wave() -> WaveDef:
	return Catalog.waves()[wave_index]

func wave_count() -> int:
	return Catalog.waves().size()

func is_over() -> bool:
	return victory or wicks <= 0

func family_counts() -> Array[int]:
	var c: Array[int] = [0, 0, 0]
	for id in army:
		var f := Catalog.unit(id).family
		if f < 3:
			c[f] += 1
	return c

func active_synergies() -> Array[SynergyDef]:
	var counts := family_counts()
	var out: Array[SynergyDef] = []
	for s in Catalog.synergies():
		if counts[s.family] >= s.threshold:
			out.append(s)
	return out

func relic_defs() -> Array[RelicDef]:
	var out: Array[RelicDef] = []
	for id in relics:
		out.append(Catalog.relic(id))
	return out

func build_mods() -> ArmyMods:
	return ArmyMods.build(active_synergies(), relic_defs())

func battle_seed() -> int:
	return run_seed * 1000 + battles_fought

## Applies a finished battle. Returns the gold paid out.
func finish_battle(won: bool, kills: int) -> int:
	battles_fought += 1
	total_kills += kills
	var wave := current_wave()
	var reward := wave.reward_gold
	for r in relic_defs():
		if r.effect == RelicDef.Effect.GOLD:
			reward += int(r.value)
	if won:
		battles_won += 1
		reward += WIN_BONUS
		if wave.is_boss:
			victory = true
			return 0
		wave_index += 1
	else:
		wicks -= 1
		if not wave.is_boss:
			wave_index += 1
	wallet.earn(reward)
	return reward
