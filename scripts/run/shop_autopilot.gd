## Decides shop actions one at a time so the UI can show each choice.
## Styles: PLANNER (chases synergies, fills roles), RANDOM, AFK (never buys).
class_name ShopAutopilot
extends RefCounted

enum Style { PLANNER, RANDOM, AFK }

const MAX_REROLLS := 2

var style: Style
var _rng := RandomNumberGenerator.new()

func _init(s: Style, seed_value: int) -> void:
	style = s
	_rng.seed = seed_value ^ 0x5eed

## Returns {"type": "buy", "index": i} | {"type": "reroll"} | {"type": "done"}
func next_action(run: RunState) -> Dictionary:
	var shop := run.shop
	var affordable: Array[int] = []
	for i in shop.offers.size():
		var o: Dictionary = shop.offers[i]
		if not o.sold and run.wallet.can_afford(o.cost) and not (o.kind == "relic" and run.relics.has(o.id)):
			affordable.append(i)
	match style:
		Style.AFK:
			return {"type": "done"}
		Style.RANDOM:
			if affordable.is_empty():
				return {"type": "done"}
			return {"type": "buy", "index": affordable[_rng.randi_range(0, affordable.size() - 1)]}
	var best := -1
	var best_score := -INF
	for i in affordable:
		var s := score(shop.offers[i], run)
		if s > best_score:
			best_score = s
			best = i
	if best >= 0:
		return {"type": "buy", "index": best}
	if shop.rerolls < MAX_REROLLS and run.wallet.can_afford(shop.reroll_cost() + 6):
		return {"type": "reroll"}
	return {"type": "done"}

static func score(o: Dictionary, run: RunState) -> float:
	if o.kind == "unit":
		var def := Catalog.unit(o.id)
		var counts := run.family_counts()
		var c := counts[def.family]
		var s := 10.0
		if c + 1 == 2 or c + 1 == 4:
			s += 8.0
		elif c == 0 or c == 2:
			s += 3.0
		var roles := {}
		for id in run.army:
			roles[Catalog.unit(id).role] = int(roles.get(Catalog.unit(id).role, 0)) + 1
		if def.role == UnitDef.Role.TANK and int(roles.get(UnitDef.Role.TANK, 0)) < 1 + run.army.size() / 5:
			s += 6.0
		if def.role == UnitDef.Role.HEALER and int(roles.get(UnitDef.Role.HEALER, 0)) == 0 and run.army.size() >= 4:
			s += 5.0
		return s * 6.0 / float(def.cost)
	var r := Catalog.relic(o.id)
	var n := float(run.army.size())
	var by_role := func(role: int) -> float:
		var k := 0
		for id in run.army:
			if Catalog.unit(id).role == role:
				k += 1
		return float(k)
	match r.effect:
		RelicDef.Effect.DAMAGE_ALL, RelicDef.Effect.HP_ALL, RelicDef.Effect.HASTE_ALL:
			return 1.3 * n * 6.0 / float(r.cost)
		RelicDef.Effect.BLAST:
			return 4.0 * by_role.call(UnitDef.Role.EXPLODER) * 6.0 / float(r.cost)
		RelicDef.Effect.HEAL:
			return 4.0 * by_role.call(UnitDef.Role.HEALER) * 6.0 / float(r.cost)
		RelicDef.Effect.SUMMON:
			return 6.0 * by_role.call(UnitDef.Role.SUMMONER) * 6.0 / float(r.cost)
		RelicDef.Effect.GOLD:
			return (14.0 if run.wave_index < 3 else 2.0) * 6.0 / float(r.cost)
	return 0.0

## Applies one action to the run. Returns false when the shop phase is over.
func apply(action: Dictionary, run: RunState) -> bool:
	match action.type:
		"buy":
			return run.shop.buy(action.index, run)
		"reroll":
			return run.shop.reroll(run.wallet)
	return false
