class_name Formation
extends RefCounted

const ROWS := 4
const COLS := 8
const SPACING := 16.0
const STEP_SPEED := 12.0
const LEFT_BOUND := 16.0
const RIGHT_BOUND := 304.0

var direction := 1
var drop_distance := 8.0
var origin := Vector2.ZERO
var mice := []

var _total := 0


func _init(rows := ROWS, cols := COLS, spacing := SPACING, start_origin := Vector2.ZERO, start_direction := 1) -> void:
	origin = start_origin
	direction = start_direction
	_total = rows * cols
	mice = []
	for row in range(rows):
		for col in range(cols):
			mice.append(start_origin + Vector2(col * spacing, row * spacing))


func speed() -> float:
	return STEP_SPEED * (float(_total) / float(max(1, alive_count())))


func alive_count() -> int:
	return mice.size()


func leftmost() -> float:
	if mice.is_empty():
		return 0.0
	var x: float = mice[0].x
	for m in mice:
		if m.x < x:
			x = m.x
	return x


func rightmost() -> float:
	if mice.is_empty():
		return 0.0
	var x: float = mice[0].x
	for m in mice:
		if m.x > x:
			x = m.x
	return x


func next_step_x() -> float:
	return direction * speed()


func step() -> bool:
	var delta := next_step_x()
	var new_left := leftmost() + delta
	var new_right := rightmost() + delta
	var hit_edge := (delta < 0.0 and new_left < LEFT_BOUND) or (delta > 0.0 and new_right > RIGHT_BOUND)
	if hit_edge:
		direction = -direction
		for i in range(mice.size()):
			mice[i] = mice[i] + Vector2(0, drop_distance)
		return false
	for i in range(mice.size()):
		mice[i] = mice[i] + Vector2(delta, 0)
	return true


func remove_at(index: int) -> void:
	if index < 0 or index >= mice.size():
		return
	mice.remove_at(index)
