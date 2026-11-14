class_name MissionGogunda
extends MissionBase
## Mission 1 - The Oath of Mewar (Gogunda, 1572).
## Tutorial flow: courtyard > training ground > fort walls > stable > course.
## All tutorial content (targets, sparring partners, course) is FICTIONAL.

const L = preload("res://data/missions/gogunda_layout.gd")

var training_gate: Gate
var stable_gate: Gate
var sparring: Soldier
var final_opponents: Array = []
var _final_defeated := 0
var _dummy_hits := 0


func _init() -> void:
	mission_id = "gogunda"
	title = "Mission 1 - The Oath of Mewar"
	place_caption = "GOGUNDA  -  1572"
	layout = L
	sky_colors = [Color("86b6d8"), Color("f0cf98"), Color("f5d9a6")]
	grade = Color(1.0, 0.97, 0.92)
	parallax = [
		[Vector2(0.05, 0.08), "bg:kumbhalgarh_parallax", 82.0, 85, -55],
		[Vector2(0.15, 0.15), "bg:fort_silhouette", 84.0, 30, -50, Color(1, 1, 1, 0.5)],
		[Vector2(0.25, 0.5), "mid_hills", 60.0, 23, -45],
		[Vector2(0.4, 0.7), "near_hills", 70.0, 37, -40],
		[Vector2(0.65, 0.85), "town", 40.0, 51, -30],
		[Vector2(1.25, 1.0), "foreground", 210.0, 71, 30],
	]
	music = "gogunda_theme"
	horse_home = L.HORSE_HOME
	start_objective = "Explore the royal courtyard."
	outro_story = StoryText.MISSION_1_OUTRO
	next_mission = "haldighati"


func _build_mission() -> void:
	for x in L.DUMMIES:
		var d := TrainingDummy.new()
		d.position = Vector2(x, 0)
		d.struck.connect(_on_dummy_struck)
		add_child(d)
	training_gate = Gate.new()
	training_gate.position = Vector2(3150, 0)
	add_child(training_gate)
	stable_gate = Gate.new()
	stable_gate.position = Vector2(6230, 0)
	stable_gate.size = Vector2(36, 260)
	add_child(stable_gate)
	# invisible horse-only barrier at the dismount post (on-foot player passes)
	var barrier := StaticBody2D.new()
	barrier.collision_layer = 16
	barrier.collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(30, 400)
	cs.shape = sh
	barrier.position = Vector2(10400, -200)
	barrier.add_child(cs)
	add_child(barrier)

	sparring = spawn_soldier(Vector2(2660, 0), "training", "imperial",
		{"max_health": 50.0, "attack_damage": 8.0, "telegraph_time": 0.62, "block_chance": 0.25})
	sparring.defeated.connect(_on_sparring_defeated)
	for d in [[Vector2(10650, 0), 55.0, 9.0, 0.55, 0.3], [Vector2(10860, 0), 70.0, 10.0, 0.48, 0.35]]:
		var s := spawn_soldier(d[0], "training", "imperial",
			{"max_health": d[1], "attack_damage": d[2], "telegraph_time": d[3], "block_chance": d[4]})
		s.defeated.connect(_on_final_defeated)
		final_opponents.append(s)


func _apply_progress_state(cp: int) -> void:
	if cp >= 2:
		_retire_soldier(sparring)
		training_gate.open()
		ui.set_objective("Cross the fort walls.")
	if cp >= 4:
		ui.set_objective("Go to the stable and meet Chetak.")
	if cp >= 5:
		stable_gate.open()
		ui.set_objective("Ride the fort approach course.")
	if cp >= 7:
		horse.allow_dismount = true
		ui.set_objective("Simulated encounter: overcome both practice opponents.")


func _retire_soldier(s: Soldier) -> void:
	if is_instance_valid(s):
		s.visible = false
		s.process_mode = Node.PROCESS_MODE_DISABLED
		s.collision_layer = 0


func _on_place_extra(index: int, cp: Checkpoint) -> void:
	if cp.mounted:
		return
	if index >= 7:
		horse.reset_to(L.HORSE_POST, 1)
		horse.allow_dismount = true
	elif index <= 4:
		horse.reset_to(L.HORSE_HOME, -1)


func _reset_encounters() -> void:
	for s in [sparring] + final_opponents:
		if is_instance_valid(s) and s.state != Soldier.S.DEFEATED and s.visible:
			s.reset_to_home()


func _on_trigger(id: String, body: Node) -> void:
	match id:
		"move": _hint_once("move", _k("Move with A / D or the arrow keys.", "Hold LEFT / RIGHT with your left thumb to walk."))
		"run": _hint_once("run", "Keep holding a direction to break into a run - and, after a while, a sprint that uses stamina.")
		"jump": _hint_once("jump", _k("SPACE to jump. Hold it longer to leap higher.", "Tap JUMP to leap. Hold it longer to leap higher."))
		"attack":
			ui.set_objective("Training ground: strike the straw targets.")
			_hint_once("attack", _k("J to strike. Tap J again quickly for a three-blow combination.", "Tap the SWORD button to strike. Tap again quickly for a three-blow combination."))
		"spar":
			if sparring.state != Soldier.S.DEFEATED:
				ui.set_objective("Training bout: overcome your sparring partner.")
				_hint_once("spar", _k("He raises his sword and flashes '!' before striking. Hold K to block - block just as the blow lands to PARRY. L to dodge.",
					"He raises his sword and flashes '!' before striking. Hold SHIELD to block - block just as the blow lands to PARRY. Use DODGE to roll clear."), 9.0)
		"ladder": _hint_once("ladder", _k("W / S to climb the ladder.", "Use UP / DOWN to climb the ladder."))
		"crumble": _hint_once("crumble", "Cracked slabs give way. Keep moving!")
		"stones": _hint_once("stones", "Loose masonry falls here. Watch the shadows and time your run.")
		"stable":
			ui.set_objective("Go to the stable and meet Chetak.")
		"mount": _hint_once("mount", _k("Press F (or E) to mount Chetak.", "Tap MOUNT to ride Chetak."))
		"gap": _hint_once("gap", "Wide gaps need a full gallop to clear.")
		"finish":
			if body is Horse or player.is_mounted():
				horse.allow_dismount = true
				ui.set_objective("Dismount at the post.")
				_hint_once("dismount", _k("Slow down and press F to dismount.", "Slow down and tap DISMOUNT."))
		"standard":
			if _final_defeated >= final_opponents.size() and not _complete and not player.is_mounted():
				_finish()


func _on_dummy_struck(_d: TrainingDummy, heavy: bool) -> void:
	_dummy_hits += 1
	if heavy:
		_hint_once("heavy_done", "A heavy blow breaks an opponent's guard - but costs more stamina.", 4.0)
	elif _dummy_hits >= 4:
		_hint_once("heavy", _k("Keep holding J after a swing to charge a HEAVY blow.", "Keep holding the SWORD button after a swing to charge a HEAVY blow."))


func _on_sparring_defeated(_s: Soldier) -> void:
	ui.toast("Training bout won")
	ui.set_objective("Cross the fort walls.")
	await get_tree().create_timer(1.0).timeout
	training_gate.open()


func _on_final_defeated(_s: Soldier) -> void:
	_final_defeated += 1
	if _final_defeated >= final_opponents.size():
		ui.toast("Course complete")
		ui.set_objective("Raise the standard at the end of the course.")


func _on_mounted_changed(m: bool, _h: Node) -> void:
	if m:
		horse.allow_dismount = current_cp >= 7 or player.global_position.x > 10150
		if not stable_gate.is_open:
			stable_gate.open()
			ui.set_objective("Ride the fort approach course.")
			_hint_once("ride", _k("Hold D to trot. Hold SHIFT (or J) to GALLOP - it drains Chetak's stamina. SPACE to leap.",
				"Hold RIGHT to trot. Hold GALLOP for speed - it drains Chetak's stamina. Tap JUMP to leap."), 8.0)
	elif player.global_position.x > 10000:
		ui.set_objective("Simulated encounter: overcome both practice opponents.")


func _stats_title() -> String:
	return "The Oath of Mewar  -  Gogunda, 1572"


func _finish() -> void:
	_complete = true
	player.lock("victory")
	for it in decor.items:
		if it.get("id", "") == "standard":
			it.raised = true
	Audio.sfx("victory", 0.0, 0.0)
	Fx.pickup(Vector2(10980, -170))
	ui.set_objective("The standard is raised.")
	await get_tree().create_timer(2.0).timeout
	_complete = false
	complete_mission()
