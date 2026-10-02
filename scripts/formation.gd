# The pure rules of the swarm: layout, marching, dropping at a bound, and speeding up.
#
# RefCounted on purpose. There is no Node, no scene, no autoload and no signal to the tree
# here, so a headless script can exercise the whole thing with nothing but `Formation.new()`.
# Art, positions in space and frame timing are somebody else's problem; these are the numbers
# the swarm obeys.
extends RefCounted

const DIR_LEFT := -1
const DIR_RIGHT := 1

# Speed is expressed in pixels per step. The swarm starts slow and accelerates as its mice
# are destroyed, ending fastest when exactly one mouse is left. The numbers are deliberately
# small and explicit so a reader (and the tests) can predict every value by hand:
#
#   speed = BASE_SPEED + STEP_ACCELERATION * (INITIAL_MOUSE_COUNT - mice_left)
#
# so with 12 mice it is 4, with 6 left it is 10, and with 1 left it is 15.
const BASE_SPEED := 4.0
const STEP_ACCELERATION := 1.0

var rows: int = 0
var columns: int = 0
var spacing: float = 0.0
var origin: Vector2 = Vector2.ZERO
var direction: int = DIR_RIGHT
var speed: float = BASE_SPEED

var _left_bound: float = 0.0
var _right_bound: float = 0.0
var _positions: Array[Vector2] = []
var _destroyed: Array[bool] = []


func _init(p_rows: int = 0, p_columns: int = 0, p_spacing: float = 0.0, p_origin: Vector2 = Vector2.ZERO, p_left_bound: float = 0.0, p_right_bound: float = 0.0) -> void:
	rows = p_rows
	columns = p_columns
	spacing = p_spacing
	origin = p_origin
	_left_bound = p_left_bound
	_right_bound = p_right_bound
	_lay_out()


# Lay the grid out from scratch: the mouse in row r, column c sits at
# origin + (c * spacing, r * spacing). Re-laying out revives every mouse, because the
# formation is the only state and a fresh layout is a fresh swarm.
func _lay_out() -> void:
	_positions.clear()
	_destroyed.clear()
	for r in rows:
		for c in columns:
			_positions.append(origin + Vector2(c * spacing, r * spacing))
			_destroyed.append(false)
	speed = speed_for(mouse_count())


func mouse_count() -> int:
	return _positions.size()


func remaining_count() -> int:
	var alive := 0
	for dead in _destroyed:
		if not dead:
			alive += 1
	return alive


func position_of(row: int, column: int) -> Vector2:
	return _positions[row * columns + column]


func positions() -> Array[Vector2]:
	return _positions.duplicate()


func left_bound() -> float:
	return _left_bound


func right_bound() -> float:
	return _right_bound


# How fast the swarm should move with `mice_left` mice alive. Fastest at exactly one mouse.
func speed_for(mice_left: int) -> float:
	return BASE_SPEED + STEP_ACCELERATION * float(mouse_count() - mice_left)


# The plain movement case: shift every mouse sideways by the current speed in the current
# direction. The swarm is assumed to be mid-field; use step() when a bound might be crossed.
func move_sideways() -> void:
	var delta := Vector2(float(direction) * speed, 0.0)
	for i in _positions.size():
		_positions[i] += delta


# One frame of swarm movement. If any living mouse would cross a left or right bound, do not
# step sideways at all: drop the whole formation by one row of spacing and reverse direction.
# That is exactly one drop and one reversal per crossing, never a sideways move on that frame.
func step() -> void:
	if _would_cross_bound():
		_drop_and_reverse()
	else:
		move_sideways()
	speed = speed_for(remaining_count())


func _would_cross_bound() -> bool:
	var sideways := float(direction) * speed
	for i in _positions.size():
		if _destroyed[i]:
			continue
		var next_x := _positions[i].x + sideways
		if next_x < _left_bound or next_x > _right_bound:
			return true
	return false


func _drop_and_reverse() -> void:
	for i in _positions.size():
		_positions[i] += Vector2(0.0, spacing)
	direction = -direction


# Mark a mouse destroyed (0-based row, column). The remaining count drops, and the speed rule
# picks up the slack immediately: killing mice makes the swarm faster.
func destroy(row: int, column: int) -> void:
	var index := row * columns + column
	if index < 0 or index >= _positions.size():
		return
	_destroyed[index] = true
	speed = speed_for(remaining_count())
