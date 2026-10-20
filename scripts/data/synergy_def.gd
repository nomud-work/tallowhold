## Family bonus that switches on when the army has `threshold` squads of `family`.
class_name SynergyDef
extends Resource

enum Effect { FAMILY_HP, ALL_HP, FAMILY_DAMAGE, ALL_HASTE, HEAL_POWER, ALL_SHIELD }

@export var family: UnitDef.Family = UnitDef.Family.WAX
@export var threshold: int = 2
@export var effect: Effect = Effect.FAMILY_HP
@export var value: float = 0.0
@export var blurb: String = ""
