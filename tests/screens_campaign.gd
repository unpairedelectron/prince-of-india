extends "res://tests/bot_base.gd"
## Screenshots: the menu, hero select, and views inside campaign levels.
## Usage: godot --path . res://tests/screens_campaign.tscn -- <output folder> [<level id> <x> ...]
var out := "user://screens"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	Game.reset_progress()
	Game.settings.touch_controls = "off"
	if args.size() <= 1:
		Game.progress.missions_completed = ["gogunda", "shivaji_1", "lakshmibai_1"]
		Game.progress.stars = {"gogunda": 3, "haldighati": 2, "shivaji_1": 3}
		var menu: Node = load(Game.SCENE_MENU).instantiate()
		add_child(menu)
		await wait(0.6)
		_shot("menu")
		menu._on_heroes()
		await wait(0.4)
		_shot("heroes")
		menu._on_levels("shivaji")
		await wait(0.4)
		_shot("levels")
		menu.queue_free()
	var i := 1
	while i + 1 < args.size():
		var id: String = args[i]
		Game.progress.current_mission = id
		mission = load(Game.MISSIONS[id]).instantiate()
		add_child(mission)
		p = mission.player
		await wait(2.6)
		for xs in args[i + 1].split(","):
			var x := float(xs)
			var y := 0.0
			for r in mission.built.ground_runs:
				if x >= r[0] and x <= r[1]:
					y = r[2]
			p.global_position = Vector2(x, y - 2)
			p.velocity = Vector2.ZERO
			mission.camera.global_position = p.global_position
			await wait(1.3)
			_shot("%s_%d" % [id, int(x)])
		mission.queue_free()
		await wait(0.3)
		i += 2
	Game.reset_progress()
	get_tree().quit()


func _shot(n: String) -> void:
	get_viewport().get_texture().get_image().save_png(out + "/" + n + ".png")
	print("shot ", n)
