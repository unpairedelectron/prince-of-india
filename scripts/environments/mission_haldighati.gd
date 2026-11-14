class_name MissionHaldighati
extends MissionBase
## Mission 2 - The Yellow Pass (Haldighati, 18 June 1576).
## Objective is SURVIVAL and WITHDRAWAL, not victory (see HISTORICAL_REFERENCES.md).
## All soldiers are fictional composites; no named historical figure appears.

const L = preload("res://data/missions/haldighati_layout.gd")

## Chokepoint waves: [archetype, x]
const WAVES := [
	[["sword", 6350], ["spear", 6470]],
	[["archer", 6500], ["armoured", 6380]],
	[["sword", 6300], ["sword", 6420], ["spear", 6520]],
]

var arena_state := "idle"   # idle | active | done
var wave := 0
var _wave_enemies: Array = []
var _arena_allies: Array = []
var allies_standing := 0
var gate_in: Gate
var gate_out: Gate
var field_enemies: Array = []
var volley_rear: FallingStones
var volley_escape: FallingStones
var _escaping := false


func _init() -> void:
	mission_id = "haldighati"
	title = "Mission 2 - The Yellow Pass"
	place_caption = "HALDIGHATI  -  18 JUNE 1576"
	layout = L
	sky_colors = [Color("c9b58e"), Color("e9c77a"), Color("f2d9a0")]
	grade = Color(1.04, 0.98, 0.86)
	parallax = [
		[Vector2(0.05, 0.08), "bg:haldighati_parallax", 82.0, 85, -55],
		[Vector2(0.18, 0.15), "bg:rock_silhouette", 86.0, 28, -50, Color(0.85, 0.6, 0.35, 0.8)],
		[Vector2(0.32, 0.55), "troops", 70.0, 13, -44],
		[Vector2(0.45, 0.7), "rocks", 70.0, 17, -40],
		[Vector2(1.25, 1.0), "foreground", 210.0, 19, 30],
	]
	ambient = {"color": Color(0.95, 0.8, 0.45, 0.35), "amount": 60, "speed": 260.0}
	music = "battle_theme"
	horse_home = L.HORSE_HOME
	start_objective = "Advance through the pass."
	outro_story = StoryText.MISSION_2_OUTRO
	next_mission = "aravalli"


func _build_mission() -> void:
	# Section 1-2: field encounters (one of each archetype is introduced)
	for e in [["sword", 1100, 0], ["sword", 1900, 0], ["spear", 2950, 0], ["archer", 3530, -150],
			["armoured", 4300, 0], ["sword", 4150, 0], ["sword", 4800, 0], ["sword", 7950, 0], ["spear", 8950, 0]]:
		var s := spawn_soldier(Vector2(e[1], e[2]), e[0])
		field_enemies.append(s)
	# Allies in the battlefield: two Mewar swordsmen and a Bhil archer (composites)
	spawn_soldier(Vector2(3880, 0), "sword", "mewar", {"max_health": 90.0})
	spawn_soldier(Vector2(3980, 0), "sword", "mewar", {"max_health": 90.0})
	spawn_soldier(Vector2(4600, -150), "archer", "mewar", {"max_health": 60.0})
	# Chokepoint barricades
	gate_in = Gate.new()
	gate_in.position = Vector2(5420, 0)
	gate_in.size = Vector2(36, 280)
	add_child(gate_in)
	gate_in.set_open_instant()
	gate_out = Gate.new()
	gate_out.position = Vector2(6580, 0)
	gate_out.size = Vector2(36, 280)
	add_child(gate_out)
	# Arrow volleys (telegraphed by red arcs + ground shadows)
	volley_rear = _volley(Vector2(6750, 9300), 1.7, 0.95, 50.0)
	volley_escape = _volley(Vector2(9750, 12700), 1.25, 0.8, 60.0)


func _volley(xr: Vector2, period: float, warn: float, radius: float) -> FallingStones:
	var v := FallingStones.new()
	v.style = "arrows"
	v.follow = true
	v.x_range = xr
	v.period = period
	v.warn_time = warn
	v.radius = radius
	v.damage = 10.0
	v.z_index = 3
	add_child(v)
	return v


func _apply_progress_state(cp: int) -> void:
	if cp >= 3:
		_finish_arena(true)
	if cp >= 5:
		ui.set_objective("Escape the encirclement on Chetak.")
	elif cp >= 3:
		ui.set_objective("Find the way out of the pass. Fight only when you must.")
	elif cp >= 1:
		ui.set_objective("Survive the battlefield. Stand with your allies.")


func _on_place_extra(index: int, cp: Checkpoint) -> void:
	if not cp.mounted and index <= 4:
		horse.reset_to(L.HORSE_HOME, -1)


func _reset_encounters() -> void:
	if arena_state == "active":
		for e in _wave_enemies + _arena_allies:
			if is_instance_valid(e):
				e.queue_free()
		_wave_enemies.clear()
		_arena_allies.clear()
		arena_state = "idle"
		wave = 0
		gate_in.open()
	for s in field_enemies:
		if is_instance_valid(s) and s.visible and s.state != Soldier.S.DEFEATED:
			if absf(s.global_position.x - player.global_position.x) < 900.0:
				s.reset_to_home()


func _on_trigger(id: String, body: Node) -> void:
	match id:
		"pass":
			_hint_once("pass", "Haldighati: the yellow pass. Imperial soldiers block the way - strike, block and dodge as you trained.")
		"battlefield":
			ui.set_objective("Survive the battlefield. Stand with your allies.")
		"spear": _hint_once("spear", "Spearmen strike from further away. Close the distance after their thrust.")
		"archer": _hint_once("archer", "Archers keep their distance. Raise your shield to stop arrows, or use rocks as cover.")
		"allies": _hint_once("allies", "Allied warriors (green marker) fight beside you. Keep them standing.")
		"armoured": _hint_once("armoured", "Armoured guards block most light blows. Use a HEAVY blow to break their guard.")
		"choke":
			if arena_state == "idle" and body is Player:
				_start_arena.call_deferred()
		"rear":
			ui.set_objective("Find the way out of the pass. Fight only when you must.")
			_hint_once("rear", "Arrow volleys! Red arcs and shadows mark where they will land - keep moving.")
		"chetak":
			ui.set_objective("Reach Chetak.")
			_hint_once("chetak", _k("Mount Chetak with F.", "Tap MOUNT to ride Chetak."))
		"escape_end":
			if player.is_mounted() and not _escaping:
				_escape_cinematic()


# ------------------------------------------------------------ chokepoint

func _start_arena() -> void:
	arena_state = "active"
	wave = 0
	gate_in.close()
	ui.set_objective("Hold the narrow pass with your allies.")
	_hint_once("choke", "The pass narrows. Hold here with your allies while the others withdraw. Rocks give cover from arrows.", 7.0)
	_arena_allies.clear()
	for x in [5560, 5640]:
		var a := spawn_soldier(Vector2(x, 0), "sword", "mewar", {"max_health": 80.0})
		_arena_allies.append(a)
	_next_wave()


func _next_wave() -> void:
	if arena_state != "active":
		return
	ui.toast("Wave %d / %d" % [wave + 1, WAVES.size()])
	_wave_enemies.clear()
	for e in WAVES[wave]:
		var s := spawn_soldier(Vector2(e[1], 0), e[0], "imperial", {"detect_range": 1000.0})
		s.defeated.connect(_on_wave_enemy_defeated)
		_wave_enemies.append(s)


func _on_wave_enemy_defeated(_s: Soldier) -> void:
	for e in _wave_enemies:
		if is_instance_valid(e) and e.state != Soldier.S.DEFEATED:
			return
	wave += 1
	if wave >= WAVES.size():
		_finish_arena(false)
	else:
		await get_tree().create_timer(1.6).timeout
		_next_wave()


func _finish_arena(instant: bool) -> void:
	arena_state = "done"
	allies_standing = 0
	for a in _arena_allies:
		if is_instance_valid(a) and a.state != Soldier.S.DEFEATED:
			allies_standing += 1
	if instant:
		gate_out.set_open_instant()
		return
	ui.toast("The pass is held")
	ui.set_objective("Find the way out of the pass. Fight only when you must.")
	gate_out.open()
	gate_in.open()


# ------------------------------------------------------------ escape

func _on_mounted_changed(m: bool, _h: Node) -> void:
	if m:
		horse.allow_dismount = false
		ui.set_objective("Escape the encirclement on Chetak.")
		_hint_once("escape", "Ride for the hills! Leap the wreckage; gallop through the volleys.", 6.0)


func _escape_cinematic() -> void:
	_escaping = true
	volley_escape.active = false
	volley_rear.active = false
	player.input_enabled = false
	horse.input_enabled = false
	horse.auto_dir = 1
	horse.auto_speed = 480.0
	ui.set_objective("The battlefield recedes behind you.")
	if camera:
		camera.set_mounted(true)
	await get_tree().create_timer(2.2).timeout
	complete_mission({"title": "The Yellow Pass  -  Haldighati, 1576"})


func _stats_title() -> String:
	return "The Yellow Pass  -  Haldighati, 1576"
