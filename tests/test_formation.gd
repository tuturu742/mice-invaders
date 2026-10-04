# The swarm's rules, stated as numbers a reader can check without opening formation.gd.
#
# Grid: 5 rows x 8 cols = 40 mice. Column gap 48 px, row gap 40 px. Top-left mouse starts
# at (120, 80), so the last (row 4, col 7) sits at (120 + 7*48, 80 + 4*40) = (456, 240).
# The swarm is confined to x in [0, 640]. At an edge it drops 24 px and reverses, doing no
# sideways move that step. Speed ramps 20 px/s (40 alive) -> 110 (20 alive) -> 200 (1 alive).
extends "res://tests/test_case.gd"

const FormationScript := preload("res://scripts/formation.gd")


func _new() -> RefCounted:
	return FormationScript.new()


func _contains_position(positions: Array, pos: Vector2) -> bool:
	for p in positions:
		if p == pos:
			return true
	return false


func test_initial_layout() -> void:
	var f = _new()
	f.reset()
	assert_eq(f.mouse_count(), 40, "full grid is 5 rows * 8 cols")
	assert_eq(f.mouse_positions().size(), 40, "one position per living mouse")

	var positions = f.mouse_positions()
	assert_eq(positions[0], Vector2(120, 80), "first mouse is the grid origin")
	assert_eq(positions[positions.size() - 1], Vector2(456, 240), "last mouse is row 4, col 7")
	assert_eq(Vector2(120 + 3 * 48, 80 + 2 * 40), Vector2(264, 160), "row 2, col 3 = (264, 160)")
	assert_true(_contains_position(positions, Vector2(264, 160)), "grid cell (2, 3) exists")


func test_plain_step() -> void:
	var f = _new()
	f.reset()
	assert_eq(f.speed(), 20.0, "40 alive -> base speed 20 px/s")
	assert_eq(f.direction, 1, "starts moving right")

	var before = f.mouse_positions()
	f.step(1.0)
	var after = f.mouse_positions()
	assert_eq(after.size(), before.size(), "stepping moves mice, it does not add or remove them")
	for i in range(before.size()):
		assert_almost_eq(after[i].x - before[i].x, 20.0, 0.0001, "each mouse moved +20 px in x")
		assert_almost_eq(after[i].y, before[i].y, 0.0001, "y is unchanged on a sideways move")
	assert_eq(f.origin.y, 80.0, "no drop on a plain step")

	f.step(0.5)
	var later = f.mouse_positions()
	for i in range(before.size()):
		assert_almost_eq(later[i].x - before[i].x, 30.0, 0.0001, "0.5 s more at 20 px/s totals +30 px")
	assert_eq(f.origin.y, 80.0, "still no drop")


func test_edge_drops_and_reverses() -> void:
	var f = _new()
	f.reset()

	var dropped := false
	for i in range(40):
		f.step(1.0)
		if f.origin.y == 104.0:
			dropped = true
			break
	assert_true(dropped, "the swarm reaches the right edge and drops within 40 steps")

	assert_eq(f.origin.y, 80.0 + 24.0, "a drop moves down exactly 24 px")
	assert_eq(f.direction, -1, "a drop reverses direction")
	for p in f.mouse_positions():
		assert_true(p.x <= 640.0, "no mouse ever crossed the 640 px right bound")

	var y_before = f.origin.y
	var x_before = f.origin.x
	f.step(1.0)
	assert_eq(f.origin.y, y_before, "after bouncing, the next step moves sideways, not down")
	assert_eq(f.direction, -1, "and it keeps moving left")
	assert_almost_eq(f.origin.x, x_before - 20.0, 0.0001, "a full-strength left step is -20 px")


func test_speed_full_half_one() -> void:
	var f = _new()
	f.reset()
	assert_eq(f.speed(), 20.0, "40 alive -> 20 px/s")

	# Remove 20 mice, keeping 20. Hit them at their exact positions, radius 1.
	var removed := 0
	while f.mouse_count() > 20:
		var pos: Vector2 = f.mouse_positions()[0]
		assert_true(f.hit_mouse(pos, 1.0), "removing a mouse at its exact position succeeds")
		removed += 1
	assert_eq(removed, 20, "exactly 20 mice were removed")
	assert_eq(f.mouse_count(), 20, "half strength is 20 mice")
	assert_eq(f.speed(), 110.0, "20 alive -> 110 px/s")

	while f.mouse_count() > 1:
		var pos: Vector2 = f.mouse_positions()[0]
		assert_true(f.hit_mouse(pos, 1.0), "removing one of many succeeds")
	assert_eq(f.mouse_count(), 1, "one mouse left")
	assert_eq(f.speed(), 200.0, "1 alive -> 200 px/s")


func test_hit_removes_one() -> void:
	var f = _new()
	f.reset()

	var target := Vector2(120 + 3 * 48, 80 + 2 * 40) # grid (2, 3) = (264, 160)
	assert_true(_contains_position(f.mouse_positions(), target), "the known mouse is present before the hit")
	var before: int = f.mouse_count()

	assert_true(f.hit_mouse(target, 1.0), "a hit on the exact position removes a mouse")
	assert_eq(f.mouse_count(), before - 1, "exactly one mouse was removed")
	assert_false(_contains_position(f.mouse_positions(), target), "the removed mouse is gone")

	assert_false(f.hit_mouse(Vector2(-1000, -1000), 1.0), "a hit far from every mouse misses")
	assert_eq(f.mouse_count(), before - 1, "a miss leaves the count unchanged")
