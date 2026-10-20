## Multipliers for the player's army, built once per battle from relics and
## family synergies. Plain data so the sim and the balance runner share it.
class_name ArmyMods
extends RefCounted

var family_hp: Array[float] = [1.0, 1.0, 1.0]
var family_damage: Array[float] = [1.0, 1.0, 1.0]
var hp_all: float = 1.0
var damage_all: float = 1.0
var haste: float = 1.0
var heal_power: float = 1.0
var slow_power: float = 1.0
var blast_power: float = 1.0
var summon_bonus: int = 0
var shield: int = 0

func hp_mult(def: UnitDef) -> float:
	var m := hp_all
	if def.family < 3:
		m *= family_hp[def.family]
	return m

func damage_mult(def: UnitDef) -> float:
	var m := damage_all
	if def.family < 3:
		m *= family_damage[def.family]
	return m

static func build(synergies: Array[SynergyDef], relics: Array[RelicDef]) -> ArmyMods:
	var m := ArmyMods.new()
	for s in synergies:
		match s.effect:
			SynergyDef.Effect.FAMILY_HP:
				m.family_hp[s.family] += s.value
			SynergyDef.Effect.ALL_HP:
				m.hp_all += s.value
			SynergyDef.Effect.FAMILY_DAMAGE:
				m.family_damage[s.family] += s.value
			SynergyDef.Effect.ALL_HASTE:
				m.haste += s.value
			SynergyDef.Effect.HEAL_POWER:
				m.heal_power += s.value
				m.slow_power += s.value
			SynergyDef.Effect.ALL_SHIELD:
				m.shield += int(s.value)
	for r in relics:
		match r.effect:
			RelicDef.Effect.DAMAGE_ALL:
				m.damage_all += r.value
			RelicDef.Effect.HP_ALL:
				m.hp_all += r.value
			RelicDef.Effect.HASTE_ALL:
				m.haste += r.value
			RelicDef.Effect.BLAST:
				m.blast_power += r.value
			RelicDef.Effect.HEAL:
				m.heal_power += r.value
			RelicDef.Effect.SUMMON:
				m.summon_bonus += int(r.value)
			RelicDef.Effect.GOLD:
				pass
	return m
