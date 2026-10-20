## One battle: which enemies, how many, how much tougher, and the gold it pays.
class_name WaveDef
extends Resource

@export var title: String = ""
@export var enemy_ids: Array[StringName] = []
@export var counts: PackedInt32Array = PackedInt32Array()
@export var hp_scale: float = 1.0
@export var damage_scale: float = 1.0
@export var reward_gold: int = 10
@export var is_boss: bool = false

func total_count() -> int:
	var n := 0
	for c in counts:
		n += c
	return n
