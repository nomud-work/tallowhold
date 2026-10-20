extends GdUnitTestSuite

func test_spend_only_when_affordable() -> void:
	var w := Wallet.new(10)
	assert_bool(w.try_spend(7)).is_true()
	assert_int(w.gold).is_equal(3)
	assert_bool(w.try_spend(4)).is_false()
	assert_int(w.gold).is_equal(3)

func test_negative_cost_rejected() -> void:
	var w := Wallet.new(5)
	assert_bool(w.try_spend(-3)).is_false()
	assert_int(w.gold).is_equal(5)

func test_earn_ignores_non_positive() -> void:
	var w := Wallet.new(0)
	w.earn(0)
	w.earn(-4)
	w.earn(6)
	assert_int(w.gold).is_equal(6)
