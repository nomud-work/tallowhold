## Draws the whole battle in one _draw call: floor, units, shots, particles,
## rings and damage numbers. Reads BattleSim state; never changes it.
class_name BattleView
extends Node2D

signal impact(trauma: float)

const MAX_FX := 700
const MAX_NUMBERS := 90
const WAX_GLOW := Color(1.0, 0.72, 0.38, 0.06)
const GLOOM_GLOW := Color(0.6, 0.3, 1.0, 0.07)
## Units are drawn larger than their collision radius so they read on video.
const VIS := 1.45

var sim: BattleSim
var time := 0.0
var _rng := RandomNumberGenerator.new()
var _dust: PackedVector3Array = PackedVector3Array()
# particles
var _fx_pos := PackedVector2Array()
var _fx_vel := PackedVector2Array()
var _fx_life := PackedFloat32Array()
var _fx_max := PackedFloat32Array()
var _fx_size := PackedFloat32Array()
var _fx_col := PackedColorArray()
# rings: [pos, r_from, r_to, life, max, color, width]
var _rings: Array = []
# numbers: [pos, text, life, color, size]
var _numbers: Array = []
var _font: Font
## One small atlas (solid disc | ring | soft glow) so nearly every shape is a
## textured rect from the same texture, which the 2D renderer can batch.
var _atlas: ImageTexture
const REG_DISC := Rect2(0, 0, 64, 64)
const REG_RING := Rect2(64, 0, 64, 64)
const REG_SOFT := Rect2(128, 0, 64, 64)
const REG_SOLID := Rect2(28, 28, 8, 8)
const UV_SOLID := Vector2(32.0 / 192.0, 0.5)
var _font_big: Font
## Character sprites live in the same atlas (art/characters_atlas.png, drawn as SVG
## in art-src/), so sprites, particles and rings still batch as one texture.
const SHEET := preload("res://art/characters_atlas.png")
const CELL := 80.0
const CELL_H := 112.0
const BOSS_CELL := 192.0
const REG_FLAME := [Rect2(192, 0, 64, 64), Rect2(256, 0, 64, 64)]
## id -> [cell index, flame: [anchor (0-1 in the cell), height (0-1), 0 warm | 1 cold] or null]
const SPRITES := {
	&"tallowguard": [0, [Vector2(0.500, 0.150), 0.121, 0]],
	&"wickthrower": [1, [Vector2(0.490, 0.136), 0.114, 0]],
	&"drip_matron": [2, [Vector2(0.500, 0.171), 0.121, 0]],
	&"waxling": [3, [Vector2(0.500, 0.314), 0.100, 0]],
	&"sparkrunner": [4, [Vector2(0.480, 0.143), 0.121, 0]],
	&"fusepot": [5, [Vector2(0.590, 0.171), 0.107, 0]],
	&"flarecaster": [6, [Vector2(0.500, 0.129), 0.121, 0]],
	&"lensmender": [7, [Vector2(0.500, 0.143), 0.114, 1]],
	&"prismshot": [8, [Vector2(0.500, 0.136), 0.114, 1]],
	&"moth": [9, null],
	&"gloomwisp": [10, null],
	&"husk": [11, null],
}
## Sprite height as a multiple of the drawn radius (r = radius * VIS).
const SPRITE_SCALE := 4.2
const GLOOM_SCALE := 4.0
const BOSS_SIZE := 210.0
## --shapes draws the original flat shapes (used for the before/after frame).
var use_sprites := true
## uid -> Vector3(last x, last y, smoothed "is walking" 0..1); view-only, never read by the sim.
var _gait: Dictionary = {}
var _order: Array = []

func _ready() -> void:
	_rng.seed = 4242
	use_sprites = not OS.get_cmdline_user_args().has("--shapes")
	_atlas = _make_atlas()
	_font = Fonts.data(800)
	_font_big = Fonts.display(900)
	for i in 70:
		_dust.append(Vector3(_rng.randf_range(40, 1240), _rng.randf_range(96, 696), _rng.randf_range(1.0, 3.5)))

func clear_fx() -> void:
	_fx_pos.clear(); _fx_vel.clear(); _fx_life.clear(); _fx_max.clear(); _fx_size.clear(); _fx_col.clear()
	_rings.clear()
	_numbers.clear()
	_gait.clear()

func _process(delta: float) -> void:
	time += delta
	if sim != null:
		_drain_events()
	_update_fx(delta)
	queue_redraw()

func _drain_events() -> void:
	for e in sim.events:
		var kind: int = e[0]
		var p: Vector2 = e[1]
		match kind:
			BattleSim.Ev.HIT:
				var dmg: float = e[2]
				var col := Color(1.0, 0.42, 0.36) if e[3] == 0 else Color(1.0, 0.93, 0.62)
				_spark(p, 3, col, 120.0, 0.25, 2.0)
				if dmg >= 1.0:
					_number(p + Vector2(_rng.randf_range(-8, 8), -e[4] * VIS - 6.0), str(int(round(dmg))), col, 15 if dmg < 20.0 else 22)
			BattleSim.Ev.HEAL:
				_number(p + Vector2(0, -16), "+" + str(int(e[2])), Color(0.55, 1.0, 0.7), 14)
				_spark(p, 4, Color(0.55, 1.0, 0.75), 50.0, 0.5, 2.5, Vector2(0, -60))
				_ring(p, 4.0, 18.0, 0.3, Color(0.55, 1.0, 0.75, 0.8), 2.0)
			BattleSim.Ev.DEATH:
				var r: float = e[2]
				var c: Color = e[4]
				_ring(p, r * 0.5, r * 2.6, 0.32, Color(c, 0.9), 3.0)
				_spark(p, 7 + int(r * 0.4), c.lightened(0.3), 170.0 + r * 4.0, 0.45, 3.0)
				_spark(p, 4, Color(1, 1, 1), 90.0, 0.2, 3.5)
				if r >= 14.0:
					impact.emit(0.18 if r < 30.0 else 0.9)
			BattleSim.Ev.BLAST:
				var br: float = e[2]
				_ring(p, 6.0, br, 0.35, Color(1.0, 0.65, 0.25, 0.95), 5.0)
				_ring(p, 2.0, br * 0.6, 0.25, Color(1.0, 0.95, 0.7, 0.9), 3.0)
				_spark(p, 18, Color(1.0, 0.6, 0.2), 300.0, 0.5, 3.5)
				impact.emit(0.22)
			BattleSim.Ev.SLAM:
				_ring(p, 10.0, e[2], 0.45, Color(0.78, 0.55, 1.0, 0.95), 6.0)
				_spark(p, 22, Color(0.7, 0.45, 1.0), 260.0, 0.6, 3.5)
				impact.emit(0.4)
			BattleSim.Ev.SUMMON:
				_ring(p, 2.0, 16.0, 0.3, Color(e[4], 0.8), 2.0)
			BattleSim.Ev.SHOT:
				_spark(p, 2, Color(e[4]).lightened(0.4), 60.0, 0.15, 2.0)
	sim.events.clear()

func _spark(p: Vector2, n: int, c: Color, spd: float, life: float, size: float, bias := Vector2.ZERO) -> void:
	for i in n:
		if _fx_pos.size() >= MAX_FX:
			return
		var a := _rng.randf() * TAU
		_fx_pos.append(p)
		_fx_vel.append(Vector2(cos(a), sin(a)) * spd * _rng.randf_range(0.35, 1.0) + bias)
		var l := life * _rng.randf_range(0.6, 1.0)
		_fx_life.append(l)
		_fx_max.append(l)
		_fx_size.append(size * _rng.randf_range(0.7, 1.3))
		_fx_col.append(c)

func _ring(p: Vector2, r0: float, r1: float, life: float, c: Color, w: float) -> void:
	if _rings.size() < 120:
		_rings.append([p, r0, r1, life, life, c, w])

func _number(p: Vector2, text: String, c: Color, size: int) -> void:
	if _numbers.size() >= MAX_NUMBERS:
		_numbers.pop_front()
	_numbers.append([p, text, 0.75, c, size])

func _update_fx(delta: float) -> void:
	var i := 0
	while i < _fx_pos.size():
		_fx_life[i] -= delta
		if _fx_life[i] <= 0.0:
			var last := _fx_pos.size() - 1
			_fx_pos[i] = _fx_pos[last]; _fx_vel[i] = _fx_vel[last]; _fx_life[i] = _fx_life[last]
			_fx_max[i] = _fx_max[last]; _fx_size[i] = _fx_size[last]; _fx_col[i] = _fx_col[last]
			_fx_pos.resize(last); _fx_vel.resize(last); _fx_life.resize(last)
			_fx_max.resize(last); _fx_size.resize(last); _fx_col.resize(last)
			continue
		_fx_pos[i] += _fx_vel[i] * delta
		_fx_vel[i] *= 0.9
		i += 1
	for r in _rings:
		r[3] -= delta
	_rings = _rings.filter(func(r): return r[3] > 0.0)
	for n in _numbers:
		n[2] -= delta
		n[0].y -= 38.0 * delta
	_numbers = _numbers.filter(func(n): return n[2] > 0.0)

func _draw() -> void:
	_draw_floor()
	if sim == null:
		return
	for u in sim.units:
		if u.alive and u.team == 0:
			_soft(u.pos, u.def.radius * VIS * 3.4, WAX_GLOW * Color(1, 1, 1, 2.2))
		elif u.alive:
			_soft(u.pos, u.def.radius * VIS * 2.2, GLOOM_GLOW * Color(1, 1, 1, 2.0))
	if use_sprites:
		_draw_sprites()
	else:
		for u in sim.units:
			if u.alive:
				_disc(u.pos + Vector2(0, u.def.radius * VIS * 0.8), u.def.radius * VIS * 0.9, Color(0, 0, 0, 0.35))
		for u in sim.units:
			if u.alive:
				if u.team == 0:
					_draw_candle(u)
				else:
					_draw_gloom(u)
	for s in sim.shots:
		if s.alive:
			var back := (s.aim - s.pos).normalized() * -10.0
			_disc(s.pos + back * 0.6, 2.2, Color(s.color, 0.45))
			_disc(s.pos + back * 0.3, 2.6, Color(s.color, 0.7))
			_disc(s.pos, 3.2, s.color.lightened(0.5))
	for i in _fx_pos.size():
		var k := _fx_life[i] / _fx_max[i]
		_disc(_fx_pos[i], _fx_size[i] * (0.4 + 0.6 * k), Color(_fx_col[i], k))
	for r in _rings:
		var k: float = 1.0 - r[3] / r[4]
		var rad: float = lerpf(r[1], r[2], 1.0 - pow(1.0 - k, 3.0))
		var c: Color = r[5]
		_ring_tex(r[0], rad, Color(c, c.a * (1.0 - k)))
	for n in _numbers:
		var a: float = clampf(n[2] / 0.35, 0.0, 1.0)
		var pos: Vector2 = n[0]
		var size: int = n[4]
		var w := _font.get_string_size(n[1], HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string_outline(_font, pos - Vector2(w * 0.5, 0), n[1], HORIZONTAL_ALIGNMENT_LEFT, -1, size, 4, Color(0.05, 0.02, 0.08, a))
		draw_string(_font, pos - Vector2(w * 0.5, 0), n[1], HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(n[3], a))

func _draw_floor() -> void:
	var a := BattleSim.ARENA
	# Warm hold on the left fading into the dark on the right.
	draw_polygon(PackedVector2Array([a.position, Vector2(a.end.x, a.position.y), a.end, Vector2(a.position.x, a.end.y)]),
		PackedColorArray([Color(0.16, 0.10, 0.07), Color(0.07, 0.05, 0.12), Color(0.06, 0.04, 0.11), Color(0.14, 0.09, 0.06)]))
	for x in range(int(a.position.x) + 60, int(a.end.x), 80):
		_rect(Rect2(x, a.position.y, 1, a.size.y), Color(1, 1, 1, 0.025))
	for y in range(int(a.position.y) + 60, int(a.end.y), 80):
		_rect(Rect2(a.position.x, y, a.size.x, 1), Color(1, 1, 1, 0.025))
	for d in _dust:
		var fl := 0.5 + 0.5 * sin(time * 0.8 + d.x)
		_soft(Vector2(d.x, d.y + sin(time * 0.5 + d.y) * 3.0), d.z * 2.0, Color(1.0, 0.8, 0.5, 0.05 + 0.05 * fl))
	draw_rect(a, Color(1.0, 0.8, 0.55, 0.18), false, 2.0)

func _flame(top: Vector2, r: float, uid: int) -> void:
	var fl := 1.0 + 0.18 * sin(time * 14.0 + uid * 1.7)
	_disc(top, r * 0.9 * fl, Color(1.0, 0.55, 0.15, 0.35))
	_disc(top, r * 0.55 * fl, Color(1.0, 0.75, 0.25))
	_disc(top + Vector2(0, r * 0.12), r * 0.28, Color(1.0, 0.97, 0.8))

func _draw_candle(u: SimUnit) -> void:
	var r := u.def.radius * VIS
	var p := u.pos
	var body := Color(1, 1, 1) if u.flash > 0.0 else u.def.color
	var edge := u.def.color.darkened(0.45)
	match u.def.role:
		UnitDef.Role.TANK:
			_box(p, Vector2(r * 1.9, r * 1.7), body, edge)
			_rect(Rect2(p + Vector2(-r * 0.95, -r * 0.1), Vector2(r * 1.9, r * 0.3)), edge.lightened(0.2))
			_flame(p + Vector2(0, -r * 1.05), r * 0.55, u.uid)
		UnitDef.Role.SUMMONER:
			_box(p, Vector2(r * 1.7, r * 1.9), body, edge)
			for k in 3:
				_disc(p + Vector2((k - 1) * r * 0.55, r * 0.95 + (k % 2) * 3.0), r * 0.22, body)
			_flame(p + Vector2(0, -r * 1.15), r * 0.6, u.uid)
		UnitDef.Role.EXPLODER:
			_disc(p, r * 1.0, edge)
			_disc(p, r * 0.85, body)
			_poly(PackedVector2Array([p + Vector2(-1, -r * 0.8), p + Vector2(1.5, -r * 0.8), p + Vector2(r * 0.45, -r * 1.4), p + Vector2(r * 0.35, -r * 1.45)]), Color(0.3, 0.2, 0.1))
			_flame(p + Vector2(r * 0.45, -r * 1.5), r * 0.4, u.uid)
		UnitDef.Role.SLOWER:
			var pts := PackedVector2Array([p + Vector2(0, -r * 1.2), p + Vector2(r * 0.9, 0), p + Vector2(0, r * 1.1), p + Vector2(-r * 0.9, 0)])
			_poly(pts, body)
			_disc(p, r * 0.3, Color(1, 1, 1, 0.8))
		UnitDef.Role.HEALER:
			_box(p, Vector2(r * 1.3, r * 1.8), body, edge)
			_disc(p + Vector2(0, -r * 0.1), r * 0.45, Color(0.85, 1.0, 1.0))
			_rect(Rect2(p + Vector2(-r * 0.12, -r * 0.45), Vector2(r * 0.24, r * 0.7)), Color(0.2, 0.7, 0.6))
			_rect(Rect2(p + Vector2(-r * 0.35, -r * 0.22), Vector2(r * 0.7, r * 0.24)), Color(0.2, 0.7, 0.6))
			_flame(p + Vector2(0, -r * 1.15), r * 0.5, u.uid)
		_:
			var w := 1.2 if u.def.role == UnitDef.Role.RANGED else 1.4
			_box(p, Vector2(r * w, r * 1.8), body, edge)
			_flame(p + Vector2(0, -r * 1.15), r * 0.55, u.uid)
	if u.shield > 0.0:
		_ring_tex(p, r * 1.5, Color(0.55, 0.95, 1.0, 0.7))
	if u.slow_t > 0.0:
		_ring_tex(p, r * 1.3, Color(0.6, 0.7, 1.0, 0.6))
	_hp_bar(u)

func _draw_sprites() -> void:
	_order.clear()
	for u in sim.units:
		if u.alive:
			_order.append(u)
	_order.sort_custom(func(a, b): return a.pos.y < b.pos.y)
	for u in _order:
		var h := _sprite_h(u)
		var w := h * 0.36
		draw_texture_rect_region(_atlas, Rect2(u.pos + Vector2(-w, h * 0.37 - w * 0.25), Vector2(w * 2.0, w * 0.5)), REG_DISC, Color(0, 0, 0, 0.32))
	for u in _order:
		_draw_sprite(u)

func _sprite_h(u: SimUnit) -> float:
	if u.def.role == UnitDef.Role.BOSS:
		return BOSS_SIZE
	return u.def.radius * VIS * (SPRITE_SCALE if u.team == 0 else GLOOM_SCALE)

## Walking is read from how far the unit moved since the last frame.
func _walk_amount(u: SimUnit) -> float:
	var g: Vector3 = _gait.get(u.uid, Vector3(u.pos.x, u.pos.y, 0.0))
	var moved := Vector2(g.x, g.y).distance_to(u.pos) > 0.05
	var k := lerpf(g.z, 1.0 if moved else 0.0, 0.25)
	_gait[u.uid] = Vector3(u.pos.x, u.pos.y, k)
	return k

func _draw_sprite(u: SimUnit) -> void:
	var boss := u.def.role == UnitDef.Role.BOSS
	var r := u.def.radius * VIS
	var p := u.pos
	var walk := _walk_amount(u)
	var ph := time * 11.0 + u.uid * 1.37
	var bob: float
	var sq: float
	var h: float
	var src: Rect2
	var white: Rect2
	var info = SPRITES.get(u.def.id)
	if boss:
		h = BOSS_SIZE
		src = Rect2(0, 64 + 2 * CELL_H, BOSS_CELL, BOSS_CELL)
		white = Rect2(192, 64 + 2 * CELL_H, BOSS_CELL, BOSS_CELL)
		bob = 4.0 + 4.0 * sin(time * 2.2)
		sq = 0.02 * sin(time * 4.4)
	else:
		h = r * (SPRITE_SCALE if u.team == 0 else GLOOM_SCALE)
		var i: int = info[0] if info != null else 0
		src = Rect2(i * CELL, 64, CELL, CELL_H)
		white = Rect2(i * CELL, 64 + CELL_H, CELL, CELL_H)
		var flyer := u.team == 1 and u.def.role != UnitDef.Role.TANK
		if flyer:
			bob = 2.0 + 2.5 * sin(time * 7.0 + u.uid)
			sq = 0.05 * sin(time * 14.0 + u.uid)
		else:
			bob = absf(sin(ph)) * h * 0.07 * walk
			sq = lerpf(0.025 * sin(time * 2.6 + u.uid), 0.07 * cos(ph * 2.0), walk)
	var sx := h * (1.0 + sq)
	var sy := h * (1.0 - sq)
	# Feet sit below the sim position so the body is centred on it.
	var feet_y := p.y + h * 0.4
	var rect := Rect2(p.x - sx * 0.5, feet_y - sy * 0.93 - bob, sx, sy)
	var flip := u.facing < 0.0
	# A negative width flips the texture in place (Godot keeps the rect's position).
	var dst := Rect2(rect.position, Vector2(-rect.size.x, rect.size.y)) if flip else rect
	draw_texture_rect_region(_atlas, dst, src)
	if u.flash > 0.0:
		draw_texture_rect_region(_atlas, dst, white, Color(1, 1, 1, clampf(u.flash / 0.12, 0.0, 1.0) * 0.9))
	if info != null and info[1] != null:
		var fl: Array = info[1]
		var a: Vector2 = fl[0]
		var ax := (1.0 - a.x) if flip else a.x
		var base := rect.position + Vector2(ax * sx, a.y * sy)
		var flick := 1.0 + 0.13 * sin(time * 13.0 + u.uid * 1.7) + 0.07 * sin(time * 29.0 + u.uid)
		var fh: float = fl[1] * sy * flick
		var cell := fh / 0.93
		var sway := sin(time * 6.0 + u.uid) * fh * 0.06
		var glow := Color(1.0, 0.7, 0.3, 0.16) if fl[2] == 0 else Color(0.5, 0.9, 1.0, 0.16)
		_soft(base + Vector2(sway, -fh * 0.45), fh * 1.1, glow)
		draw_texture_rect_region(_atlas, Rect2(base.x - cell * 0.5 + sway, base.y - cell * 0.96, cell, cell), REG_FLAME[fl[2]])
	var ring_r := r * 1.5 if not boss else 70.0
	if u.shield > 0.0:
		_ring_tex(p + Vector2(0, -sy * 0.3), ring_r, Color(0.55, 0.95, 1.0, 0.32))
	if u.slow_t > 0.0:
		_ring_tex(p + Vector2(0, -sy * 0.3), ring_r * 0.9, Color(0.6, 0.7, 1.0, 0.5))
	if not boss and u.hp < u.max_hp:
		var bw := maxf(r * 2.0, 16.0)
		var bp := Vector2(p.x - bw * 0.5, rect.position.y - 2.0)
		_rect(Rect2(bp, Vector2(bw, 3)), Color(0, 0, 0, 0.6))
		var col := Color(0.5, 1.0, 0.55) if u.team == 0 else Color(1.0, 0.4, 0.5)
		_rect(Rect2(bp, Vector2(bw * clampf(u.hp / u.max_hp, 0.0, 1.0), 3)), col)

func _box(p: Vector2, size: Vector2, body: Color, edge: Color) -> void:
	var rect := Rect2(p - size * 0.5, size)
	_rect(rect.grow(1.5), edge)
	_rect(rect, body)
	_rect(Rect2(rect.position + Vector2(size.x * 0.12, size.y * 0.1), Vector2(size.x * 0.18, size.y * 0.7)), Color(1, 1, 1, 0.25))

func _draw_gloom(u: SimUnit) -> void:
	var r := u.def.radius * (VIS if u.def.role != UnitDef.Role.BOSS else 1.15)
	var p := u.pos
	var flash := u.flash > 0.0
	var c := Color(1, 1, 1) if flash else u.def.color
	var dark := Color(0.12, 0.07, 0.16) if not flash else Color(1, 1, 1)
	match u.def.role:
		UnitDef.Role.MELEE:
			var flap := 0.55 + 0.45 * absf(sin(time * 18.0 + u.uid))
			var f := u.facing
			_poly(PackedVector2Array([p, p + Vector2(-f * r * 0.6, -r * 1.7 * flap), p + Vector2(-f * r * 1.5, -r * 0.6 * flap)]), c)
			_poly(PackedVector2Array([p, p + Vector2(-f * r * 0.6, r * 1.7 * flap), p + Vector2(-f * r * 1.5, r * 0.6 * flap)]), c.darkened(0.15))
			_disc(p, r * 0.55, dark)
			_disc(p + Vector2(f * r * 0.35, 0), r * 0.18, Color(1.0, 0.85, 0.3))
		UnitDef.Role.RANGED:
			var f := u.facing
			for k in 3:
				_disc(p + Vector2(-f * (k + 1) * r * 0.7, sin(time * 6.0 + u.uid + k) * 3.0), r * (0.55 - k * 0.14), Color(c, 0.5 - k * 0.12))
			_disc(p, r, Color(c, 0.35))
			_disc(p, r * 0.75, c)
			_disc(p + Vector2(f * r * 0.25, -r * 0.1), r * 0.25, Color(1, 1, 1))
		UnitDef.Role.TANK:
			_disc(p, r, dark if not flash else c)
			_disc(p, r * 0.85, c)
			for k in 3:
				_rect(Rect2(p + Vector2(-r * (0.62 - k * 0.1), -r * 0.45 + k * r * 0.38), Vector2(r * (1.24 - k * 0.2), r * 0.12)), dark)
		UnitDef.Role.BOSS:
			var flap := 0.8 + 0.2 * sin(time * 5.0)
			var wing := c.darkened(0.25)
			_disc(p, r * 2.4, Color(0.6, 0.3, 1.0, 0.08))
			_poly(PackedVector2Array([p, p + Vector2(r * 0.8, -r * 2.2 * flap), p + Vector2(r * 2.3, -r * 1.2 * flap), p + Vector2(r * 1.6, 0)]), wing)
			_poly(PackedVector2Array([p, p + Vector2(-r * 0.8, -r * 2.2 * flap), p + Vector2(-r * 2.3, -r * 1.2 * flap), p + Vector2(-r * 1.6, 0)]), wing)
			_poly(PackedVector2Array([p, p + Vector2(r * 1.5, r * 1.6 * flap), p + Vector2(r * 0.5, r * 1.8 * flap)]), wing.darkened(0.2))
			_poly(PackedVector2Array([p, p + Vector2(-r * 1.5, r * 1.6 * flap), p + Vector2(-r * 0.5, r * 1.8 * flap)]), wing.darkened(0.2))
			_disc(p + Vector2(r * 1.3, -r * 1.0 * flap), r * 0.3, Color(1.0, 0.85, 0.3, 0.8))
			_disc(p + Vector2(-r * 1.3, -r * 1.0 * flap), r * 0.3, Color(1.0, 0.85, 0.3, 0.8))
			_disc(p, r * 0.7, dark)
			_disc(p + Vector2(-r * 0.25, -r * 0.2), r * 0.14, Color(1.0, 0.3, 0.3))
			_disc(p + Vector2(r * 0.25, -r * 0.2), r * 0.14, Color(1.0, 0.3, 0.3))
	if u.slow_t > 0.0:
		_ring_tex(p, r * 1.3, Color(0.6, 0.7, 1.0, 0.7))
	if u.def.role != UnitDef.Role.BOSS:
		_hp_bar(u)

func _hp_bar(u: SimUnit) -> void:
	if u.hp >= u.max_hp:
		return
	var w := maxf(u.def.radius * VIS * 2.0, 16.0)
	var p := u.pos + Vector2(-w * 0.5, -u.def.radius * VIS * 1.9 - 4.0)
	_rect(Rect2(p, Vector2(w, 3)), Color(0, 0, 0, 0.6))
	var col := Color(0.5, 1.0, 0.55) if u.team == 0 else Color(1.0, 0.4, 0.5)
	_rect(Rect2(p, Vector2(w * clampf(u.hp / u.max_hp, 0.0, 1.0), 3)), col)


static func _make_atlas() -> ImageTexture:
	var img: Image = SHEET.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d := Vector2(x + 0.5 - 32.0, y + 0.5 - 32.0).length()
			img.set_pixel(x, y, Color(1, 1, 1, clampf(31.5 - d, 0.0, 1.0)))
			var ring := clampf(1.0 - absf(d - 28.5) / 3.0, 0.0, 1.0)
			img.set_pixel(x + 64, y, Color(1, 1, 1, ring))
			var soft := clampf(1.0 - d / 32.0, 0.0, 1.0)
			img.set_pixel(x + 128, y, Color(1, 1, 1, soft * soft))
	return ImageTexture.create_from_image(img)

func _disc(c: Vector2, r: float, col: Color) -> void:
	draw_texture_rect_region(_atlas, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), REG_DISC, col)

func _soft(c: Vector2, r: float, col: Color) -> void:
	draw_texture_rect_region(_atlas, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), REG_SOFT, col)

func _ring_tex(c: Vector2, r: float, col: Color) -> void:
	draw_texture_rect_region(_atlas, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), REG_RING, col)

func _rect(r: Rect2, col: Color) -> void:
	draw_texture_rect_region(_atlas, r, REG_SOLID, col)

func _poly(pts: PackedVector2Array, col: Color) -> void:
	var uvs := PackedVector2Array()
	uvs.resize(pts.size())
	uvs.fill(UV_SOLID)
	draw_primitive(pts, PackedColorArray([col]), uvs, _atlas)
