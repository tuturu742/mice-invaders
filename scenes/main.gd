# The single-screen playable game. Owns input, drawing, and collision/game-state; delegates
# every swarm rule -- layout, marching, dropping, reversing, speeding up -- to Formation, so
# this file never duplicates movement logic.
extends Node2D

const Formation := preload("res://scripts/formation.gd")

# Swarm shape (explicit configuration values handed to Formation).
const ROWS := 4
const COLS := 8
const H_SPACING := 60.0
const V_SPACING := 50.0
const FORMATION_TOP := 80.0
const BASE_SPEED := 0.7

# Sizes and feel, independent of the swarm rules.
const CAT_W := 56.0
const CAT_H := 22.0
const CAT_SPEED := 340.0
const CAT_BOTTOM_MARGIN := 50.0

const MOUSE_RADIUS := 14.0
const SHOT_RADIUS := 5.0
const SHOT_SPEED := 500.0
const SHOT_COOLDOWN := 0.35

# One formation step per frame-equivalent; marching is framerate independent.
const STEP_INTERVAL := 1.0 / 60.0

var screen := Vector2(800.0, 600.0)

var formation: Formation
var cat_x := 0.0
var cat_y := 0.0
var shots: Array[Vector2] = []
var step_accum := 0.0
var shot_cooldown := 0.0
var state := "playing"


func _ready() -> void:
	var vs := get_viewport_rect().size
	if vs.x > 0.0 and vs.y > 0.0:
		screen = vs
	restart()


func restart() -> void:
	var swarm_width := (COLS - 1) * H_SPACING
	var origin := Vector2((screen.x - swarm_width) / 2.0, FORMATION_TOP)
	formation = Formation.new(ROWS, COLS, H_SPACING, V_SPACING, origin)
	formation.base_speed = BASE_SPEED
	formation.set_bounds(30.0, screen.x - 30.0)
	cat_x = screen.x / 2.0
	cat_y = screen.y - CAT_BOTTOM_MARGIN
	shots.clear()
	step_accum = 0.0
	shot_cooldown = 0.0
	state = "playing"
	queue_redraw()


func _process(delta: float) -> void:
	var move := 0.0
	if Input.is_key_pressed(KEY_LEFT):
		move -= CAT_SPEED
	if Input.is_key_pressed(KEY_RIGHT):
		move += CAT_SPEED
	if move != 0.0:
		cat_x = clampf(cat_x + move * delta, CAT_W / 2.0, screen.x - CAT_W / 2.0)

	if state != "playing":
		queue_redraw()
		return

	step_accum += delta
	while step_accum >= STEP_INTERVAL:
		step_accum -= STEP_INTERVAL
		formation.step(formation.living())

	shot_cooldown = maxf(shot_cooldown - delta, 0.0)
	for i in range(shots.size() - 1, -1, -1):
		var s: Vector2 = shots[i]
		s.y -= SHOT_SPEED * delta
		shots[i] = s
		if s.y < 0.0:
			shots.remove_at(i)

	_check_collisions()
	_check_end()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE and state == "playing":
			_fire()
		elif event.keycode == KEY_ENTER and state != "playing":
			restart()


func _fire() -> void:
	if shot_cooldown > 0.0:
		return
	shot_cooldown = SHOT_COOLDOWN
	shots.append(Vector2(cat_x, cat_y - CAT_H / 2.0))


func _check_collisions() -> void:
	var positions := formation.positions()
	for si in range(shots.size() - 1, -1, -1):
		var s: Vector2 = shots[si]
		var hit := -1
		for mi in positions.size():
			if s.distance_to(positions[mi]) < MOUSE_RADIUS + SHOT_RADIUS:
				hit = mi
				break
		if hit >= 0:
			formation.remove_at(hit)
			shots.remove_at(si)


func _check_end() -> void:
	if formation.living() == 0:
		state = "won"
		return
	var cat_row := cat_y - CAT_H / 2.0 - MOUSE_RADIUS
	for p in formation.positions():
		if p.y >= cat_row:
			state = "lost"
			return


func _draw() -> void:
	_draw_mice()
	_draw_shots()
	_draw_cat()
	if state == "won":
		_draw_message("You win")
	elif state == "lost":
		_draw_message("Game over")


func _draw_cat() -> void:
	var top := cat_y - CAT_H / 2.0
	var body := Rect2(cat_x - CAT_W / 2.0, top, CAT_W, CAT_H)
	draw_rect(body, Color(0.55, 0.40, 0.22), true)
	var ear_w := CAT_W / 5.0
	var ear_h := CAT_H * 0.7
	draw_colored_polygon(PackedVector2Array([
		Vector2(cat_x - CAT_W / 2.0, top),
		Vector2(cat_x - CAT_W / 2.0 + ear_w, top),
		Vector2(cat_x - CAT_W / 2.0 + ear_w / 2.0, top - ear_h),
	]), Color(0.55, 0.40, 0.22))
	draw_colored_polygon(PackedVector2Array([
		Vector2(cat_x + CAT_W / 2.0, top),
		Vector2(cat_x + CAT_W / 2.0 - ear_w, top),
		Vector2(cat_x + CAT_W / 2.0 - ear_w / 2.0, top - ear_h),
	]), Color(0.55, 0.40, 0.22))
	draw_circle(Vector2(cat_x - CAT_W / 4.0, cat_y - 2.0), 2.5, Color(0.1, 0.1, 0.1))
	draw_circle(Vector2(cat_x + CAT_W / 4.0, cat_y - 2.0), 2.5, Color(0.1, 0.1, 0.1))


func _draw_mice() -> void:
	var color := Color(0.62, 0.62, 0.68)
	for p in formation.positions():
		draw_circle(p, MOUSE_RADIUS, color)
		draw_circle(p + Vector2(-8.0, -8.0), 5.0, color)
		draw_circle(p + Vector2(8.0, -8.0), 5.0, color)


func _draw_shots() -> void:
	for s in shots:
		draw_rect(Rect2(s.x - 2.0, s.y - 8.0, 4.0, 16.0), Color(1.0, 0.85, 0.25), true)


func _draw_message(text: String) -> void:
	var font := ThemeDB.fallback_font
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 32)
	var pos := Vector2((screen.x - size.x) / 2.0, (screen.y - size.y) / 2.0)
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color(1.0, 1.0, 1.0))
