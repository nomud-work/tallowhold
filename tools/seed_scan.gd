## Lists planner-autopilot results for a range of seeds (to pick a demo seed).
extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var from := int(args[0]) if args.size() > 0 else 1
	var to := int(args[1]) if args.size() > 1 else 20
	for s in range(from, to + 1):
		var r: Dictionary = load("res://tools/balance_runner.gd").play_run(s, ShopAutopilot.Style.PLANNER)
		print("SEED ", s, " ", JSON.stringify(r))
	Catalog.clear()
	quit()
