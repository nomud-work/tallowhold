## Trauma-based noise shake, adapted from the community GDAS
## camera_shake_trauma_pro pattern. Seeded so recordings repeat exactly.
class_name ShakeCamera
extends Camera2D

@export var decay := 1.6
@export var max_offset := Vector2(18, 12)
@export var max_roll := 0.02

var trauma := 0.0
var _noise := FastNoiseLite.new()
var _t := 0.0

func _ready() -> void:
	_noise.seed = 1337
	_noise.frequency = 0.9

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	_t += delta * 60.0
	trauma = maxf(trauma - decay * delta, 0.0)
	var s := trauma * trauma
	offset = Vector2(max_offset.x * s * _noise.get_noise_2d(11.0, _t), max_offset.y * s * _noise.get_noise_2d(37.0, _t))
	rotation = max_roll * s * _noise.get_noise_2d(73.0, _t)
