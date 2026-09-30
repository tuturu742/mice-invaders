extends "res://tests/test_case.gd"

const Formation = preload("res://scripts/formation.gd")


func test_initial_layout_with_defaults() -> void:
	var formation = Formation.new()
	assert_eq(formation.get_total_mice(), 50, "total mice")
	var positions = formation.get_positions()
	assert_eq(positions.size(), 50, "position count")
	assert_eq(positions[0], Vector2(100, 60), "first position")
	assert_eq(positions[49], Vector2(532, 252), "last position")
	assert_eq(formation.get_direction(), 1, "initial direction")


func test_plain_step_marches_right() -> void:
	var formation = Formation.new()
	var before = formation.get_positions()
	formation.step(20.0)
	var after = formation.get_positions()
	assert_eq(after.size(), before.size(), "count is unchanged")
	for i in before.size():
		assert_almost_eq(after[i].x, before[i].x + 20.0, 0.0001, "x advanced")
		assert_almost_eq(after[i].y, before[i].y, 0.0001, "y unchanged")
	assert_eq(formation.get_direction(), 1, "still moving right")


func test_edge_step_drops_and_reverses() -> void:
	var formation = Formation.new(1, 2, Vector2(10, 10), Vector2(0, 0), 0.0, 15.0)
	var initial = formation.get_positions()
	assert_eq(initial[0], Vector2(0, 0), "initial left mouse")
	assert_eq(initial[1], Vector2(10, 0), "initial right mouse")

	formation.step(20.0)
	var after_right = formation.get_positions()
	assert_almost_eq(after_right[0].x, 0.0, 0.0001, "left x held")
	assert_almost_eq(after_right[1].x, 10.0, 0.0001, "right x held")
	assert_almost_eq(after_right[0].y, 10.0, 0.0001, "left dropped a row")
	assert_almost_eq(after_right[1].y, 10.0, 0.0001, "right dropped a row")
	assert_eq(formation.get_direction(), -1, "reversed to left")

	formation.step(20.0)
	var after_left = formation.get_positions()
	assert_almost_eq(after_left[0].y, 20.0, 0.0001, "left dropped again")
	assert_almost_eq(after_left[1].y, 20.0, 0.0001, "right dropped again")
	assert_eq(formation.get_direction(), 1, "reversed to right")


func test_speed_increases_as_mice_are_lost() -> void:
	var formation = Formation.new()
	assert_almost_eq(formation.speed_for_remaining(50), 20.0, 0.0001, "full strength")
	assert_almost_eq(formation.speed_for_remaining(25), 40.0, 0.0001, "half strength")
	assert_almost_eq(formation.speed_for_remaining(1), 1000.0, 0.0001, "one mouse left")
	assert_true(
		formation.speed_for_remaining(50) < formation.speed_for_remaining(25),
		"fewer mice move faster than full"
	)
	assert_true(
		formation.speed_for_remaining(25) < formation.speed_for_remaining(1),
		"last mouse is fastest"
	)


func test_formation_state_is_independent() -> void:
	var first = Formation.new()
	var second = Formation.new()
	var second_before = second.get_positions()
	first.step(20.0)
	var second_after = second.get_positions()
	for i in second_before.size():
		assert_eq(second_after[i], second_before[i], "stepping one leaves the other alone")
	assert_ne(first.get_positions()[0], second_after[0], "the stepped one did move")
