# The march of the mice, as pure logic.
#
# No scene, no Node, no autoload, no Input, no rendering: a reviewer instantiates this with
# no scene loaded and calls step() directly. The rules are small enough to hold in one head:
# the swarm moves sideways at a speed set by how many mice remain, and when the next step
# would cross a bound it instead drops by STEP_DROP and turns around.
extends RefCounted

const ROWS := 4
const COLS := 8
const SPACING := 48.0
const ORIGIN := Vector2(64, 80)

const STEP_DROP := 24.0
const SPEED_MIN := 20.0
const SPEED_MAX := 120.0

# Live positions of surviving mice, row-major. Mouse i spawns at row i / COLS, column i % COLS.
var mice: Array[Vector2] = []

# +1 moving right, -1 moving left.
var direction: int = 1

# Current sideways speed in pixels per second.
var speed: float = SPEED_MIN


func _init() -> void:
	mice.clear()
	for r in ROWS:
		for c in COLS:
			mice.append(Vector2(ORIGIN.x + c * SPACING, ORIGIN.y + r * SPACING))
	speed = speed_for(mice.size())


# The speed-up rule: linear in the fraction of the swarm remaining, so a smaller swarm
# always moves at least as fast, clamped never above SPEED_MAX and never below SPEED_MIN.
func speed_for(mouse_count: int) -> float:
	if mouse_count <= 1:
		return SPEED_MIN
	if mouse_count >= ROWS * COLS:
		return SPEED_MAX
	var fraction := (mouse_count - 1) / float(ROWS * COLS - 1)
	return clampf(SPEED_MIN + (SPEED_MAX - SPEED_MIN) * fraction, SPEED_MIN, SPEED_MAX)


# Advance one frame. Returns true when a drop+reverse happened, false when the swarm
# simply slid sideways. The sideways movement is all-or-nothing across the swarm.
func step(delta: float, left_bound: float, right_bound: float) -> bool:
	var move := delta * speed * direction
	for mouse in mice:
		var proposed := mouse.x + move
		if proposed < left_bound or proposed > right_bound:
			for m in mice:
				m.y += STEP_DROP
			direction = -direction
			return true
	for m in mice:
		m.x += move
	return false


# Shrink to n mice from the end, then re-derive speed. No respawn or refill here.
func set_mouse_count(n: int) -> void:
	while mice.size() > n:
		mice.pop_back()
	speed = speed_for(mice.size())


func alive_count() -> int:
	return mice.size()
