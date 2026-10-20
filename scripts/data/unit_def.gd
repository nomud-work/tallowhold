## Read-only definition shared by every unit of this type (flyweight).
## Runtime state lives in SimUnit; never mutate a UnitDef at runtime.
class_name UnitDef
extends Resource

enum Family { WAX, FLAME, GLASS, GLOOM }
enum Role { TANK, MELEE, RANGED, HEALER, EXPLODER, SUMMONER, SLOWER, BOSS }

@export var id: StringName
@export var display_name: String = ""
@export_multiline var blurb: String = ""
@export var family: Family = Family.WAX
@export var role: Role = Role.MELEE
@export var recruitable: bool = true
@export var cost: int = 6
@export var squad_size: int = 3
@export var hp: int = 40
@export var damage: int = 6
@export var attack_interval: float = 1.0
@export var attack_range: float = 18.0
@export var speed: float = 60.0
@export var radius: float = 10.0
@export var projectile_speed: float = 0.0
## Healer: hp restored per cast. Slower: seconds of slow applied.
@export var support_power: float = 0.0
## Exploder / boss slam radius and damage.
@export var blast_radius: float = 0.0
@export var blast_damage: int = 0
## Summoner / boss: spawns summon_id every summon_interval seconds.
@export var summon_id: StringName = &""
@export var summon_interval: float = 0.0
@export var summon_count: int = 0
@export var bounty: int = 0
@export var color: Color = Color.WHITE
