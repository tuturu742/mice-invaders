# The pure rules of the mouse swarm.
#
# RefCounted-only on purpose: no Node, no scene, no Input, no Time. Everything here is
# arithmetic over grid coordinates, so it can be unit-tested headless and later driven by a
# scene without the scene owning any of the rules.
#
# Mice live as (row, col) grid cells. Their screen positions are derived from the grid's
# `origin` every time they are asked for, so a drop is a single change to `origin.y` and
# never a write to forty separate mice.
class_name Formation
extends RefCounted

const ROWS := 5
const COLS := 8
const SPACING := 48.0
const ROW_SPACING := 40.0
const ORIGIN := Vector2(120, 80)
const LEFT_BOUND := 0.0
const RIGHT_BOUND := 640.0
const DROP_DISTANCE := 24.0
const BASE_SPEED := 20.0
const MAX_SPEED := 200.0

var origin: Vector2 = ORIGIN
var direction: int = 1
# Explicit set of living mice keyed by "row:col" so membership is exact and cheap.
var _alive: Dictionary = {}


func _init() -> void:
	reset()


# Restore the full grid, the starting origin, rightward motion, and the full-strength speed.
func reset() -> void:
	origin = ORIGIN
	direction = 1
	_alive.clear()
	for row in ROWS:
		for col in COLS:
			_alive[_key(row, col)] = true


func mouse_count() -> int:
	return _alive.size()


# Screen position of every living mouse, derived from `origin` and the grid cell.
func mouse_positions() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for key in _alive:
		var cell: Array = _parse(key)
		out.append(origin + Vector2(cell[1] * SPACING, cell[0] * ROW_SPACING))
	return out


# Linear ramp from BASE_SPEED at full strength to MAX_SPEED with a single mouse left.
# The checkpoints this must hit are exact: 40 alive -> 20, 20 alive -> 110, 1 alive -> 200.
func speed() -> float:
	var n := mouse_count()
	var full := ROWS * COLS
	if n <= 1:
		return MAX_SPEED
	return BASE_SPEED + (MAX_SPEED - BASE_SPEED) * (float(full - n) / float(full))


# One action per call: either a sideways move, or a bounce (drop + reverse). Never both.
# The edge test uses the actual leftmost/rightmost living mouse, so empty edge columns
# do not cause a false bounce.
func step(delta: float) -> void:
	var candidate := origin.x + direction * speed() * delta
	if direction > 0:
		if _rightmost_x(candidate) > RIGHT_BOUND:
			origin.y += DROP_DISTANCE
			direction = -direction
			return
	else:
		if _leftmost_x(candidate) < LEFT_BOUND:
			origin.y += DROP_DISTANCE
			direction = -direction
			return
	origin.x = candidate


# Remove the nearest living mouse within `radius` of `pos`. Ties break by lowest row then
# lowest col, so the outcome never depends on dictionary iteration order.
func hit_mouse(pos: Vector2, radius: float) -> bool:
	var best_key := ""
	var best_dist := INF
	var best_row := 0
	var best_col := 0
	for key in _alive:
		var cell: Array = _parse(key)
		var row: int = cell[0]
		var col: int = cell[1]
		var p := origin + Vector2(col * SPACING, row * ROW_SPACING)
		var d := p.distance_to(pos)
		if d > radius:
			continue
		if d < best_dist or (d == best_dist and (row < best_row or (row == best_row and col < best_col))):
			best_dist = d
			best_key = key
			best_row = row
			best_col = col
	if best_key == "":
		return false
	_alive.erase(best_key)
	return true


func _leftmost_x(origin_x: float) -> float:
	var best := INF
	for key in _alive:
		var cell: Array = _parse(key)
		var x: float = origin_x + cell[1] * SPACING
		if x < best:
			best = x
	return best


func _rightmost_x(origin_x: float) -> float:
	var best := -INF
	for key in _alive:
		var cell: Array = _parse(key)
		var x: float = origin_x + cell[1] * SPACING
		if x > best:
			best = x
	return best


func _key(row: int, col: int) -> String:
	return "%d:%d" % [row, col]


func _parse(key: String) -> Array:
	var parts := key.split(":")
	return [int(parts[0]), int(parts[1])]
