## Between-battle market: three offers drawn from a seeded shuffle bag.
class_name Shop
extends RefCounted

const OFFER_COUNT := 3
const REROLL_BASE := 2

var offers: Array[Dictionary] = []
var rerolls := 0
var _bag: ShuffleBag

func _init(rng: RandomNumberGenerator) -> void:
	var items: Array = []
	for u in Catalog.recruits():
		items.append("u:" + String(u.id))
		items.append("u:" + String(u.id))  # recruits twice as common as relics
	for r in Catalog.relics():
		items.append("r:" + String(r.id))
	_bag = ShuffleBag.new(items, rng)

func reroll_cost() -> int:
	return REROLL_BASE + rerolls

func open_new() -> void:
	rerolls = 0
	_fill()

func reroll(wallet: Wallet) -> bool:
	if not wallet.try_spend(reroll_cost()):
		return false
	rerolls += 1
	_fill()
	return true

func _fill() -> void:
	offers.clear()
	var seen := {}
	var guard := 0
	while offers.size() < OFFER_COUNT and guard < 40:
		guard += 1
		var key: String = _bag.draw()
		if seen.has(key):
			continue
		seen[key] = true
		offers.append(_offer_for(key))

func _offer_for(key: String) -> Dictionary:
	var id := StringName(key.substr(2))
	if key.begins_with("u:"):
		var u := Catalog.unit(id)
		return {"kind": "unit", "id": id, "cost": u.cost, "key": key, "sold": false}
	var r := Catalog.relic(id)
	return {"kind": "relic", "id": id, "cost": r.cost, "key": key, "sold": false}

## Returns true when the purchase went through. Relics leave the pool for good.
func buy(index: int, run: RunState) -> bool:
	if index < 0 or index >= offers.size():
		return false
	var o: Dictionary = offers[index]
	if o.sold:
		return false
	if o.kind == "relic" and run.relics.has(o.id):
		return false
	if not run.wallet.try_spend(o.cost):
		return false
	o.sold = true
	if o.kind == "unit":
		run.army.append(o.id)
	else:
		run.relics.append(o.id)
		_bag.remove_item(o.key)
	run.purchases.append(String(o.id))
	return true
