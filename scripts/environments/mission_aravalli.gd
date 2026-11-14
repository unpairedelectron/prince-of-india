class_name MissionAravalli
extends MissionBase
## Mission 3 - Chetak: The Final Ride (Aravalli routes, after Haldighati).
## Horseback obstacle course; the ending follows the TRADITIONAL account of
## Chetak, handled as a quiet, non-graphic tribute (no injury is shown).

const L = preload("res://data/missions/aravalli_layout.gd")

const LIGHT_GOLD := Color(1.05, 0.9, 0.74)
const LIGHT_MUTED := Color(0.74, 0.7, 0.8)

var _final := false
var _tribute_ready := false
var _tribute: Area2D


func _init() -> void:
	mission_id = "aravalli"
	title = "Mission 3 - Chetak: The Final Ride"
	place_caption = "THE ARAVALLI HILLS  -  1576"
	layout = L
	sky_colors = [Color("6d6aa8"), Color("e9a066"), Color("f5c27a")]
	grade = LIGHT_GOLD
	parallax = [
		[Vector2(0.05, 0.08), "bg:aravalli_forest_parallax", 82.0, 85, -55, Color(1.0, 0.82, 0.7)],
		[Vector2(0.18, 0.15), "bg:forest_silhouette", 86.0, 30, -50, Color(0.55, 0.5, 0.45, 0.9)],
		[Vector2(0.25, 0.5), "mid_hills", 60.0, 43, -46, Color(0.85, 0.8, 0.85)],
		[Vector2(0.45, 0.7), "forest", 60.0, 47, -40, Color(0.85, 0.85, 0.85)],
		[Vector2(1.25, 1.0), "foreground", 210.0, 53, 30],
	]
	ambient = {"color": Color(1.0, 0.85, 0.55, 0.3), "amount": 26, "speed": 90.0}
	music = "ride_theme"
	horse_home = L.HORSE_HOME
	start_objective = "Ride for the hills. Carry Pratap to safety."
	outro_story = StoryText.MISSION_3_OUTRO
	next_scene = Game.SCENE_MENU


func _build_mission() -> void:
	horse.allow_dismount = false


func _process(delta: float) -> void:
	super._process(delta)
	# golden evening slowly turning muted as the ride goes on
	if not _final and player:
		var k := clampf(player.global_position.x / 9500.0, 0.0, 1.0)
		_grade_node.color = LIGHT_GOLD.lerp(LIGHT_MUTED, k * 0.6)


func _on_trigger(id: String, _body: Node) -> void:
	match id:
		"ride": _hint_once("ride", _k("Hold D to ride, SHIFT to gallop, SPACE to leap. Watch Chetak's stamina.",
			"Hold RIGHT to ride, GALLOP for speed, JUMP to leap. Watch Chetak's stamina."))
		"gap": _hint_once("gap", "Saffron flags mark safe landing ground.")
		"bridge": _hint_once("bridge", "The rope bridge is failing - keep your speed, and leap the missing planks.")
		"branch": _hint_once("branch", "Low branches ahead: stay on the ground beneath them. Jumping into a branch makes Chetak balk.")
		"stream": _hint_once("stream", "The stream slows Chetak. Build speed again on the far bank.")
		"passage": _hint_once("passage", "A narrow passage - loose rocks fall beyond it. Watch the shadows.")
		"descent": _hint_once("descent", "A steep descent onto crumbling ground. Don't stop at the bottom.")
		"final_leap": _hint_once("final_leap", "The stream ahead is wide. Gallop, and leap from the edge.")
		"final":
			if player.is_mounted() and not _final:
				_final_sequence()


func _final_sequence() -> void:
	_final = true
	player.input_enabled = false
	horse.input_enabled = false
	ui.set_objective("")
	Audio.stop_all_loops()
	Audio.play_ambience("wind")
	horse.auto_dir = 1
	horse.auto_speed = 300.0
	var tw := create_tween()
	tw.tween_property(_grade_node, "color", LIGHT_MUTED, 4.0)
	await get_tree().create_timer(1.6).timeout
	horse.auto_speed = 140.0
	while horse.global_position.x < L.REST_SPOT.x - 30.0:
		await get_tree().physics_frame
	horse.auto_speed = 0.0
	await get_tree().create_timer(1.0).timeout
	horse.auto_dir = 0
	horse.allow_dismount = true
	horse.release_rider()
	player.lock("idle")
	await get_tree().create_timer(1.2).timeout
	horse.resting = true
	Audio.sfx("snort", 0.0, -10.0)
	await get_tree().create_timer(3.5).timeout   # silent moment
	# Return control: the player chooses when to say farewell.
	_tribute = Area2D.new()
	_tribute.add_to_group("interactable")
	_tribute.collision_layer = 32
	_tribute.collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(220, 120)
	cs.shape = sh
	cs.position = Vector2(0, -60)
	_tribute.add_child(cs)
	_tribute.position = horse.global_position
	_tribute.set_script(preload("res://scripts/objects/tribute_spot.gd"))
	_tribute.done.connect(_farewell)
	add_child(_tribute)
	player.unlock()
	ui.set_objective("Stay a while beside Chetak.")
	ui.show_hint(_k("Walk to Chetak and press E.", "Walk to Chetak and tap STAY."), 8.0)


func _farewell() -> void:
	player.lock("yield")   # kneels quietly
	await get_tree().create_timer(2.5).timeout
	await ui.fade_to(1.0, 2.5)
	horse.visible = false
	decor.items.append({"type": "memorial", "pos": horse.global_position})
	player.global_position = horse.global_position + Vector2(-110, -2)
	player.lock("yield")
	await get_tree().create_timer(1.0).timeout
	await ui.fade_to(0.0, 2.5)
	await get_tree().create_timer(3.0).timeout
	complete_mission()


func _stats_title() -> String:
	return "Chetak: The Final Ride  -  Aravalli hills"
