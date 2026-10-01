# The row-based score rule, with the numbers spelled out so a reader can learn the
# scoring table from this file alone: top row 30, middle rows 20, bottom row 10.
extends "res://tests/test_case.gd"

const ScoreScript := preload("res://scripts/score.gd")


func test_total_starts_at_zero() -> void:
	var score := ScoreScript.new()
	assert_eq(score.total(), 0, "a fresh score starts at 0")


func test_top_row_scores_30() -> void:
	var score := ScoreScript.new()
	score.add(0)
	assert_eq(score.total(), 30, "row 0 (top) scores 30")


func test_middle_row_scores_20() -> void:
	var score := ScoreScript.new()
	score.add(4)
	assert_eq(score.total(), 20, "row 4 (middle) scores 20")


func test_bottom_row_scores_10() -> void:
	var score := ScoreScript.new()
	score.add(8)
	assert_eq(score.total(), 10, "row 8 (bottom) scores 10")


func test_running_total_accumulates_across_hits() -> void:
	var score := ScoreScript.new()
	score.add(0)
	score.add(4)
	score.add(8)
	assert_eq(score.total(), 60, "30 + 20 + 10 accumulates to 60")
	score.add(0)
	assert_eq(score.total(), 90, "adding another top-row mouse brings it to 90")


func test_reset_clears_the_total() -> void:
	var score := ScoreScript.new()
	score.add(0)
	score.add(4)
	score.reset()
	assert_eq(score.total(), 0, "reset returns the total to 0")
	score.add(8)
	assert_eq(score.total(), 10, "scoring works again after reset")
