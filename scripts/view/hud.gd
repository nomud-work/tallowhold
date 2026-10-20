## Top bar, family synergy chips, boss bar and the big banner.
class_name Hud
extends Control

var run: RunState
var sim: BattleSim
var mode_text := ""
var _banner: Label
var _sub: Label
var _tween: Tween
var _f_title: Font
var _f_data: Font
var _f_small: Font

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_f_title = Fonts.display(900)
	_f_data = Fonts.data(700)
	_f_small = Fonts.data(500)
	_banner = _make_label(Fonts.display(900), 72)
	_banner.position = Vector2(0, 250)
	_sub = _make_label(Fonts.data(700), 24)
	_sub.position = Vector2(0, 345)

func _make_label(font: Font, size: int) -> Label:
	var l := Label.new()
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.08))
	l.add_theme_constant_override("outline_size", 12)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(1280, 90)
	l.pivot_offset = Vector2(640, 45)
	l.modulate.a = 0.0
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l

func banner(text: String, sub: String, color: Color, hold: float = 1.2) -> void:
	if _tween:
		_tween.kill()
	_banner.text = text
	_sub.text = sub
	_banner.add_theme_color_override("font_color", color)
	_sub.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	_banner.scale = Vector2(1.6, 1.6)
	_tween = create_tween().bind_node(self)
	_tween.set_parallel(true)
	_tween.tween_property(_banner, "modulate:a", 1.0, 0.15)
	_tween.tween_property(_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_sub, "modulate:a", 1.0, 0.25).set_delay(0.1)
	# chain() only applies to the next tweener, so each sequential step gets its own.
	_tween.chain().tween_interval(hold)
	_tween.chain().tween_property(_banner, "modulate:a", 0.0, 0.3)
	_tween.tween_property(_sub, "modulate:a", 0.0, 0.3)

func _process(_d: float) -> void:
	queue_redraw()

func _text(pos: Vector2, s: String, font: Font, size: int, c: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	draw_string(font, pos, s, align, width, size, c)

func _draw() -> void:
	if run == null:
		return
	draw_rect(Rect2(0, 0, 1280, 88), Color(0.05, 0.035, 0.07, 0.96))
	draw_rect(Rect2(0, 87, 1280, 2), Color(1.0, 0.7, 0.35, 0.35))
	_text(Vector2(40, 42), "TALLOWHOLD", _f_title, 32, Color(1.0, 0.86, 0.6))
	_text(Vector2(42, 70), "candles vs the gloom", _f_small, 15, Color(1, 1, 1, 0.55))
	var w := run.current_wave()
	_text(Vector2(300, 38), "WAVE %d/%d" % [run.wave_index + 1, run.wave_count()], _f_data, 22, Color(1, 1, 1))
	_text(Vector2(300, 66), w.title.to_upper() + ("  (BOSS)" if w.is_boss else ""), _f_small, 15, Color(1.0, 0.8, 0.55) if not w.is_boss else Color(0.85, 0.65, 1.0))
	_text(Vector2(568, 38), "GOLD %d" % run.wallet.gold, _f_data, 22, Color(1.0, 0.84, 0.3))
	_text(Vector2(568, 66), "WICKS", _f_small, 15, Color(1, 1, 1, 0.6))
	for i in RunState.START_WICKS:
		var x := 626.0 + i * 20.0
		var lit := i < run.wicks
		draw_rect(Rect2(x, 52, 9, 16), Color(0.95, 0.9, 0.78) if lit else Color(0.35, 0.3, 0.3))
		if lit:
			draw_circle(Vector2(x + 4.5, 47), 4.5, Color(1.0, 0.7, 0.25))
			draw_circle(Vector2(x + 4.5, 48), 2.2, Color(1.0, 0.95, 0.75))
	var counts := run.family_counts()
	for f in 3:
		var x := 724.0 + f * 124.0
		var col := Catalog.FAMILY_COLORS[f]
		var tier := 0
		if counts[f] >= 4:
			tier = 2
		elif counts[f] >= 2:
			tier = 1
		var bg := Color(col, 0.10 + tier * 0.14)
		draw_rect(Rect2(x, 16, 114, 56), bg)
		draw_rect(Rect2(x, 16, 4, 56), col)
		_text(Vector2(x + 12, 40), Catalog.FAMILY_NAMES[f], _f_data, 17, col)
		_text(Vector2(x + 12, 63), "%d/2  %d/4" % [mini(counts[f], 2), mini(counts[f], 4)], _f_small, 14, Color(1, 1, 1, 0.5 + tier * 0.25))
		for k in 2:
			var on := tier > k
			draw_circle(Vector2(x + 88 + k * 14, 34), 5, col if on else Color(col, 0.2))
	if sim != null:
		_text(Vector2(1100, 38), "CANDLES %d" % sim.alive_count[0], _f_data, 18, Color(1.0, 0.86, 0.6), HORIZONTAL_ALIGNMENT_RIGHT, 140)
		_text(Vector2(1100, 64), "GLOOM %d" % (sim.alive_count[1] + sim.pending_spawns()), _f_data, 18, Color(0.8, 0.6, 1.0), HORIZONTAL_ALIGNMENT_RIGHT, 140)
		for u in sim.units:
			if u.alive and u.def.role == UnitDef.Role.BOSS:
				var bw := 600.0
				var bx := 340.0
				draw_rect(Rect2(bx - 2, 668, bw + 4, 18), Color(0.05, 0.02, 0.08, 0.9))
				draw_rect(Rect2(bx, 670, bw * clampf(u.hp / u.max_hp, 0.0, 1.0), 14), Color(0.75, 0.45, 1.0))
				_text(Vector2(bx, 662), u.def.display_name.to_upper(), _f_data, 16, Color(0.9, 0.8, 1.0))
	_text(Vector2(1240, 712), mode_text, _f_small, 13, Color(1, 1, 1, 0.45), HORIZONTAL_ALIGNMENT_RIGHT, 600)
