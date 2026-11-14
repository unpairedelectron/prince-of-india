extends "res://tests/bot_base.gd"
var out := "user://s"
func _ready():
	var a := OS.get_cmdline_user_args(); if a.size() > 0: out = a[0]
	Game.reset_progress(); Game.settings.touch_controls = "on"
	load_mission("res://scenes/environments/test/asset_test_room.tscn")
	await wait(1.2); _shot("a1_idle_floor")
	p.global_position = Vector2(560, -300); await wait(1.0); _shot("a2_wood_platform")
	p.global_position = Vector2(300, -2); await wait(0.6)
	press("move_right"); await wait(0.9); _shot("a3_run"); release_all()
	await tap("attack", 0.03); await wait(0.12); _shot("a4_attack")
	var h = mission.horse
	p.global_position = h.global_position + Vector2(-60, -2); await wait(0.5); await tap("mount"); await wait(0.6); _shot("a5_mounted_idle")
	press("move_right"); press("gallop"); await wait(1.0); _shot("a6_gallop"); release_all(); await wait(1.0)
	await tap("mount"); await wait(0.5)
	p.global_position = Vector2(3150, -2); await wait(1.5); _shot("a7_soldier")
	mission.queue_free(); await wait(0.2)
	load_mission("res://scenes/environments/gogunda/gogunda.tscn"); await wait(3.0)
	press("move_right"); await wait(0.6); release_all(); _shot("b1_gogunda")
	p.global_position = Vector2(3700, -132); mission.camera.global_position = p.global_position; await wait(1.2); _shot("b2_gogunda_walls")
	mission.queue_free(); await wait(0.2)
	load_mission("res://scenes/environments/haldighati/haldighati.tscn"); await wait(3.0)
	p.global_position = Vector2(3820, -2); mission.camera.global_position = p.global_position; await wait(1.8); _shot("b3_haldighati")
	mission.queue_free(); await wait(0.2)
	load_mission("res://scenes/environments/aravalli/aravalli.tscn"); await wait(3.0)
	press("move_right"); press("gallop"); await wait(1.2); release_all(); _shot("b4_aravalli")
	mission.queue_free(); await wait(0.2)
	var menu = load("res://scenes/menus/main_menu.tscn").instantiate(); add_child(menu); await wait(0.8); _shot("b5_menu")
	get_tree().quit()
func _shot(n):
	get_viewport().get_texture().get_image().save_png(out + "/" + n + ".png"); print("shot ", n)
