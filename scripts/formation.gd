# Pure swarm rules for Mice Invaders.
#
# A plain RefCounted with no scene, Node, input, drawing, or rendering dependency. It owns
# exactly the swarm rules: laying out the grid, marching it sideways, dropping and reversing
# at the edges, and reporting how fast it should move as mice die. Everything else -- the
# cat, the shots, the win/lose conditions, the drawing -- lives in the scene, which drives
# this class without duplicating any of these rules.
class_name Formation
extends RefCounted

# Grid shape. These are the explicit constructor values: how many rows and columns, how far
# apart the mice sit horizontally and vertically, and where the top-left mouse starts.
var rows: int
var cols: int
var h_spacing: float
var v_spacing: float
var origin: Vector2

# The horizontal speed at full strength. speed() scales it up as mice are removed, so the
# swarm moves faster the fewer mice remain.
var base_speed: float = 1.0

# +1 marches right, -1 marches left. Reversed automatically when the swarm drops at an edge.
var direction: int = 1

# Bounds the mice must not cross. Stepping past either one triggers a drop and a reversal.
var left_bound: float = -INF
var right_bound: float = INF

var _positions: Array[Vector2] = []


func _init(p_rows: int, p_cols: int, p_h_spacing: float, p_v_spacing: float, p_origin: Vector2) -> void:
	rows = p_rows
	cols = p_cols
	h_spacing = p_h_spacing
	v_spacing = p_v_spacing
	origin = p_origin
	_positions = layout()


# The full grid, laid out row by row, left to right, top to bottom.
func layout() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for r in rows:
		for c in cols:
			result.append(position_of(r, c))
	return result


# Where a single mouse sits, given its row and column.
func position_of(row: int, col: int) -> Vector2:
	return Vector2(origin.x + col * h_spacing, origin.y + row * v_spacing)


# The current positions, one per mouse, in the same order layout() produced them.
func positions() -> Array[Vector2]:
	return _positions


# Total mice in the grid, alive or not.
func total() -> int:
	return rows * cols


# Mice still in play. Shots remove them, and the swarm speeds up as this shrinks.
func living() -> int:
	return _positions.size()


# Remove the mouse at the given index. The scene calls this when a shot hits; it never
# changes any other mouse, so the swarm marches on with the survivors.
func remove_at(index: int) -> void:
	_positions.remove_at(index)


# Movement speed for a given number of living mice. Inversely proportional to the count:
# full strength moves at base_speed, and the swarm is fastest when exactly one mouse remains.
func speed(living: int) -> float:
	if living <= 0:
		return 0.0
	return base_speed * float(total()) / float(living)


# The horizontal limits the swarm must respect. The scene supplies these; the rule layer
# only needs to know them to decide when to drop.
func set_bounds(p_left: float, p_right: float) -> void:
	left_bound = p_left
	right_bound = p_right


# One march step. Moves sideways by the current speed in the current direction; if that
# would push any mouse across a bound, it does not move sideways at all, instead dropping
# every mouse by exactly one row spacing and reversing direction.
func step(living: int) -> void:
	var dx := speed(living) * direction
	if _would_cross(dx):
		for i in _positions.size():
			var p: Vector2 = _positions[i]
			p.y += v_spacing
			_positions[i] = p
		direction = -direction
	else:
		for i in _positions.size():
			var p: Vector2 = _positions[i]
			p.x += dx
			_positions[i] = p


func _would_cross(dx: float) -> bool:
	for p in _positions:
		var next_x := p.x + dx
		if next_x < left_bound or next_x > right_bound:
			return true
	return false
