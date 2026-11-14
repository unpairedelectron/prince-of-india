extends "res://tests/bot_base.gd"
var out := "user://screens"

func _ready():
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: out = args[0]
	Game.reset_progress()
	Game.settings.touch_controls = "on"
	load_mission("res://scenes/environments/haldighati/haldighati.tscn")
	await wait(2.7)
	for spot in [[Vector2(900, -2), "m2_01_pass"], [Vector2(3250, -2), "m2_02_archer"], [Vector2(3820, -2), "m2_03_allies"]]:
		p.global_position = spot[0]; mission.camera.global_position = spot[0]
		await wait(1.6); _shot(spot[1])
	p.global_position = Vector2(5470, -2); mission.camera.global_position = p.global_position
	await wait(4.0); _shot("m2_04_chokepoint")
	for e in get_tree().get_nodes_in_group("imperial"):
		if e.global_position.x > 5300 and e.global_position.x < 6700: e.health.damage(999)
	mission._reset_encounters()
	p.global_position = Vector2(7000, -2); mission.camera.global_position = p.global_position
	press("move_right"); await wait(1.4); release_all(); _shot("m2_05_volley")
	var h = mission.horse
	h.reset_to(Vector2(9800, -2), 1); h.mount_rider(p)
	press("move_right"); press("gallop"); await wait(1.5); _shot("m2_06_escape"); release_all()
	mission.queue_free(); await wait(0.3)
	load_mission("res://scenes/environments/aravalli/aravalli.tscn")
	await wait(2.7)
	h = mission.horse
	for spot in [[Vector2(400, -2), "m3_01_start"], [Vector2(2620, -2), "m3_02_bridge"], [Vector2(3750, -2), "m3_03_branch"], [Vector2(4300, 20), "m3_04_stream"], [Vector2(6350, 80), "m3_05_descent"]]:
		h.reset_to(spot[0], 1); mission.camera.global_position = spot[0]
		press("move_right"); await wait(0.9); release_all(); await wait(0.2); _shot(spot[1])
	h.reset_to(Vector2(9400, -2), 1)
	press("move_right"); press("gallop"); await wait(0.6); release_all()
	for i in 900:
		await get_tree().physics_frame
		if mission._tribute != null: break
	await wait(0.5); _shot("m3_06_rest")
	get_tree().quit()

func _shot(n):
	get_viewport().get_texture().get_image().save_png(out + "/" + n + ".png"); print("shot ", n)
