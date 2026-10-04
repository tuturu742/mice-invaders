extends Node2D

# The playable scene. This file wires formation.gd's rules to input, collision,
# game state, and drawing. All swarm rules live in scripts/formation.gd; the
# only decisions made here are what the swarm does not know about -- a cat that
# moves with the arrow keys, shots that fly up, and the two ways the game ends.

const Formation := preload("res://scripts/formation.gd")

const SCREEN_WIDTH := 640.0
const SCREEN_HEIGHT := 480.0

const CAT_Y := 440.0
const CAT_W := 48.0
const CAT_H := 24.0
const CAT_SPEED := 300.0

const SHOT_SPEED := 500.0
const SHOT_HALF_SIZE := 3.0
const MOUSE_HALF_SIZE := 12.0

var formation: Formation
var cat_x := SCREEN_WIDTH * 0.5
var shot: Vector2 = Vector2.ZERO
var shot_active := false

var game_over := false
var won := false


func _ready() -> void:
	formation = Formation.new()


func _process(delta: float) -> void:
	if game_over or won:
		if Input.is_action_just_pressed("restart"):
			_restart()
		return

	_handle_input(delta)
	formation.step(delta)
	_update_shot(delta)
	_check_shot_hit()
	_check_outcomes()
	queue_redraw()


func _handle_input(delta: float) -> void:
	var move := Input.get_axis("move_left", "move_right")
	cat_x = clampf(cat_x + move * CAT_SPEED * delta, CAT_W, SCREEN_WIDTH - CAT_W)
	if Input.is_action_just_pressed("fire") and not shot_active:
		shot = Vector2(cat_x, CAT_Y - CAT_H)
		shot_active = true


func _update_shot(delta: float) -> void:
	if shot_active:
		shot.y -= SHOT_SPEED * delta
		if shot.y < -SHOT_HALF_SIZE:
			shot_active = false


func _check_shot_hit() -> void:
	if not shot_active:
		return
	for i in formation.mice.size():
		var mouse := formation.mice[i]
		if absf(shot.x - mouse.x) <= MOUSE_HALF_SIZE and absf(shot.y - mouse.y) <= MOUSE_HALF_SIZE:
			formation.remove_mouse(i)
			shot_active = false
			return


func _check_outcomes() -> void:
	if formation.mice.is_empty():
		won = true
		return
	for mouse in formation.mice:
		if mouse.y >= CAT_Y:
			game_over = true
			return


func _restart() -> void:
	formation = Formation.new()
	cat_x = SCREEN_WIDTH * 0.5
	shot = Vector2.ZERO
	shot_active = false
	game_over = false
	won = false


func _draw() -> void:
	draw_rect(Rect2(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT), Color(0.05, 0.05, 0.1))

	if not game_over:
		_draw_cat()

	for mouse in formation.mice:
		_draw_mouse(mouse)

	if shot_active:
		draw_circle(shot, SHOT_HALF_SIZE, Color(1.0, 0.9, 0.4))

	if won:
		_draw_message("You win")
	elif game_over:
		_draw_message("Game over")


func _draw_cat() -> void:
	var body := Rect2(cat_x - CAT_W * 0.5, CAT_Y - CAT_H, CAT_W, CAT_H)
	draw_rect(body, Color(0.85, 0.55, 0.2))
	var ear_half := CAT_W * 0.22
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(cat_x - CAT_W * 0.5, CAT_Y - CAT_H),
			Vector2(cat_x - CAT_W * 0.5 + ear_half, CAT_Y - CAT_H - CAT_H * 0.6),
			Vector2(cat_x - CAT_W * 0.5 + ear_half * 2.0, CAT_Y - CAT_H),
		]),
		Color(0.85, 0.55, 0.2)
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(cat_x + CAT_W * 0.5, CAT_Y - CAT_H),
			Vector2(cat_x + CAT_W * 0.5 - ear_half, CAT_Y - CAT_H - CAT_H * 0.6),
			Vector2(cat_x + CAT_W * 0.5 - ear_half * 2.0, CAT_Y - CAT_H),
		]),
		Color(0.85, 0.55, 0.2)
	)


func _draw_mouse(pos: Vector2) -> void:
	draw_circle(pos, MOUSE_HALF_SIZE, Color(0.6, 0.6, 0.65))
	draw_circle(pos + Vector2(-4, -4), 2.0, Color(0.9, 0.9, 0.9))


func _draw_message(text: String) -> void:
	var font := ThemeDB.fallback_font
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 32)
	var pos := Vector2((SCREEN_WIDTH - size.x) * 0.5, SCREEN_HEIGHT * 0.4)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(1, 1, 1))
