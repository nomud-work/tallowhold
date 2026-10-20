## Single read-only entry point to all game data. Everything balance-relevant
## lives in the .tres files under res://data; nothing is copied into code.
class_name Catalog
extends RefCounted

const UNIT_PATHS: Array[String] = [
	"res://data/units/tallowguard.tres", "res://data/units/wickthrower.tres",
	"res://data/units/drip_matron.tres", "res://data/units/waxling.tres",
	"res://data/units/sparkrunner.tres", "res://data/units/fusepot.tres",
	"res://data/units/flarecaster.tres", "res://data/units/lensmender.tres",
	"res://data/units/prismshot.tres",
	"res://data/enemies/moth.tres", "res://data/enemies/gloomwisp.tres",
	"res://data/enemies/husk.tres", "res://data/enemies/matriarch.tres",
]
const RELIC_PATHS: Array[String] = [
	"res://data/relics/trimmed_wicks.tres", "res://data/relics/beeswax_coat.tres",
	"res://data/relics/bellows.tres", "res://data/relics/powder_horn.tres",
	"res://data/relics/dew_lens.tres", "res://data/relics/spare_mold.tres",
	"res://data/relics/tip_jar.tres",
]
const SYNERGY_PATHS: Array[String] = [
	"res://data/synergies/wax_2.tres", "res://data/synergies/wax_4.tres",
	"res://data/synergies/flame_2.tres", "res://data/synergies/flame_4.tres",
	"res://data/synergies/glass_2.tres", "res://data/synergies/glass_4.tres",
]
const WAVE_PATHS: Array[String] = [
	"res://data/waves/wave_1.tres", "res://data/waves/wave_2.tres",
	"res://data/waves/wave_3.tres", "res://data/waves/wave_4.tres",
	"res://data/waves/wave_5.tres", "res://data/waves/wave_6.tres",
	"res://data/waves/wave_7.tres",
]
const FAMILY_NAMES: Array[String] = ["WAX", "FLAME", "GLASS", "GLOOM"]
const FAMILY_COLORS: Array[Color] = [
	Color(0.95, 0.90, 0.79), Color(1.0, 0.54, 0.24), Color(0.5, 0.89, 1.0), Color(0.69, 0.36, 1.0)]
const ROLE_NAMES: Array[String] = ["Tank", "Striker", "Ranged", "Healer", "Bomber", "Summoner", "Slower", "Boss"]

static var _units: Dictionary = {}
static var _relics: Dictionary = {}
static var _synergies: Array[SynergyDef] = []
static var _waves: Array[WaveDef] = []
static var _recruits: Array[UnitDef] = []

static func _ensure() -> void:
	if not _waves.is_empty():
		return
	for p in UNIT_PATHS:
		var u: UnitDef = load(p)
		_units[u.id] = u
		if u.recruitable:
			_recruits.append(u)
	for p in RELIC_PATHS:
		var r: RelicDef = load(p)
		_relics[r.id] = r
	for p in SYNERGY_PATHS:
		_synergies.append(load(p))
	for p in WAVE_PATHS:
		_waves.append(load(p))

static func unit(id: StringName) -> UnitDef:
	_ensure()
	return _units[id]

static func relic(id: StringName) -> RelicDef:
	_ensure()
	return _relics[id]

static func recruits() -> Array[UnitDef]:
	_ensure()
	return _recruits

static func relics() -> Array:
	_ensure()
	return _relics.values()

static func synergies() -> Array[SynergyDef]:
	_ensure()
	return _synergies

static func waves() -> Array[WaveDef]:
	_ensure()
	return _waves

static func clear() -> void:
	_units.clear()
	_relics.clear()
	_synergies.clear()
	_waves.clear()
	_recruits.clear()
