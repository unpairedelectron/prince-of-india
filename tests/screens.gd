extends Node
## Captures reference screenshots: godot (windowed) res://tests/screens.tscn -- <outdir>
var out := "user://screens"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	Game.reset_progress()
	Game.settings.touch_controls = "on"
	var menu = load("res://scenes/menus/main_menu.tscn").instantiate()
	add_child(menu)
	await _wait(40); _shot("01_menu"); menu.queue_free()
	Game.pending_story = StoryText.MISSION_1_INTRO; Game.pending_next_scene = ""
	var story = load("res://scenes/menus/story_card.tscn").instantiate()
	add_child(story)
	await _wait(50); _shot("02_story"); story.queue_free()
	var m = load("res://scenes/environments/gogunda/gogunda.tscn").instantiate()
	add_child(m)
	var p: Player = m.player
	await _wait(170)
	Input.action_press("move_right"); await _wait(30); Input.action_release("move_right")
	_shot("03_courtyard")
	for spot in [[Vector2(1780, -2), "04_training", "attack"], [Vector2(2540, -2), "05_sparring", "telegraph"], [Vector2(3700, -132), "06_steps", ""],
			[Vector2(4300, -360), "07_ramparts", "jump"], [Vector2(5800, -2), "08_stable", ""]]:
		p.global_position = spot[0]; p.velocity = Vector2.ZERO
		m.camera.global_position = spot[0] + Vector2(0, -90)
		await _wait(60)
		if spot[2] == "attack":
			Input.action_press("attack"); await _wait(8); Input.action_release("attack"); await _wait(4)
		if spot[2] == "jump":
			Input.action_press("jump"); await _wait(14); Input.action_release("jump")
		if spot[2] == "telegraph":
			for i in 240:
				await get_tree().physics_frame
				if m.sparring.state == Soldier.S.TELEGRAPH and m.sparring._t > 0.3: break
		_shot(spot[1])
	m.horse.global_position = Vector2(6600, -2); m.horse.mount_rider(p)
	Input.action_press("move_right"); Input.action_press("gallop")
	await _wait(150); _shot("09_gallop")
	m.horse.global_position = Vector2(8700, -2)
	await _wait(20)
	Input.action_press("jump"); await _wait(16); Input.action_release("jump")
	_shot("10_jump_log")
	get_tree().quit()

func _wait(n):
	for i in n: await get_tree().process_frame

func _shot(name):
	var img := get_viewport().get_texture().get_image()
	img.save_png(out + "/" + name + ".png")
	print("shot ", name)
