# The mouse swarm's rules, and nothing else.
#
# Pure logic: a RefCounted with no Node, no scene tree, no signals, no Input, no rendering,
# no autoloads and no await. It can be loaded and instantiated from a bare script run with
# no scene, which is what `godot --headless --path . --script tests/run_tests.gd` does.
#
# A mouse is represented by its index into `positions` (row-major: index = row * columns +
# column). Its liveness is `alive[index]`, its position is `positions[index]`. Public methods
# read both, so the test suite never touches the internals.
#
# Every number in the rules is an input or a documented constant. There is no randomness:
# two formations configured and stepped identically end in identical state.
extends RefCounted

# Every step moves horizontally by `speed` (see speed_for). When any live mouse would cross
# a bound, the formation does not step sideways at all: it drops by exactly DROP_DISTANCE
# and reverses. DROP_DISTANCE is intentionally equal to the row spacing, so one drop is one
# row -- but it is a named constant so a test can pin the number.
const DROP_DISTANCE := 40.0

# speed_for(alive_count): the swarm speeds up as mice are destroyed, and is fastest with
# one mouse left. The axis is linear between these two anchors, rounded to whole pixels:
#   alive == full strength (rows * columns) -> SPEED_AT_FULL
#   alive == 1                              -> SPEED_AT_ONE
# With fewer than one live mouse there is nothing to move, so speed is 0.
const SPEED_AT_FULL := 8.0
const SPEED_AT_ONE := 40.0

var rows: int = 0
var columns: int = 0
var spacing_x: float = 0.0
var spacing_y: float = 0.0
var origin := Vector2.ZERO
var left_bound: float = 0.0
var right_bound: float = 0.0

# +1 marches right, -1 marches left.
var direction: int = 1

var positions: Array[Vector2] = []
var alive: Array[bool] = []


# Explicit parameters, in the order the work item names them. `origin` is the centre of the
# top-left mouse; spacing is the centre-to-centre distance to the next mouse.
func _init(
	p_rows: int = 0,
	p_columns: int = 0,
	p_spacing_x: float = 0.0,
	p_spacing_y: float = 0.0,
	p_origin := Vector2.ZERO,
	p_left_bound: float = 0.0,
	p_right_bound: float = 0.0
) -> void:
	configure(p_rows, p_columns, p_spacing_x, p_spacing_y, p_origin, p_left_bound, p_right_bound)


# Lay out the grid again from scratch and reset direction/liveness. Callable after any run
# to get back to the initial state without building a new object.
func configure(
	p_rows: int,
	p_columns: int,
	p_spacing_x: float,
	p_spacing_y: float,
	p_origin := Vector2.ZERO,
	p_left_bound: float = 0.0,
	p_right_bound: float = 0.0
) -> void:
	rows = p_rows
	columns = p_columns
	spacing_x = p_spacing_x
	spacing_y = p_spacing_y
	origin = p_origin
	left_bound = p_left_bound
	right_bound = p_right_bound
	reset()


# Rebuild the grid using the current parameters: every mouse alive, at its slot, facing
# right. Positions are row-major, `index = row * columns + column`.
func reset() -> void:
	direction = 1
	positions.clear()
	alive.clear()
	for row in rows:
		for column in columns:
			positions.append(Vector2(
				origin.x + float(column) * spacing_x,
				origin.y + float(row) * spacing_y
			))
			alive.append(true)


func count_alive() -> int:
	var n := 0
	for is_alive in alive:
		if is_alive:
			n += 1
	return n


# Alias, so callers that read naturally either way are served.
func alive_count() -> int:
	return count_alive()


func total_count() -> int:
	return positions.size()


func is_alive(index: int) -> bool:
	return alive[index]


func position_of(index: int) -> Vector2:
	return positions[index]


# Mark one mouse destroyed. Out of range is a no-op so a stray shot cannot crash the swarm.
func kill(index: int) -> void:
	if index >= 0 and index < alive.size():
		alive[index] = false


# Move the whole formation sideways by the current speed. A plain step with no edge in the
# way moves every *live* mouse horizontally by exactly `speed` and changes nothing else:
# y unchanged, direction unchanged, liveness unchanged. If any live mouse would cross the
# left or right bound, no horizontal move happens; instead every mouse drops by
# DROP_DISTANCE and the direction reverses.
func step() -> void:
	var speed := speed_for(count_alive())
	if speed == 0.0:
		return  # Nothing alive: nothing to march, no edge to reach.
	if _would_cross(speed):
		for i in positions.size():
			positions[i] = Vector2(positions[i].x, positions[i].y + DROP_DISTANCE)
		direction = -direction
		return
	for i in positions.size():
		if alive[i]:
			positions[i] = Vector2(positions[i].x + speed * float(direction), positions[i].y)


# Pure function of alive_count: same input, same output, no hidden state. Linear between
# SPEED_AT_ONE and SPEED_AT_FULL, rounded to whole pixels, so it strictly decreases as
# alive_count rises and is maximum at 1. Dead mice do not count.
func speed_for(p_alive_count: int) -> float:
	if p_alive_count <= 0:
		return 0.0
	if p_alive_count >= rows * columns:
		return SPEED_AT_FULL
	if p_alive_count == 1:
		return SPEED_AT_ONE
	var t := float(p_alive_count - 1) / float(rows * columns - 1)
	return round(SPEED_AT_ONE + (SPEED_AT_FULL - SPEED_AT_ONE) * t)


# "Would cross" means the new x would be < left_bound or > right_bound. Tested against the
# leftmost and rightmost edges of every live mouse, for the direction we are facing.
func _would_cross(speed: float) -> bool:
	var delta := speed * float(direction)
	for i in positions.size():
		if not alive[i]:
			continue
		var new_x := positions[i].x + delta
		if new_x < left_bound or new_x > right_bound:
			return true
	return false
