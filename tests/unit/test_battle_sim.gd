extends GdUnitTestSuite

func _battle(seed_value: int) -> BattleSim:
	var run := RunState.new(seed_value)
	run.army.append_array([&"sparkrunner", &"lensmender", &"fusepot"])
	var sim := BattleSim.new()
	sim.setup(run.army, run.build_mods(), Catalog.waves()[1], seed_value)
	sim.run_to_end()
	return sim

func test_battle_is_deterministic() -> void:
	var a := _battle(77)
	var b := _battle(77)
	assert_int(a.outcome).is_equal(b.outcome)
	assert_int(a.tick).is_equal(b.tick)
	assert_int(a.kills).is_equal(b.kills)
	assert_int(a.alive_count[0]).is_equal(b.alive_count[0])
	a.dispose()
	b.dispose()

func test_battle_ends() -> void:
	var a := _battle(5)
	assert_int(a.outcome).is_not_equal(BattleSim.Outcome.RUNNING)
	a.dispose()

func test_shield_soaks_damage_first() -> void:
	var sim := BattleSim.new()
	var run := RunState.new(1)
	sim.setup(run.army, run.build_mods(), Catalog.waves()[0], 1)
	var u: SimUnit = sim.units[0]
	u.shield = 10.0
	var hp := u.hp
	sim.deal_damage(u, 6.0, 1)
	assert_float(u.shield).is_equal_approx(4.0, 0.001)
	assert_float(u.hp).is_equal_approx(hp, 0.001)
	sim.deal_damage(u, 10.0, 1)
	assert_float(u.hp).is_equal_approx(hp - 6.0, 0.001)
	sim.dispose()

func test_exploder_death_damages_nearby_enemies() -> void:
	var sim := BattleSim.new()
	var run := RunState.new(1)
	run.army = [&"fusepot"]
	sim.setup(run.army, run.build_mods(), Catalog.waves()[0], 1)
	sim._release_spawns()
	var pot: SimUnit = sim.units[0]
	var moth := sim._add_unit(Catalog.unit(&"moth"), 1, pot.pos + Vector2(20, 0), false)
	var before := moth.hp
	sim.deal_damage(pot, 9999.0, 1)
	assert_bool(pot.alive).is_false()
	assert_float(moth.hp).is_less(before)
	sim.dispose()

func test_lost_battle_costs_a_wick() -> void:
	var run := RunState.new(1)
	run.finish_battle(false, 0)
	assert_int(run.wicks).is_equal(RunState.START_WICKS - 1)
	assert_int(run.wave_index).is_equal(1)
