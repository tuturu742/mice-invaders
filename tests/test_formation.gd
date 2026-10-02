# The swarm's rules, spelled out in numbers so the file reads like a spec.
#
# Configuration used throughout: 3 rows x 4 columns = 12 mice, spacing 8, origin (10, 10),
# bounds left 0 and right 100. Row r, column c sits at origin + (c * spacing, r * spacing):
#
#   (10, 10) (18, 10) (26, 10) (34, 10)
#   (10, 18) (18, 18) (26, 18) (34, 18)
#   (10, 26) (18, 26) (26, 26) (34, 26)
#
# Speed is BASE_SPEED + STEP_ACCELERATION * (12 - mice_left): 4 with all 12 mice,
# 10 with 6 left, 15 with 1 left.
extends "res://tests/test_case.gd"

const Formation := preload("res://scripts/formation.gd")


func _swarm() -> RefCounted:
	return Formation.new(3, 4, 8.0, Vector2(10, 10), 0.0, 100.0)


func test_initial_layout_count_and_exact_positions() -> void:
	var swarm = _swarm()
	assert_eq(swarm.rows, 3, "rows")
	assert_eq(swarm.columns, 4, "columns")
	assert_eq(swarm.spacing, 8.0, "spacing")
	assert_eq(swarm.mouse_count(), 12, "3 rows x 4 columns is 12 mice")

	assert_eq(swarm.position_of(0, 0), Vector2(10, 10), "first mouse at the origin")
	assert_eq(swarm.position_of(0, 1), Vector2(18, 10), "second mouse one spacing to the right")
	assert_eq(swarm.position_of(0, 2), Vector2(26, 10), "third mouse")
	assert_eq(swarm.position_of(0, 3), Vector2(34, 10), "fourth mouse")
	assert_eq(swarm.position_of(1, 0), Vector2(10, 18), "first mouse of row 2 is one spacing down")
	assert_eq(swarm.position_of(2, 3), Vector2(34, 26), "last mouse")


func test_plain_step_moves_every_mouse_sideways_at_current_speed() -> void:
	var swarm = _swarm()
	# Start mid-field and aim left so no mouse is anywhere near a bound after one step.
	swarm.origin = Vector2(50, 10)
	swarm._lay_out()
	swarm.direction = Formation.DIR_LEFT
	var speed: float = swarm.speed
	assert_eq(speed, 4.0, "full strength moves 4 px per step")

	var before: Array[Vector2] = swarm.positions()
	swarm.step()

	for i in before.size():
		assert_eq(swarm.positions()[i], before[i] + Vector2(-speed, 0.0), "mouse %d moved left by the speed" % i)
	assert_eq(swarm.direction, Formation.DIR_LEFT, "direction is unchanged by a plain step")


func test_right_bound_drops_one_row_and_reverses_without_sideways_motion() -> void:
	var swarm = _swarm()
	# With origin x = 73 the rightmost mouse sits at 73 + 3 * 8 = 97, so one 4 px step right
	# would carry it to 101, past right = 100. The leftmost mouse at 73 is nowhere near a bound.
	swarm.origin = Vector2(73, 10)
	swarm._lay_out()
	swarm.direction = Formation.DIR_RIGHT
	var before: Array[Vector2] = swarm.positions()
	var rightmost_before: float = before[3].x
	assert_true(rightmost_before + swarm.speed > swarm.right_bound(), "the next step would cross the right bound")

	swarm.step()

	for i in before.size():
		assert_eq(swarm.positions()[i], before[i] + Vector2(0.0, 8.0), "mouse %d dropped one row, not sideways" % i)
	assert_eq(swarm.direction, Formation.DIR_LEFT, "direction reversed at the right bound")

	# The follow-up step now travels left.
	var after_drop: Array[Vector2] = swarm.positions()
	swarm.step()
	for i in after_drop.size():
		assert_eq(swarm.positions()[i], after_drop[i] + Vector2(-swarm.speed, 0.0), "mouse %d now moves left" % i)


func test_left_bound_drops_one_row_and_reverses_without_sideways_motion() -> void:
	var swarm = _swarm()
	# The leftmost mouse sits at x = origin.x. A left step of 4 px would drop it below 0; aim
	# the formation at x = 2 so the crossing is guaranteed.
	swarm.origin = Vector2(2, 10)
	swarm._lay_out()
	swarm.direction = Formation.DIR_LEFT
	var before: Array[Vector2] = swarm.positions()
	assert_true(before[0].x - swarm.speed < swarm.left_bound(), "the next step would cross the left bound")

	swarm.step()

	for i in before.size():
		assert_eq(swarm.positions()[i], before[i] + Vector2(0.0, 8.0), "mouse %d dropped one row, not sideways" % i)
	assert_eq(swarm.direction, Formation.DIR_RIGHT, "direction reversed at the left bound")

	var after_drop: Array[Vector2] = swarm.positions()
	swarm.step()
	for i in after_drop.size():
		assert_eq(swarm.positions()[i], after_drop[i] + Vector2(swarm.speed, 0.0), "mouse %d now moves right" % i)


func test_speed_increases_as_mice_are_destroyed() -> void:
	var swarm = _swarm()
	assert_eq(swarm.remaining_count(), 12, "all mice alive at the start")
	assert_eq(swarm.speed_for(12), 4.0, "full strength speed")

	# Destroy six mice: 3 in the top row and 3 in the middle row.
	for column in 3:
		swarm.destroy(0, column)
		swarm.destroy(1, column)
	assert_eq(swarm.remaining_count(), 6, "half the mice are gone")
	assert_eq(swarm.speed_for(6), 10.0, "half strength speed")

	# Destroy five more, leaving exactly one.
	for column in 3:
		swarm.destroy(2, column)
	swarm.destroy(2, 3)
	swarm.destroy(1, 3)
	assert_eq(swarm.remaining_count(), 1, "one mouse left")
	assert_eq(swarm.speed_for(1), 15.0, "one mouse is fastest")

	assert_true(swarm.speed_for(6) > swarm.speed_for(12), "half is faster than full")
	assert_true(swarm.speed_for(1) > swarm.speed_for(6), "one is faster than half")
