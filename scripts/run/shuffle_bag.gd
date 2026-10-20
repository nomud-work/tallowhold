## Fair draws: every entry comes out once per bag before any repeats.
## Uses the caller's seeded RNG so a seed always gives the same shops.
class_name ShuffleBag
extends RefCounted

var _source: Array = []
var _bag: Array = []
var _rng: RandomNumberGenerator

func _init(items: Array, rng: RandomNumberGenerator) -> void:
	_source = items.duplicate()
	_rng = rng

func draw() -> Variant:
	if _bag.is_empty():
		_bag = _source.duplicate()
		# Fisher-Yates with the run RNG (not Array.shuffle, which uses the global RNG).
		for i in range(_bag.size() - 1, 0, -1):
			var j := _rng.randi_range(0, i)
			var t = _bag[i]
			_bag[i] = _bag[j]
			_bag[j] = t
	return _bag.pop_back()

func remove_item(item: Variant) -> void:
	_source.erase(item)
	_bag.erase(item)

func size() -> int:
	return _source.size()
