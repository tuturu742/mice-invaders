# The swarm's marching rules, asserted against literal numbers.
#
# Every expected value here is written out, not read back from Formation's constants, so a
# reviewer reading only this file knows exactly where the swarm is and how fast it moves.
extends "res://tests/test_case.gd"

const Formation = preload("res://scripts/formation.gd")


func test_initial_layout() -> void:
	var f = Formation.new()
	assert_eq(f.alive_count(), 32, "a fresh formation is a full 4x8 grid")
	assert_eq(f.mice[0], Vector2(64, 80), "top-left mouse at the origin")
	assert_eq(f.mice[7], Vector2(400, 80), "end of row one: 64 + 7*48")
	assert_eq(f.mice[8], Vector2(64, 128), "row two returns to origin x")
	assert_eq(f.mice[31], Vector2(400, 224), "bottom-right: 64 + 7*48, 80 + 3*48")
	assert_eq(f.direction, 1, "starts moving right")
	assert_eq(f.speed, 120.0, "full strength moves at the maximum")


func test_plain_step() -> void:
	var f = Formation.new()
	var dropped = f.step(1.0, 0.0, 10000.0)
	assert_false(dropped, "far from a bound, a step is a plain slide")
	assert_eq(f.direction, 1, "direction is unchanged")
	var all_moved = true
	var all_level = true
	for i in f.mice.size():
		all_moved = all_moved and is_equal_approx(f.mice[i].x, 64.0 + (i % 8) * 48.0 + 120.0)
		all_level = all_level and is_equal_approx(f.mice[i].y, 80.0 + (i / 8) * 48.0)
	assert_true(all_moved, "every mouse x increased by exactly 120")
	assert_true(all_level, "every mouse y is unchanged")
	assert_eq(f.mice[0], Vector2(184, 80), "the top-left mouse slid one second to the right")


func test_edge_drop_and_reverse() -> void:
	# Right edge: 400 + 120 = 520 proposed, which crosses a right bound of 519.
	var right = Formation.new()
	var dropped = right.step(1.0, 0.0, 519.0)
	assert_true(dropped, "crossing the right bound drops the swarm")
	assert_eq(right.direction, -1, "and reverses it to the left")
	var all_same_x = true
	var all_dropped = true
	for i in right.mice.size():
		all_same_x = all_same_x and is_equal_approx(right.mice[i].x, 64.0 + (i % 8) * 48.0)
		all_dropped = all_dropped and is_equal_approx(right.mice[i].y, 80.0 + (i / 8) * 48.0 + 24.0)
	assert_true(all_same_x, "no mouse x changed on a drop")
	assert_true(all_dropped, "every mouse y increased by exactly 24")
	assert_eq(right.mice[0], Vector2(64, 104), "the top-left mouse stayed put and fell")

	# Left edge: move left until the next step would cross a left bound of -296.
	# After three left steps the leftmost column sits at 64 - 360 = -296, which is exactly
	# on the bound; the fourth step proposes -416, which crosses it.
	var left = Formation.new()
	left.direction = -1
	for i in 3:
		left.step(1.0, -296.0, 10000.0)
	assert_eq(left.direction, -1, "still heading left after sliding inside the bound")
	var left_dropped = left.step(1.0, -296.0, 10000.0)
	assert_true(left_dropped, "crossing the left bound drops the swarm")
	assert_eq(left.direction, 1, "and reverses it to the right")
	var left_x_ok = true
	var left_y_ok = true
	for i in left.mice.size():
		left_x_ok = left_x_ok and is_equal_approx(left.mice[i].x, 64.0 + (i % 8) * 48.0 - 3.0 * 120.0)
		left_y_ok = left_y_ok and is_equal_approx(left.mice[i].y, 80.0 + (i / 8) * 48.0 + 24.0)
	assert_true(left_x_ok, "x unchanged on the left-edge drop")
	assert_true(left_y_ok, "y up by 24 on the left-edge drop")
	assert_eq(left.mice[0], Vector2(-296, 104), "the top-left mouse is one drop down")


func test_speed_full_strength() -> void:
	var f = Formation.new()
	assert_eq(f.speed_for(32), 120.0, "a full swarm moves at the maximum")
	assert_eq(f.speed_for(40), 120.0, "and never exceeds the maximum")


func test_speed_half_strength() -> void:
	var f = Formation.new()
	assert_eq(f.speed_for(16), 70.0, "half a swarm is the exact midpoint of 20 and 120")


func test_speed_one_left() -> void:
	var f = Formation.new()
	assert_eq(f.speed_for(1), 20.0, "a lone mouse moves at the minimum")
	assert_eq(f.speed_for(0), 20.0, "and so does an empty swarm")


func test_speed_decreases_monotonically() -> void:
	var f = Formation.new()
	var previous := f.speed_for(32)
	for count in range(31, 0, -1):
		var current = f.speed_for(count)
		assert_true(current <= previous, "speed never rises as mice are removed (%d)" % count)
		previous = current
	assert_true(f.speed_for(32) > f.speed_for(1), "full is strictly faster than one")


func test_set_mouse_count_updates_speed() -> void:
	var f = Formation.new()
	f.set_mouse_count(1)
	assert_eq(f.alive_count(), 1, "only one mouse remains")
	assert_eq(f.mice[0], Vector2(64, 80), "the survivor is the preserved prefix")
	assert_eq(f.speed, 20.0, "the speed follows the smaller swarm")
