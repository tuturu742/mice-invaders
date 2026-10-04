# The scene: input and drawing only. Every swarm decision lives in Formation.
#
# The cat, the mice and the shot are all plain drawn shapes -- there is no sprite to load,
# so a missing asset can never break the build.
extends Node2D

const SCREEN := Vector2(640.0, 480.0)
const CAT_SIZE := Vector2(60.0, 24.0)
const CAT_SPEED := 260.0
const CAT_Y := 430.0
const SHOT_SIZE := Vector2(4.0, 12.0)
const SHOT_SPEED := 420.0
const MOUSE_SIZE := Vector2(22.0, 16.0)

const FORMATION_SCRIPT := preload("res://scripts/formation.gd")

var formation: RefCounted
var cat_x: float
var shot_pos: Vector2
var shot_active: bool = false
var game_over: bool = false
var won: bool = false


func _ready() -> void:
	restart()


func restart() -> void:
	cat_x = (SCREEN.x - CAT_SIZE.x) * 0.5
	shot_active = false
	shot_pos = Vector2.ZERO
	game_over = false
	won = false
	# Bounds keep every mouse cell inside the screen. The swarm starts upper-left-ish so it
	# has room to march right first.
	formation = FORMATION_SCRIPT.new(
		5, 8, 40.0, 34.0, Vector2(80.0, 60.0), 40.0, 40.0, SCREEN.x - 40.0, 12.0, 260.0
	)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") and (won or game_over):
		restart()
		queue_redraw()
		return

	if not won and not game_over:
		_update_cat(delta)
		_update_shot(delta)
		_update_swarm(delta)
		_check_end()
	queue_redraw()


func _update_cat(delta: float) -> void:
	var move := Input.get_axis("ui_left", "ui_right")
	cat_x += move * CAT_SPEED * delta
	cat_x = clampf(cat_x, 0.0, SCREEN.x - CAT_SIZE.x)


func _update_shot(delta: float) -> void:
	if not shot_active:
		return
	shot_pos.y -= SHOT_SPEED * delta
	if shot_pos.y + SHOT_SIZE.y < 0.0:
		shot_active = false
		return
	# A shot overlapping any living mouse removes the closest one.
	for mouse in formation.positions():
		var rect := Rect2(mouse - MOUSE_SIZE * 0.5, MOUSE_SIZE)
		if rect.has_point(shot_pos):
			formation.remove_closest(mouse)
			shot_active = false
			return


func _update_swarm(delta: float) -> void:
	# The speed is asked of the formation, never hard-coded here. The delta passed is scaled
	# so one "step" is a consistent sideways distance regardless of frame rate.
	formation.step(delta)


func _check_end() -> void:
	if formation.mouse_count() == 0:
		won = true
		return
	var lowest := -INF
	for mouse in formation.positions():
		lowest = maxf(lowest, mouse.y)
	if lowest >= CAT_Y:
		game_over = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fire") and not shot_active and not won and not game_over:
		shot_active = true
		shot_pos = Vector2(cat_x + CAT_SIZE.x * 0.5, CAT_Y)


func _draw() -> void:
	# A plain background.
	draw_rect(Rect2(Vector2.ZERO, SCREEN), Color(0.05, 0.05, 0.12))

	# The mice.
	for mouse in formation.positions():
		draw_rect(Rect2(mouse - MOUSE_SIZE * 0.5, MOUSE_SIZE), Color(0.85, 0.8, 0.75))

	# The cat.
	draw_rect(Rect2(Vector2(cat_x, CAT_Y), CAT_SIZE), Color(0.95, 0.6, 0.2))

	# The shot.
	if shot_active:
		draw_rect(Rect2(shot_pos, SHOT_SIZE), Color(1.0, 1.0, 0.4))

	if won:
		_draw_center_text("You win")
	elif game_over:
		_draw_center_text("Game over")


func _draw_center_text(text: String) -> void:
	var font := ThemeDB.fallback_font
	var size := 48
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(
		font,
		Vector2((SCREEN.x - width) * 0.5, SCREEN.y * 0.5),
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		size,
		Color(1.0, 1.0, 1.0)
	)
