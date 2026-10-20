## The between-battle market. Emits requests; Game asks the run to apply them.
class_name ShopPanel
extends Control

signal buy_requested(index: int)
signal reroll_requested
signal fight_requested

const PANEL := Rect2(700, 104, 540, 596)

var run: RunState
var _cards: Array[Button] = []
var _reroll: Button
var _fight: Button
var _highlight := -1
var _highlight_t := 0.0
var _f_title: Font
var _f_data: Font
var _f_small: Font

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_f_title = Fonts.display(900)
	_f_data = Fonts.data(700)
	_f_small = Fonts.data(500)
	for i in Shop.OFFER_COUNT:
		var b := _make_button(Rect2(PANEL.position.x + 20, PANEL.position.y + 92 + i * 124, PANEL.size.x - 40, 112))
		b.pressed.connect(buy_requested.emit.bind(i))
		_cards.append(b)
	_reroll = _make_button(Rect2(PANEL.position.x + 20, PANEL.end.y - 128, 200, 52))
	_reroll.pressed.connect(reroll_requested.emit)
	_fight = _make_button(Rect2(PANEL.end.x - 260, PANEL.end.y - 128, 240, 52))
	_fight.pressed.connect(fight_requested.emit)

func _make_button(r: Rect2) -> Button:
	var b := Button.new()
	b.position = r.position
	b.size = r.size
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(s, empty)
	add_child(b)
	return b

## Autopilot shows what it is about to pick before it clicks.
func flash_choice(index: int) -> void:
	_highlight = index
	_highlight_t = 0.0

func _process(delta: float) -> void:
	_highlight_t += delta
	queue_redraw()

func _text(pos: Vector2, s: String, font: Font, size: int, c: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	draw_string(font, pos, s, align, width, size, c)

func _draw() -> void:
	if run == null or not visible:
		return
	draw_rect(PANEL, Color(0.06, 0.04, 0.09, 0.94))
	draw_rect(PANEL, Color(1.0, 0.75, 0.4, 0.4), false, 2.0)
	var x := PANEL.position.x + 24
	_text(Vector2(x, PANEL.position.y + 42), "CANDLE MARKET", _f_title, 30, Color(1.0, 0.86, 0.6))
	var w := run.current_wave()
	_text(Vector2(x, PANEL.position.y + 70), "Next: %s  -  %d gloom" % [w.title, w.total_count()], _f_small, 16, Color(1, 1, 1, 0.7))
	_text(Vector2(PANEL.end.x - 24, PANEL.position.y + 42), "%d GOLD" % run.wallet.gold, _f_data, 24, Color(1.0, 0.84, 0.3), HORIZONTAL_ALIGNMENT_RIGHT, 200)
	for i in _cards.size():
		_draw_card(i)
	var rr := Rect2(_reroll.position, _reroll.size)
	var can_reroll := run.wallet.can_afford(run.shop.reroll_cost())
	var hl_reroll := _highlight == 10 and _highlight_t < 0.6
	draw_rect(rr, Color(0.3, 0.22, 0.4, 0.9 if can_reroll else 0.35))
	if hl_reroll:
		draw_rect(rr.grow(3), Color(1, 1, 1, 0.9), false, 3.0)
	_text(rr.position + Vector2(0, 33), "REROLL  %dg" % run.shop.reroll_cost(), _f_data, 19, Color(1, 1, 1, 1.0 if can_reroll else 0.4), HORIZONTAL_ALIGNMENT_CENTER, rr.size.x)
	var fr := Rect2(_fight.position, _fight.size)
	var pulse := 0.5 + 0.5 * sin(_highlight_t * 6.0) if _highlight == 11 else 0.0
	draw_rect(fr, Color(1.0, 0.55, 0.2).lerp(Color(1.0, 0.85, 0.5), pulse))
	_text(fr.position + Vector2(0, 35), "LIGHT THE WICKS", _f_title, 22, Color(0.12, 0.05, 0.02), HORIZONTAL_ALIGNMENT_CENTER, fr.size.x)
	# army summary
	var y := PANEL.end.y - 54
	var squads := {}
	for id in run.army:
		squads[id] = int(squads.get(id, 0)) + 1
	var parts: Array[String] = []
	for id in squads:
		parts.append("%s x%d" % [Catalog.unit(id).display_name, squads[id]])
	# Wraps onto a second line instead of running off the panel.
	draw_multiline_string(_f_small, Vector2(x, y), "ARMY  " + ", ".join(parts), HORIZONTAL_ALIGNMENT_LEFT, PANEL.size.x - 48, 13, 2, Color(1, 1, 1, 0.75))
	var rel: Array[String] = []
	for r in run.relic_defs():
		rel.append(r.display_name)
	_text(Vector2(x, y + 38), "RELICS  " + (", ".join(rel) if not rel.is_empty() else "none yet"), _f_small, 13, Color(1.0, 0.84, 0.3, 0.8), HORIZONTAL_ALIGNMENT_LEFT, PANEL.size.x - 48)

func _draw_card(i: int) -> void:
	var b := _cards[i]
	var r := Rect2(b.position, b.size)
	if i >= run.shop.offers.size():
		return
	var o: Dictionary = run.shop.offers[i]
	var hover := b.is_hovered()
	var col: Color
	var title_text: String
	var line2: String
	var blurb: String
	if o.kind == "unit":
		var u := Catalog.unit(o.id)
		col = Catalog.FAMILY_COLORS[u.family]
		title_text = u.display_name
		line2 = "%s  -  %s  -  squad of %d" % [Catalog.FAMILY_NAMES[u.family], Catalog.ROLE_NAMES[u.role], u.squad_size]
		blurb = u.blurb
	else:
		var rl := Catalog.relic(o.id)
		col = Color(1.0, 0.84, 0.3)
		title_text = rl.display_name
		line2 = "RELIC"
		blurb = rl.blurb
	var affordable := run.wallet.can_afford(o.cost)
	if o.sold:
		# A bought card collapses to its name and a badge, so nothing overlaps.
		draw_rect(r, Color(col, 0.06))
		draw_rect(Rect2(r.position, Vector2(6, r.size.y)), Color(col, 0.35))
		_text(r.position + Vector2(22, 48), title_text, _f_title, 24, Color(1, 1, 1, 0.35))
		_text(r.position + Vector2(22, 74), line2, _f_data, 14, Color(col, 0.35))
		var br := Rect2(r.end.x - 150, r.position.y + 30, 132, 50)
		draw_rect(br, Color(0.6, 1.0, 0.7, 0.14))
		draw_rect(br, Color(0.6, 1.0, 0.7, 0.7), false, 2.0)
		_text(br.position + Vector2(0, 34), "BOUGHT", _f_title, 22, Color(0.6, 1.0, 0.7), HORIZONTAL_ALIGNMENT_CENTER, br.size.x)
		return
	draw_rect(r, Color(col, 0.13 if not hover else 0.2))
	draw_rect(Rect2(r.position, Vector2(6, r.size.y)), col)
	if _highlight == i and _highlight_t < 0.7:
		draw_rect(r.grow(3), Color(1, 1, 1, 0.9 - _highlight_t), false, 3.0)
	_text(r.position + Vector2(22, 36), title_text, _f_title, 24, Color(1, 1, 1))
	_text(r.position + Vector2(22, 62), line2, _f_data, 14, col)
	_text(r.position + Vector2(22, 90), blurb, _f_small, 14, Color(1, 1, 1, 0.7), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 150)
	var pr := Rect2(r.end.x - 110, r.position.y + 30, 92, 50)
	draw_rect(pr, Color(1.0, 0.84, 0.3, 0.9 if affordable else 0.25))
	_text(pr.position + Vector2(0, 33), "%dg" % o.cost, _f_data, 22, Color(0.12, 0.07, 0.0) if affordable else Color(1, 1, 1, 0.5), HORIZONTAL_ALIGNMENT_CENTER, pr.size.x)
