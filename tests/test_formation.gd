# What the mouse swarm does, readable without opening scripts/formation.gd.
#
# Every number is written out here as a literal: grid size, spacing, origin, bounds, drop
# distance, and the three speeds. Read this file top to bottom and you know the rules.
#
# Contract (from tests/run_tests.gd): every method named `test_*` is run, on a fresh
# instance, and assertions append to `failures` (tests/test_case.gd). No framework.
extends "res://tests/test_case.gd"

# The concrete swarm used throughout: 3 rows x 6 columns = 18 mice, spacing 40 px in both
# axes, top-left mouse centred at (100, 50), marching between x = 0 and x = 300.
#
# Slot centres are therefore:
#   x = 100, 140, 180, 220, 260, 300   (origin.x + column * 40)
#   y =  50,  90, 130                   (origin.y + row * 40)
# Speed at full strength is 8 px/step and the fastest (one mouse) is 40 px/step, linearly
# rounded between; the drop is 40 px == one row.
const ROWS := 3
const COLS := 6
const SPACING_X := 40.0
const SPACING_Y := 40.0
const ORIGIN := Vector2(100.0, 50.0)
const LEFT_BOUND := 0.0
const RIGHT_BOUND := 300.0
const DROP := 40.0
const SPEED_FULL := 8.0
const SPEED_ONE := 40.0


func _swarm():
	return load("res://scripts/formation.gd").new(
		ROWS, COLS, SPACING_X, SPACING_Y, ORIGIN, LEFT_BOUND, RIGHT_BOUND
	)


func test_initial_layout_is_exact() -> void:
	var f = _swarm()
	assert_eq(f.count_alive(), 18, "3 rows x 6 columns of live mice")
	for row in ROWS:
		for column in COLS:
			var index: int = row * COLS + column
			var expected := Vector2(
				ORIGIN.x + float(column) * SPACING_X,
				ORIGIN.y + float(row) * SPACING_Y
			)
			assert_eq(
				f.position_of(index), expected,
				"mouse %d sits at its grid slot" % index
			)
			assert_true(f.is_alive(index), "mouse %d starts alive" % index)
	# Spot-check the corners by value, so a reader sees the literals.
	assert_eq(f.position_of(0), Vector2(100.0, 50.0), "top-left centre")
	assert_eq(f.position_of(5), Vector2(300.0, 50.0), "top-right centre")
	assert_eq(f.position_of(17), Vector2(300.0, 130.0), "bottom-right centre")


func test_plain_step_moves_horizontally_only() -> void:
	# Start the formation away from either bound. Its extremes are x = 300 (right column)
	# and x = 100 (left column); shifting the whole grid left by 60 puts them at 240 and
	# 40, leaving room for several 8 px steps before either bound is reached.
	var f = _swarm()
	var step: float = f.speed_for(f.count_alive())
	assert_eq(step, SPEED_FULL, "18 mice move at 8 px/step")
	for i in f.total_count():
		var p: Vector2 = f.position_of(i)
		f.positions[i] = Vector2(p.x - 60.0, p.y)
	var before: Array[Vector2] = f.positions.duplicate()
	var direction_before: int = f.direction
	f.step()
	for i in f.total_count():
		assert_eq(
			f.position_of(i),
			Vector2(before[i].x + step, before[i].y),
			"mouse %d moved right by exactly %s and not vertically" % [i, step]
		)
	assert_eq(f.direction, direction_before, "no edge reached, so direction is unchanged")
	assert_eq(f.count_alive(), 18, "no step kills a mouse")


func test_edge_drops_one_row_and_reverses() -> void:
	var f = _swarm()
	# Top-right mouse is at x = 300, exactly the right bound. A step right of 8 would put
	# it at 308 > 300, i.e. it "would cross" (new x > right_bound), so the whole formation
	# must drop and turn instead of stepping sideways.
	var before: Array[Vector2] = f.positions.duplicate()
	assert_eq(before[5].x, RIGHT_BOUND, "top-right mouse starts exactly on the right bound")
	var direction_before: int = f.direction
	assert_eq(direction_before, 1, "and the formation faces right")

	f.step()

	for i in f.total_count():
		assert_eq(
			f.position_of(i).x, before[i].x,
			"mouse %d did NOT move horizontally at the edge" % i
		)
		assert_eq(
			f.position_of(i).y, before[i].y + DROP,
			"mouse %d dropped by exactly the drop distance" % i
		)
	assert_eq(f.direction, -1, "direction reversed after the drop")
	assert_eq(f.count_alive(), 18, "dropping kills no mouse")

	# And the reversal is real: the very next step moves the other way, left, by 8.
	var after_drop: Array[Vector2] = f.positions.duplicate()
	f.step()
	for i in f.total_count():
		assert_eq(
			f.position_of(i),
			Vector2(after_drop[i].x - SPEED_FULL, after_drop[i].y),
			"mouse %d steps left after the reversal" % i
		)

	# The left edge is symmetric, and shows the other half of "would cross": a new x <
	# left_bound. Shift a fresh swarm left by 96 so the leftmost mouse sits at x = 4, face
	# left, and step. 4 - 8 = -4 < 0, so this must drop and face right.
	var g = _swarm()
	for i in g.total_count():
		var p: Vector2 = g.position_of(i)
		g.positions[i] = Vector2(p.x - 96.0, p.y)
	g.direction = -1
	assert_eq(g.position_of(0).x, 4.0, "leftmost mouse is at x = 4")
	var xs_before: Array[float] = []
	for j in g.total_count():
		xs_before.append(g.position_of(j).x)
	var ys_before: Array[float] = []
	for j in g.total_count():
		ys_before.append(g.position_of(j).y)
	g.step()
	for j in g.total_count():
		assert_eq(g.position_of(j).x, xs_before[j], "left edge: no horizontal move")
		assert_eq(g.position_of(j).y, ys_before[j] + DROP, "left edge: dropped one row")
	assert_eq(g.direction, 1, "left edge reverses back to facing right")


func test_speed_up_as_mice_die() -> void:
	var f = _swarm()
	# Full strength (18): minimum. One mouse: maximum. Half strength: round(18/2) = 9.
	assert_eq(f.speed_for(18), 8.0, "18 mice move at 8")
	assert_eq(f.speed_for(9), round(40.0 + (8.0 - 40.0) * 8.0 / 17.0), "9 mice move at 25")
	assert_eq(f.speed_for(1), 40.0, "one mouse moves at 40")
	assert_eq(f.speed_for(0), 0.0, "nothing alive does not move")

	# Written as literals, so a reader sees the exact numbers.
	assert_eq(f.speed_for(18), 8.0, "full strength")
	assert_eq(f.speed_for(9), 25.0, "half strength, rounded")
	assert_eq(f.speed_for(1), 40.0, "one mouse left")

	# Monotonic: as alive_count falls from full to 1, speed never decreases; strictly rises
	# from full to one.
	for n in range(1, 18):
		assert_true(
			f.speed_for(n) >= f.speed_for(n + 1),
			"speed at %d mice is not faster than at %d" % [n + 1, n]
		)
	assert_true(f.speed_for(1) > f.speed_for(18), "one mouse is strictly faster than full")
	# Speed depends only on the count, not on which mice died: kill a different set and
	# the answer is the same.
	var g = _swarm()
	g.kill(0)
	g.kill(1)
	g.kill(2)
	assert_eq(g.speed_for(g.count_alive()), f.speed_for(15), "speed is a pure function of count")


func test_dead_mice_do_not_block_the_edge() -> void:
	var f = _swarm()
	# The whole right column (indices 5, 11, 17 at x = 300) is dead. The rightmost *live*
	# mouse is now column 4 at x = 260. The swarm has 15 alive, so its speed is 14 px/step:
	# 260 + 14 = 274 <= 300, a plain step right that must NOT drop.
	f.kill(5)
	f.kill(11)
	f.kill(17)
	assert_false(f.is_alive(5), "index 5 is dead")
	assert_eq(f.count_alive(), 15, "three of eighteen are dead")
	var step: float = f.speed_for(15)
	assert_eq(step, 14.0, "15 mice move at 14 px/step")
	var before: Array[Vector2] = f.positions.duplicate()
	f.step()
	assert_eq(f.direction, 1, "no drop: direction unchanged")
	assert_eq(f.position_of(4).x, before[4].x + step, "live mouse 4 stepped right by the speed")
	assert_eq(f.position_of(5).x, before[5].x, "dead mouse 5 did not move at all")
	assert_eq(f.position_of(4).y, before[4].y, "and nothing dropped")


func test_determinism_no_randomness() -> void:
	var a = _swarm()
	var b = _swarm()
	for _i in 50:
		a.step()
		b.step()
	assert_eq(a.count_alive(), b.count_alive(), "same liveness")
	assert_eq(a.direction, b.direction, "same direction")
	for i in a.total_count():
		assert_eq(a.position_of(i), b.position_of(i), "mouse %d is in the same place" % i)
