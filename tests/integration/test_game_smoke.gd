extends GdUnitTestSuite

func test_main_scene_autopilot_reaches_battle() -> void:
	var runner := scene_runner("res://scenes/main.tscn")
	var game: Game = runner.scene()
	game.autopilot = true
	assert_int(game.phase).is_equal(Game.Phase.SHOP)
	await runner.simulate_frames(600, 16)
	assert_int(game.phase).is_not_equal(Game.Phase.SHOP)
	assert_int(game.run.army.size()).is_greater(RunState.START_ARMY.size())
