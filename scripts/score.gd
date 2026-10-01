# The score rule for mice destroyed, by the row they occupied.
#
# Pure and headless-testable on purpose: no Node, no scene, no autoload, no signals. A
# caller constructs it, calls add() for each destroyed mouse, and reads total().
#
# Rows are 0-based: row 0 is the top row, row 8 the bottom row, rows 1..7 are the middle.
# Points are worth more the higher the mouse was.
extends RefCounted


const TOP_ROW := 0
const BOTTOM_ROW := 8
const TOP_ROW_POINTS := 30
const MIDDLE_ROW_POINTS := 20
const BOTTOM_ROW_POINTS := 10

var _total: int = 0


# Adds the points for the given row to the running total.
# Out-of-range rows are ignored (no points, no crash) so a stray index cannot break a
# headless run.
func add(row: int) -> void:
	_total += _points_for_row(row)


func total() -> int:
	return _total


func reset() -> void:
	_total = 0


func _points_for_row(row: int) -> int:
	if row == TOP_ROW:
		return TOP_ROW_POINTS
	if row == BOTTOM_ROW:
		return BOTTOM_ROW_POINTS
	if row > TOP_ROW and row < BOTTOM_ROW:
		return MIDDLE_ROW_POINTS
	return 0
