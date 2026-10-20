## Integer gold with validated spending. UI and autopilot ask; the wallet decides.
class_name Wallet
extends RefCounted

signal changed(gold: int)

var gold: int = 0

func _init(start: int = 0) -> void:
	gold = start

func can_afford(cost: int) -> bool:
	return cost >= 0 and gold >= cost

func try_spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	gold -= cost
	changed.emit(gold)
	return true

func earn(amount: int) -> void:
	if amount <= 0:
		return
	gold += amount
	changed.emit(gold)
