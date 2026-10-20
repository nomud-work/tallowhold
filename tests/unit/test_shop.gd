extends GdUnitTestSuite

func test_three_distinct_offers() -> void:
	var run := RunState.new(11)
	run.shop.open_new()
	assert_int(run.shop.offers.size()).is_equal(3)
	var keys := {}
	for o in run.shop.offers:
		keys[o.key] = true
	assert_int(keys.size()).is_equal(3)

func test_same_seed_same_offers() -> void:
	var a := RunState.new(42)
	var b := RunState.new(42)
	a.shop.open_new()
	b.shop.open_new()
	for i in 3:
		assert_str(a.shop.offers[i].key).is_equal(b.shop.offers[i].key)

func test_buy_spends_gold_and_adds_to_army() -> void:
	var run := RunState.new(3)
	run.wallet.gold = 100
	run.shop.open_new()
	var o: Dictionary = run.shop.offers[0]
	var army_before := run.army.size()
	var relics_before := run.relics.size()
	assert_bool(run.shop.buy(0, run)).is_true()
	assert_int(run.wallet.gold).is_equal(100 - o.cost)
	assert_int(run.army.size() + run.relics.size()).is_equal(army_before + relics_before + 1)
	assert_bool(run.shop.buy(0, run)).is_false()  # already sold

func test_cannot_buy_without_gold() -> void:
	var run := RunState.new(3)
	run.wallet.gold = 0
	run.shop.open_new()
	assert_bool(run.shop.buy(1, run)).is_false()
	assert_int(run.army.size()).is_equal(RunState.START_ARMY.size())

func test_reroll_cost_rises() -> void:
	var run := RunState.new(5)
	run.wallet.gold = 20
	run.shop.open_new()
	assert_int(run.shop.reroll_cost()).is_equal(2)
	assert_bool(run.shop.reroll(run.wallet)).is_true()
	assert_int(run.wallet.gold).is_equal(18)
	assert_int(run.shop.reroll_cost()).is_equal(3)
