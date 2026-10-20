## Runtime state for one unit. The definition is shared; this is per instance.
class_name SimUnit
extends RefCounted

var uid: int
var def: UnitDef
var team: int  # 0 = candles, 1 = gloom
var pos: Vector2
var hp: float
var max_hp: float
var shield: float = 0.0
var damage: float
var attack_interval: float
var speed: float
var attack_cd: float = 0.0
var summon_cd: float = 0.0
var target: SimUnit = null
var alive := true
var flash := 0.0
var slow_t := 0.0
var lane_bias := 0.0
var is_summon := false
var age := 0.0
var facing := 1.0
