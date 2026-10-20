## A run-long bonus bought in the shop.
class_name RelicDef
extends Resource

enum Effect { DAMAGE_ALL, HP_ALL, HASTE_ALL, BLAST, HEAL, SUMMON, GOLD }

@export var id: StringName
@export var display_name: String = ""
@export_multiline var blurb: String = ""
@export var cost: int = 8
@export var effect: Effect = Effect.DAMAGE_ALL
@export var value: float = 0.0
