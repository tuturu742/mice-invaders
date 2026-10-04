# The swarm's rules, and nothing else. A plain RefCounted class with no scene
# dependency, so it can be driven by tests and by the scene alike. It knows how
# the grid is laid out, how it marches and drops at the edge, and how fast it
# moves as its numbers fall. It knows nothing about input, drawing, or shots.
extends RefCounted

# --- Explicit data ---------------------------------------------------------
# Every rule the swarm follows is a named number here, so a test can state the
# same numbers back and mean exactly the same thing.

const ROWS := 5
const COLUMNS := 8

# Horizontal and vertical distance between neighbouring mice.
const SPACING := Vector2(48.0, 48.0)

# Where the top-left mouse sits when the swarm is first laid out.
const ORIGIN := Vector2(80.0, 80.0)

# The x-limits a mouse position may not cross. "Crossing" one of these is what
# triggers a drop and a reversal instead of a sideways step.
const LEFT_BOUND := 40.0
const RIGHT_BOUND := 600.0

# How far the whole swarm falls when it reaches an edge.
const ROW_DROP_DISTANCE := 32.0

# Speed at full strength, in pixels per second.
const BASE_SPEED := 40.0

# --- State -----------------------------------------------------------------

var mice: Array[Vector2] = []

# +1 marches right, -1 marches left.
var direction: int = 1


func _init() -> void:
	mice.clear()
	for r in ROWS:
		for c in COLUMNS:
			mice.append(ORIGIN + Vector2(c * SPACING.x, r * SPACING.y))


# --- Movement --------------------------------------------------------------

# Advance the swarm by `delta` seconds. Moves sideways by the current speed;
# if that sideways move would push any mouse past a bound, it is not made, the
# swarm drops one row instead, and the direction reverses.
func step(delta: float) -> void:
	var dx := speed() * delta * float(direction)
	if _would_cross_bound(dx):
		_drop_row()
		direction = -direction
	else:
		_shift_x(dx)


# --- Speed -----------------------------------------------------------------

# Speed scales with how much of the swarm has been destroyed: full strength is
# BASE_SPEED, and it rises to nearly double that as the last mouse is hunted.
func speed() -> float:
	var total := float(ROWS * COLUMNS)
	var remaining := float(mice.size())
	if remaining <= 0.0:
		return 0.0
	return BASE_SPEED * (1.0 + (total - remaining) / total)


# Remove the mouse at `index` (a shot hit it). Speed picks up automatically
# because it is computed from the count that remains.
func remove_mouse(index: int) -> void:
	if index >= 0 and index < mice.size():
		mice.remove_at(index)


# --- Internals -------------------------------------------------------------

func _would_cross_bound(dx: float) -> bool:
	for mouse in mice:
		var next_x := mouse.x + dx
		if next_x < LEFT_BOUND or next_x > RIGHT_BOUND:
			return true
	return false


func _shift_x(dx: float) -> void:
	for i in mice.size():
		var mouse := mice[i]
		mouse.x += dx
		mice[i] = mouse


func _drop_row() -> void:
	for i in mice.size():
		var mouse := mice[i]
		mouse.y += ROW_DROP_DISTANCE
		mice[i] = mouse
