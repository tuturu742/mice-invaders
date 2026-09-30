extends RefCounted
class_name Formation

const BASE_SPEED := 20.0
const DEFAULT_ROWS := 5
const DEFAULT_COLUMNS := 10
const DEFAULT_SPACING := Vector2(48, 48)
const DEFAULT_ORIGIN := Vector2(100, 60)
const DEFAULT_LEFT_BOUND := 0.0
const DEFAULT_RIGHT_BOUND := 800.0

var rows: int
var columns: int
var spacing: Vector2
var origin: Vector2
var left_bound: float
var right_bound: float
var horizontal_offset: float
var direction: int


func _init(
	rows: int = DEFAULT_ROWS,
	columns: int = DEFAULT_COLUMNS,
	spacing: Vector2 = DEFAULT_SPACING,
	origin: Vector2 = DEFAULT_ORIGIN,
	left_bound: float = DEFAULT_LEFT_BOUND,
	right_bound: float = DEFAULT_RIGHT_BOUND
) -> void:
	self.rows = rows
	self.columns = columns
	self.spacing = spacing
	self.origin = origin
	self.left_bound = left_bound
	self.right_bound = right_bound
	self.horizontal_offset = 0.0
	self.direction = 1


func get_total_mice() -> int:
	return rows * columns


func get_direction() -> int:
	return direction


func get_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for r in rows:
		for c in columns:
			positions.append(
				Vector2(
					origin.x + horizontal_offset + c * spacing.x,
					origin.y + r * spacing.y
				)
			)
	return positions


func speed_for_remaining(mice_left: int) -> float:
	return BASE_SPEED * get_total_mice() / clamp(mice_left, 1, get_total_mice())


func step(speed: float = BASE_SPEED) -> void:
	var proposed := horizontal_offset + direction * speed
	var leftmost := origin.x + proposed
	var rightmost := origin.x + proposed + (columns - 1) * spacing.x
	if leftmost < left_bound or rightmost > right_bound:
		origin.y += spacing.y
		direction *= -1
	else:
		horizontal_offset = proposed
