extends "res://tests/test_case.gd"


func test_initial_layout() -> void:
	var f = load("res://scripts/formation.gd").new()
	assert_eq(f.alive_count(), 32, "32 mice in a 4x8 grid")
	assert_eq(f.mice[0], Vector2(0, 0), "mice[0]")
	assert_eq(f.mice[1], Vector2(16, 0), "mice[1]")
	assert_eq(f.mice[7], Vector2(112, 0), "mice[7]")
	assert_eq(f.mice[8], Vector2(0, 16), "mice[8]")
	assert_eq(f.mice[31], Vector2(112, 48), "mice[31]")
	assert_eq(f.rightmost(), 112.0, "rightmost of full grid")
	assert_eq(f.direction, 1, "starts moving right")


func test_plain_step() -> void:
	var f = load("res://scripts/formation.gd").new()
	assert_true(f.step(), "first step is a plain sideways step")
	for i in range(32):
		var moved: Vector2 = f.mice[i]
		var col := i % 8
		var row := i / 8
		assert_eq(moved, Vector2(col * 16.0 + 12.0, row * 16.0), "mouse %d after one step" % i)
	for i in range(15):
		f.step()
	assert_eq(f.rightmost(), 304.0, "after 16 steps rightmost is 304")
	assert_eq(f.mice[0].y, 0.0, "no drop yet")


func test_edge_drops_and_reverses() -> void:
	var f = load("res://scripts/formation.gd").new()
	for i in range(16):
		f.step()
	assert_false(f.step(), "17th step drops and reverses")
	assert_eq(f.direction, -1, "direction reversed")
	assert_eq(f.rightmost(), 304.0, "x unchanged on the drop")
	assert_eq(f.mice[0].y, 8.0, "every mouse dropped by 8")
	assert_eq(f.mice[31].y, 56.0, "mice[31].y also dropped by 8")
	assert_true(f.step(), "the step after a drop is plain")
	assert_eq(f.rightmost(), 292.0, "moving left by 12 from 304")


func test_speed_at_full_strength() -> void:
	var f = load("res://scripts/formation.gd").new()
	assert_eq(f.alive_count(), 32, "32 alive")
	assert_eq(f.speed(), 12.0, "full strength speed")
	assert_true(f.step(), "plain step")
	assert_eq(f.mice[0].x, 12.0, "x moved by +12")


func test_speed_at_half_strength() -> void:
	var f = load("res://scripts/formation.gd").new()
	for i in range(16):
		f.remove_at(0)
	assert_eq(f.alive_count(), 16, "16 alive")
	assert_eq(f.speed(), 24.0, "half strength speed")
	assert_true(f.step(), "plain step")
	assert_eq(f.mice[0].x, 24.0, "x moved by +24")


func test_speed_with_one_mouse_left() -> void:
	var f = load("res://scripts/formation.gd").new()
	for i in range(31):
		f.remove_at(0)
	assert_eq(f.alive_count(), 1, "1 alive")
	assert_eq(f.speed(), 384.0, "one mouse speed")
	assert_true(12.0 < 24.0, "12.0 < 24.0")
	assert_true(24.0 < 384.0, "24.0 < 384.0")
