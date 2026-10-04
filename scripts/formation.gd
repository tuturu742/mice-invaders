# The whole swarm's rules, and nothing else.
#
# A plain RefCounted: no scene, no input, no drawing, no signals. It never reaches out to a
# view -- the view asks it where the mice are and calls `step()` once per frame. That is what
# lets every rule in here be tested headless, with no live scene.
#
# Every number the caller cares about is a constructor parameter, bounds included: there are
# no globals to reach for and no hidden screen size.
extends RefCounted

# Base speed (pixels per second) while every mouse is alive, the added speed per mouse lost,
# and the ceiling that one surviving mouse reaches. The curve is deliberately explicit so a
# reader can compute any value by hand: speed = min(base + per_loss * (start_count - alive), cap).
var base_speed: float
var speed_increment: float
var max_speed: float

# The grid definition, in the order the mice were created.
var rows: int
var columns: int
var h_spacing: float
var v_spacing: float
var origin: Vector2

# Bounds on the swarm's leftmost/rightmost cell, not on its center.
var left_bound: float
var right_bound: float

# +1 marches right, -1 marches left. Flipped on every drop.
var direction: int = 1

# Parallel arrays: position and a matching alive flag. `_dead` entries keep their slot so the
# deterministic row-major order -- and therefore each index's meaning -- survives a removal.
var _positions: Array[Vector2] = []
var _alive: Array[bool] = []
var _alive_count: int = 0


func _init(
	p_rows: int,
	p_columns: int,
	p_h_spacing: float,
	p_v_spacing: float,
	p_origin: Vector2,
	p_speed: float,
	p_left_bound: float,
	p_right_bound: float,
	p_speed_increment: float = 10.0,
	p_max_speed: float = 200.0
) -> void:
	rows = p_rows
	columns = p_columns
	h_spacing = p_h_spacing
	v_spacing = p_v_spacing
	origin = p_origin
	base_speed = p_speed
	speed_increment = p_speed_increment
	max_speed = p_max_speed
	left_bound = p_left_bound
	right_bound = p_right_bound
	_build()


func _build() -> void:
	_positions.clear()
	_alive.clear()
	for row in rows:
		for col in columns:
			_positions.append(origin + Vector2(col * h_spacing, row * v_spacing))
			_alive.append(true)
	_alive_count = _positions.size()


## How many mice are still alive.
func mouse_count() -> int:
	return _alive_count


## The living mice's positions, in deterministic row-major order.
func positions() -> Array[Vector2]:
	var live: Array[Vector2] = []
	for i in _positions.size():
		if _alive[i]:
			live.append(_positions[i])
	return live


## Position of the mouse at a given array index, alive or not -- useful to the tests.
func position_at(index: int) -> Vector2:
	return _positions[index]


## Remove the living mouse whose position is closest to `point`. Returns the index, or -1
## when nothing was alive. The scene turns a shot into a removal with only this call.
func remove_closest(point: Vector2) -> int:
	var best_index := -1
	var best_dist := INF
	for i in _positions.size():
		if not _alive[i]:
			continue
		var d := _positions[i].distance_squared_to(point)
		if d < best_dist:
			best_dist = d
			best_index = i
	if best_index == -1:
		return -1
	_alive[best_index] = false
	_alive_count -= 1
	return best_index


## Remove the mouse at a direct array index. Returns true if one was removed.
func remove_at(index: int) -> bool:
	if index < 0 or index >= _alive.size() or not _alive[index]:
		return false
	_alive[index] = false
	_alive_count -= 1
	return true


## Advance the swarm by one step. Moves sideways at the current speed; if any living mouse
## would cross a bound, the whole swarm instead drops one row and reverses. Returns true when
## a drop happened, so the scene and the tests can see it.
func step(delta: float) -> bool:
	if _alive_count == 0:
		return false
	var speed := current_speed()
	var dx := direction * speed * delta
	var edge := _would_cross(dx)
	if edge:
		for i in _positions.size():
			_positions[i] = Vector2(_positions[i].x, _positions[i].y + v_spacing)
		direction = -direction
		return true
	for i in _positions.size():
		_positions[i] = Vector2(_positions[i].x + dx, _positions[i].y)
	return false


func _would_cross(dx: float) -> bool:
	for i in _positions.size():
		if not _alive[i]:
			continue
		var next_x := _positions[i].x + dx
		if next_x < left_bound or next_x > right_bound:
			return true
	return false


## The speed the swarm should move at right now, given how many mice are left. Fastest with
## exactly one mouse. Deterministic: base_speed + speed_increment * mice_lost, capped at max_speed.
func current_speed() -> float:
	var lost := _positions.size() - _alive_count
	return minf(base_speed + speed_increment * float(lost), max_speed)
