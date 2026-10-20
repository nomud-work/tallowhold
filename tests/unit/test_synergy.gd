extends GdUnitTestSuite

func test_two_wax_squads_unlock_first_tier() -> void:
	var run := RunState.new(1)
	# Start army is Tallowguard + Wickthrower: two WAX squads.
	var active := run.active_synergies()
	assert_int(active.size()).is_equal(1)
	assert_int(active[0].family).is_equal(UnitDef.Family.WAX)
	assert_int(active[0].threshold).is_equal(2)

func test_four_flame_squads_unlock_both_tiers() -> void:
	var run := RunState.new(1)
	run.army.append_array([&"sparkrunner", &"fusepot", &"flarecaster", &"sparkrunner"])
	var flame := run.active_synergies().filter(func(s): return s.family == UnitDef.Family.FLAME)
	assert_int(flame.size()).is_equal(2)

func test_mods_apply_family_and_relic_bonuses() -> void:
	var run := RunState.new(1)
	run.relics.append(&"beeswax_coat")
	var mods := run.build_mods()
	var guard := Catalog.unit(&"tallowguard")
	var spark := Catalog.unit(&"sparkrunner")
	# Wax 2 tier (+50% wax hp) stacks with the relic (+20% all hp).
	assert_float(mods.hp_mult(guard)).is_equal_approx(1.2 * 1.5, 0.001)
	assert_float(mods.hp_mult(spark)).is_equal_approx(1.2, 0.001)
