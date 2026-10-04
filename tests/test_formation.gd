# Tests for scripts/formation.gd -- the swarm rules, stated back as numbers.
#
# Each case makes its expected numbers explicit rather than importing them from
# the class under test: a test that repeats a constant it was handed proves
# nothing, so the layout, bounds, drop, and speed figures are written out here.
extends "res://tests/test_case.gd"

const Formation := preload("res://scripts/formation.gd")


func test_initial_grid_layout() -> void:
	var formation = Formation.new()
	assert_eq(formation.mice.size(), 40, "swarm starts with ROWS * COLUMNS mice")
	assert_eq(formation.direction, 1, "swarm starts marching right")
	assert_eq(formation.mice[0], Vector2(80.0, 80.0), "top-left mouse sits at the origin")
	assert_eq(formation.mice[1], Vector2(128.0, 80.0), "second mouse is one spacing to the right")
	assert_eq(formation.mice[8], Vector2(80.0, 128.0), "first mouse of row two is one spacing down")


func test_one_ordinary_step() -> void:
	var formation = Formation.new()
	# 1 second at full-strength speed (40 px/s), marching right.
	formation.step(1.0)
	assert_eq(formation.mice[0], Vector2(120.0, 80.0), "the swarm advanced one step to the right")
	assert_eq(formation.direction, 1, "an ordinary step does not reverse direction")


func test_edge_case_drops_and_reverses() -> void:
	var formation = Formation.new()
	# March right until the leading edge would cross RIGHT_BOUND (600.0).
	# Rightmost mouse starts at 80 + 7*48 = 416; it needs to reach 600.
	formation.step(5.0)
	# 416 + 200 = 616, which is past 600 -- so that step must not happen.
	# Instead: a 32px drop, and the direction reverses to left.
	assert_eq(formation.direction, -1, "hitting the right edge reverses direction")
	assert_eq(formation.mice[0], Vector2(80.0, 112.0), "the swarm dropped one row instead of stepping")
	assert_eq(formation.mice[1], Vector2(128.0, 112.0), "every mouse drops together")


func test_speed_at_full_strength() -> void:
	var formation = Formation.new()
	assert_almost_eq(formation.speed(), 40.0, 0.0001, "full swarm moves at base speed")


func test_speed_at_half_strength() -> void:
	var formation = Formation.new()
	for _i in 20:
		formation.remove_mouse(0)
	assert_eq(formation.mice.size(), 20, "half the swarm remains")
	# 40 * (1 + 20/40) = 60
	assert_almost_eq(formation.speed(), 60.0, 0.0001, "half swarm moves at 60 px/s")


func test_speed_with_one_mouse_remaining() -> void:
	var formation = Formation.new()
	for _i in 39:
		formation.remove_mouse(0)
	assert_eq(formation.mice.size(), 1, "one mouse remains")
	# 40 * (1 + 39/40) = 79
	assert_almost_eq(formation.speed(), 79.0, 0.0001, "last mouse moves at 79 px/s")
