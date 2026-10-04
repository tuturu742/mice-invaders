# Every rule the swarm obeys, checked headless against the pure class.
#
# The expected numbers are written out literally on purpose: a reviewer should be able to
# read the grid off this file without opening formation.gd. The fixture used throughout is
# three rows by four columns, horizontal spacing 40, vertical spacing 30, origin (100, 50).
#
#   row 0:  (100,50) (140,50) (180,50) (220,50)
#   row 1:  (100,80) (140,80) (180,80) (220,80)
#   row 2:  (100,110)(140,110)(180,110)(220,110)
#
# Speed curve: base 20, +10 per mouse lost, capped at 200. A full swarm of 12 moves at 20;
# losing one mouse drops it to 11 alive, speed 20 + 10 = 30; one mouse left is 20 + 10*11 = 130.
extends "res://tests/test_case.gd"

const H_SPACING := 40.0
const V_SPACING := 30.0
const ORIGIN := Vector2(100.0, 50.0)
const BASE_SPEED := 20.0


func _new_formation(left_bound: float = 0.0, right_bound: float = 1000.0) -> RefCounted:
	return load("res://scripts/formation.gd").new(
		3, 4, H_SPACING, V_SPACING, ORIGIN, BASE_SPEED, left_bound, right_bound, 10.0, 200.0
	)


func test_initial_layout_is_row_major_grid() -> void:
	var f = _new_formation()
	assert_eq(f.mouse_count(), 12, "three rows of four mice")
	var live: Array = f.positions()
	assert_eq(live.size(), 12, "one position per living mouse")
	# First, a middle, and the last, all literally.
	assert_eq(live[0], Vector2(100.0, 50.0), "first mouse (row 0, col 0)")
	assert_eq(live[1], Vector2(140.0, 50.0), "second mouse (row 0, col 1)")
	assert_eq(live[5], Vector2(140.0, 80.0), "middle mouse (row 1, col 1)")
	assert_eq(live[11], Vector2(220.0, 110.0), "last mouse (row 2, col 3)")


func test_plain_step_moves_every_mouse_in_x_only() -> void:
	# Bounds far away, so no edge is involved. Full swarm, so speed is 20.
	var f = _new_formation()
	var before: Array = f.positions()
	var dropped: bool = f.step(0.5)
	assert_false(dropped, "a step away from the edges does not drop")
	var after: Array = f.positions()
	assert_eq(after.size(), before.size(), "no mouse is lost on a plain step")
	for i in before.size():
		assert_almost_eq(after[i].x, before[i].x + 10.0, 0.0001, "mouse %d moved +%.1f in x" % [i, 10.0])
		assert_almost_eq(after[i].y, before[i].y, 0.0001, "mouse %d y is unchanged" % i)


func test_right_edge_drops_and_reverses() -> void:
	# Rightmost cell starts at 220; +10 per step takes it to 230, past the bound 225.
	var f = _new_formation(0.0, 225.0)
	var before: Array = f.positions()
	var dropped: bool = f.step(0.5)
	assert_true(dropped, "crossing the right bound drops")
	var after: Array = f.positions()
	assert_eq(after[0], Vector2(100.0, 80.0), "first mouse dropped one row, x unchanged")
	assert_eq(after[4], Vector2(100.0, 110.0), "first mouse of row 1 dropped one row")
	assert_eq(after[11], Vector2(220.0, 140.0), "last mouse dropped one row")
	assert_eq(f.direction, -1, "direction reversed after the right-edge drop")
	# An immediate second step now moves left by 10, not down again.
	f.step(0.5)
	assert_eq(f.positions()[0], Vector2(90.0, 80.0), "second step moves back the other way")


func test_left_edge_drops_and_reverses() -> void:
	# Start at x=100, one step of -10 takes it to 90, past the left bound 95.
	var f = _new_formation(95.0, 1000.0)
	f.direction = -1
	var dropped: bool = f.step(0.5)
	assert_true(dropped, "crossing the left bound drops")
	var after: Array = f.positions()
	assert_eq(after[0], Vector2(100.0, 80.0), "first mouse dropped one row, x unchanged")
	assert_eq(after[11], Vector2(220.0, 140.0), "last mouse dropped one row")
	assert_eq(f.direction, 1, "direction reversed after the left-edge drop")
	f.step(0.5)
	assert_eq(f.positions()[0], Vector2(110.0, 80.0), "second step moves back the other way")


func test_speed_curve_full_half_and_one() -> void:
	var f = _new_formation()
	assert_almost_eq(f.current_speed(), 20.0, 0.0001, "full strength: base 20")

	# Half strength: the formula floors at 6 alive (12 - 6 = 6 lost), speed 20 + 60 = 80.
	for i in 6:
		f.remove_at(i)
	assert_eq(f.mouse_count(), 6, "six mice removed leaves six")
	assert_almost_eq(f.current_speed(), 80.0, 0.0001, "half strength: 6 alive, 6 lost")

	# One mouse remaining: 11 lost, 20 + 110 = 130, below the 200 cap.
	for i in range(6, 11):
		f.remove_at(i)
	assert_eq(f.mouse_count(), 1, "one mouse left")
	assert_almost_eq(f.current_speed(), 130.0, 0.0001, "one mouse: 11 lost")

	assert_true(f.current_speed() > 80.0, "one-mouse speed beats half strength")
	assert_true(f.current_speed() > 20.0, "one-mouse speed beats full strength")
