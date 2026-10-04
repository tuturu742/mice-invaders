# Tests for the pure swarm rules in scripts/formation.gd.
#
# Every number below is written out explicitly so a reviewer can see exactly what behavior
# is being pinned down without opening the implementation. No test depends on a running
# scene; Formation is a plain RefCounted.
extends "res://tests/test_case.gd"

const Formation := preload("res://scripts/formation.gd")


func test_initial_grid_layout() -> void:
	var f := Formation.new(2, 3, 60.0, 50.0, Vector2(100.0, 40.0))

	var expected := [
		Vector2(100.0, 40.0),  Vector2(160.0, 40.0),  Vector2(220.0, 40.0),
		Vector2(100.0, 90.0),  Vector2(160.0, 90.0),  Vector2(220.0, 90.0),
	]

	var got := f.positions()
	assert_eq(got.size(), 6, "positions count")
	for i in expected.size():
		assert_eq(got[i], expected[i], "position %d" % i)


func test_normal_sideways_step() -> void:
	var f := Formation.new(1, 2, 50.0, 40.0, Vector2(0.0, 0.0))
	f.base_speed = 2.0
	f.direction = 1
	f.set_bounds(-100.0, 100.0)

	f.step(2)

	var expected := [Vector2(2.0, 0.0), Vector2(52.0, 0.0)]
	var got := f.positions()
	assert_eq(got[0], expected[0], "left mouse moved right")
	assert_eq(got[1], expected[1], "right mouse moved right")
	assert_eq(f.direction, 1, "direction unchanged")


func test_edge_step_drops_and_reverses() -> void:
	var f := Formation.new(1, 2, 50.0, 40.0, Vector2(0.0, 0.0))
	f.base_speed = 2.0
	f.direction = 1
	f.set_bounds(-100.0, 51.0)

	# Right mouse is at x=50. A step of 2 would put it at 52, past the bound of 51, so the
	# step must be rejected: no horizontal movement, every mouse drops by exactly one row
	# spacing, and the direction reverses.
	f.step(2)

	assert_eq(f.positions()[0], Vector2(0.0, 40.0), "left mouse kept x, dropped one row")
	assert_eq(f.positions()[1], Vector2(50.0, 40.0), "right mouse kept x, dropped one row")
	assert_eq(f.direction, -1, "direction reversed after the drop")


func test_speed_scaling() -> void:
	var f := Formation.new(3, 4, 50.0, 40.0, Vector2(0.0, 0.0))
	f.base_speed = 4.0

	var full := f.speed(12)
	var half := f.speed(6)
	var one := f.speed(1)

	assert_eq(f.total(), 12, "total mice")
	assert_eq(full, 4.0, "full strength speed")
	assert_eq(half, 8.0, "half strength speed")
	assert_eq(one, 48.0, "one mouse speed")
	assert_true(one > half, "one-mouse speed exceeds half-strength")
	assert_true(half > full, "half-strength exceeds full-strength")
	assert_true(one > full, "one-mouse speed exceeds full-strength")
