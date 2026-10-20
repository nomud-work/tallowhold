## Orchestrates one run: shop -> battle -> result, repeated until the boss
## falls or the wicks run out. Logic lives in RunState/BattleSim; this node
## only sequences phases, feeds input and shows the result.
class_name Game
extends Node2D

enum Phase { SHOP, INTRO, BATTLE, RESULT, END }

const DEFAULT_SEED := 10
const AUTO_STEP := 1.0

@onready var camera: ShakeCamera = $Camera
@onready var view: BattleView = $BattleView
@onready var hud: Hud = $UI/Hud
@onready var shop_panel: ShopPanel = $UI/ShopPanel

var run: RunState
var sim: BattleSim
var phase := Phase.SHOP
var autopilot := false
var pilot: ShopAutopilot
var quit_at_end := false
var perf := false
var _phase_t := 0.0
var _auto_t := 0.0
var _pending: Dictionary = {}
var _perf_t := 0.0
var _frames := 0
var _peak_units := 0
var _run_seed := DEFAULT_SEED
var _skip_to := 0

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	autopilot = args.has("--autopilot")
	quit_at_end = args.has("--quit-at-end")
	perf = args.has("--perf") or OS.has_feature("web")
	for a in args:
		if a.begins_with("--seed="):
			_run_seed = int(a.substr(7))
		elif a.begins_with("--wave="):
			_skip_to = int(a.substr(7))
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("window.location.search", true)
		if q is String and q.contains("autopilot"):
			autopilot = true
		if q is String and q.contains("wave="):
			_skip_to = int(q.get_slice("wave=", 1).get_slice("&", 0))
	view.impact.connect(camera.add_trauma)
	shop_panel.buy_requested.connect(_on_buy)
	shop_panel.reroll_requested.connect(_on_reroll)
	shop_panel.fight_requested.connect(_on_fight)
	new_run()

func new_run() -> void:
	run = RunState.new(_run_seed)
	pilot = ShopAutopilot.new(ShopAutopilot.Style.PLANNER, _run_seed)
	hud.run = run
	shop_panel.run = run
	hud.mode_text = "seed %d  |  %s" % [_run_seed, "autopilot" if autopilot else "1-3 buy   R reroll   SPACE fight"]
	_peak_units = 0
	if _skip_to > 1:
		_fast_forward(_skip_to)
	_enter_shop()

## Test hook: plays earlier waves instantly (headless sim + planner shop) so
## perf checks can start at a crowded wave. Same seed, same result as watching.
func _fast_forward(to_wave: int) -> void:
	while not run.is_over() and run.wave_index < to_wave - 1:
		run.shop.open_new()
		for guard in 20:
			var a := pilot.next_action(run)
			if a.type == "done" or not pilot.apply(a, run):
				break
		var s := BattleSim.new()
		s.setup(run.army, run.build_mods(), run.current_wave(), run.battle_seed())
		var o := s.run_to_end()
		var k := s.kills
		s.dispose()
		run.finish_battle(o == BattleSim.Outcome.WON, k)

func _enter_shop() -> void:
	phase = Phase.SHOP
	_phase_t = 0.0
	_auto_t = 0.0
	run.shop.open_new()
	shop_panel.visible = true
	_rebuild_preview()

## The army stands in formation while you shop, so each recruit shows up.
func _rebuild_preview() -> void:
	if sim != null:
		sim.dispose()
	sim = BattleSim.new()
	sim.setup(run.army, run.build_mods(), run.current_wave(), run.battle_seed())
	view.sim = sim
	hud.sim = sim
	sim.events.clear()

func _on_buy(i: int) -> void:
	if phase == Phase.SHOP and run.shop.buy(i, run):
		_rebuild_preview()
		camera.add_trauma(0.12)

func _on_reroll() -> void:
	if phase == Phase.SHOP and run.shop.reroll(run.wallet):
		camera.add_trauma(0.08)

func _on_fight() -> void:
	if phase != Phase.SHOP:
		return
	shop_panel.visible = false
	_rebuild_preview()
	phase = Phase.INTRO
	_phase_t = 0.0
	var w := run.current_wave()
	var col := Color(0.85, 0.65, 1.0) if w.is_boss else Color(1.0, 0.86, 0.6)
	hud.banner(("BOSS - " if w.is_boss else "WAVE %d - " % (run.wave_index + 1)) + w.title.to_upper(),
		"%d candles vs %d gloom" % [sim.alive_count[0], w.total_count()], col, 0.9)
	camera.add_trauma(0.15)

func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	var k: int = e.physical_keycode
	if phase == Phase.SHOP and not autopilot:
		if k >= KEY_1 and k <= KEY_3:
			_on_buy(k - KEY_1)
		elif k == KEY_R:
			_on_reroll()
		elif k == KEY_SPACE or k == KEY_ENTER:
			_on_fight()
	elif phase == Phase.END and (k == KEY_R or k == KEY_SPACE or k == KEY_ENTER):
		view.clear_fx()
		new_run()

func _physics_process(_delta: float) -> void:
	if phase == Phase.BATTLE:
		sim.step()
		_peak_units = maxi(_peak_units, sim.alive_count[0] + sim.alive_count[1])
		if sim.outcome != BattleSim.Outcome.RUNNING:
			_finish_battle()

func _process(delta: float) -> void:
	_phase_t += delta
	match phase:
		Phase.SHOP:
			if autopilot:
				_autopilot_shop(delta)
		Phase.INTRO:
			if _phase_t >= 1.4:
				phase = Phase.BATTLE
				_phase_t = 0.0
		Phase.RESULT:
			if _phase_t >= 2.4:
				if run.is_over():
					_end_run()
				else:
					_enter_shop()
		Phase.END:
			if quit_at_end and _phase_t >= 4.0:
				get_tree().quit()
	if perf:
		_frames += 1
		_perf_t += delta
		if _perf_t >= 5.0:
			print("PERF fps=%.1f units=%d draw_calls=%d phase=%s wave=%d" % [_frames / _perf_t,
				(sim.alive_count[0] + sim.alive_count[1]) if sim else 0,
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), Phase.keys()[phase], run.wave_index + 1])
			_frames = 0
			_perf_t = 0.0

func _autopilot_shop(delta: float) -> void:
	_auto_t += delta
	if _pending.is_empty():
		if _auto_t < AUTO_STEP:
			return
		_auto_t = 0.0
		_pending = pilot.next_action(run)
		match _pending.type:
			"buy":
				shop_panel.flash_choice(_pending.index)
			"reroll":
				shop_panel.flash_choice(10)
			_:
				shop_panel.flash_choice(11)
	elif _auto_t >= 0.45:
		var a := _pending
		_pending = {}
		_auto_t = 0.0
		match a.type:
			"buy":
				_on_buy(a.index)
			"reroll":
				_on_reroll()
			_:
				_on_fight()

func _finish_battle() -> void:
	var won := sim.outcome == BattleSim.Outcome.WON
	var was_boss := run.current_wave().is_boss
	var reward := run.finish_battle(won, sim.kills)
	run.peak_units = maxi(run.peak_units, _peak_units)
	phase = Phase.RESULT
	_phase_t = 0.0
	if won:
		if was_boss:
			hud.banner("THE MATRIARCH FALLS", "%d gloom snuffed out" % sim.kills, Color(1.0, 0.86, 0.5), 1.6)
			camera.add_trauma(0.8)
		else:
			hud.banner("WAVE CLEARED", "+%d gold" % reward, Color(0.6, 1.0, 0.7), 1.4)
	else:
		hud.banner("A WICK GOES OUT", "%d wicks left  -  +%d gold" % [run.wicks, reward], Color(1.0, 0.45, 0.4), 1.4)
		camera.add_trauma(0.35)

func _end_run() -> void:
	phase = Phase.END
	_phase_t = 0.0
	if run.victory:
		hud.banner("TALLOWHOLD STANDS", "Victory in %d battles  -  %d gloom defeated" % [run.battles_fought, run.total_kills], Color(1.0, 0.86, 0.5), 30.0)
	else:
		hud.banner("THE GLOOM WINS", "Reached wave %d  -  press R to retry" % (run.wave_index + 1), Color(0.8, 0.6, 1.0), 30.0)
	var stats := {"seed": run.run_seed, "victory": run.victory, "battles_fought": run.battles_fought,
		"battles_won": run.battles_won, "wicks_left": run.wicks, "kills": run.total_kills,
		"peak_units": run.peak_units, "army_squads": run.army.size(), "relics": run.relics.size(),
		"purchases": run.purchases, "gold_left": run.wallet.gold}
	print("STATS ", JSON.stringify(stats))

func _exit_tree() -> void:
	if sim != null:
		sim.dispose()
	Catalog.clear()
