## Monte Carlo balance pass, following the community GDAS
## godot-monte-carlo-balancer method: many seeded full runs per play style,
## win rate with a 95% Wilson interval, checked against BALANCE_PLAN.md bands.
## Usage: godot --headless --path . -s res://tools/balance_runner.gd -- --runs 200 [--out path]
extends SceneTree

const BANDS := {"PLANNER": [0.55, 0.90], "RANDOM": [0.15, 0.60], "AFK": [0.0, 0.10]}

func _init() -> void:
	var runs := 200
	var out_path := ""
	var only := ""
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--runs":
			runs = int(args[i + 1])
		elif args[i] == "--style":
			only = args[i + 1]
		elif args[i] == "--out":
			out_path = args[i + 1]
	var report := {"runs_per_style": runs, "styles": {}}
	var t0 := Time.get_ticks_msec()
	for style_name in ["PLANNER", "RANDOM", "AFK"]:
		if only != "" and style_name != only:
			continue
		var style: int = ShopAutopilot.Style[style_name]
		var wins := 0
		var waves_won := 0
		var reached := PackedInt32Array()
		reached.resize(8)
		var peak := 0
		var wave_losses := PackedInt32Array()
		wave_losses.resize(7)
		for r in runs:
			var res := play_run(1000 + r, style)
			if res.victory:
				wins += 1
			waves_won += res.won
			reached[res.furthest] += 1
			peak = maxi(peak, res.peak)
			for w in res.losses:
				wave_losses[w] += 1
		var ci := wilson(wins, runs)
		var band: Array = BANDS[style_name]
		var verdict := "OK"
		if ci[1] < band[0]:
			verdict = "TOO_HARD"
		elif ci[0] > band[1]:
			verdict = "TOO_EASY"
		elif ci[0] < band[0] or ci[1] > band[1]:
			verdict = "OK_OVERLAP"
		report.styles[style_name] = {
			"win_rate": snappedf(float(wins) / runs, 0.001), "ci95": [snappedf(ci[0], 0.001), snappedf(ci[1], 0.001)],
			"band": band, "verdict": verdict, "avg_battles_won": snappedf(float(waves_won) / runs, 0.01),
			"losses_by_wave": Array(wave_losses), "peak_units": peak,
		}
		print(style_name, " win ", snappedf(float(wins) / runs, 0.001), " ci ", ci, " ", verdict, " losses_by_wave ", wave_losses, " peak ", peak)
	report["seconds"] = (Time.get_ticks_msec() - t0) / 1000.0
	if out_path != "":
		var f := FileAccess.open(out_path, FileAccess.WRITE)
		f.store_string(JSON.stringify(report, "  "))
	print("BALANCE ", JSON.stringify(report))
	Catalog.clear()
	quit()

static func play_run(seed_value: int, style: int) -> Dictionary:
	var run := RunState.new(seed_value)
	var pilot := ShopAutopilot.new(style, seed_value)
	var peak := 0
	var losses: Array[int] = []
	while not run.is_over():
		run.shop.open_new()
		for guard in 20:
			var a := pilot.next_action(run)
			if a.type == "done" or not pilot.apply(a, run):
				break
		var sim := BattleSim.new()
		sim.setup(run.army, run.build_mods(), run.current_wave(), run.battle_seed())
		var o := sim.run_to_end()
		peak = maxi(peak, sim.peak_alive)
		var won := o == BattleSim.Outcome.WON
		if not won:
			losses.append(run.wave_index)
		var kills := sim.kills
		sim.dispose()
		run.finish_battle(won, kills)
	return {"victory": run.victory, "won": run.battles_won, "furthest": mini(run.wave_index + (1 if run.victory else 0), 7), "peak": peak, "losses": losses}

static func wilson(k: int, n: int) -> Array:
	var z := 1.96
	var p := float(k) / n
	var den := 1.0 + z * z / n
	var c := (p + z * z / (2.0 * n)) / den
	var h := z * sqrt(p * (1.0 - p) / n + z * z / (4.0 * n * n)) / den
	return [maxf(c - h, 0.0), minf(c + h, 1.0)]
