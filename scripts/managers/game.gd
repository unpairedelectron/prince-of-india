extends Node
## Global game state: input map, settings, local save/load, scene flow.
## Autoloaded as "Game".

signal settings_changed
signal app_focus_lost

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1

const SCENE_MENU := "res://scenes/menus/main_menu.tscn"
const SCENE_STORY := "res://scenes/menus/story_card.tscn"
const MISSIONS := {
	"gogunda": "res://scenes/environments/gogunda/gogunda.tscn",
	"haldighati": "res://scenes/environments/haldighati/haldighati.tscn",
	"aravalli": "res://scenes/environments/aravalli/aravalli.tscn",
	"asset_test": "res://scenes/environments/test/asset_test_room.tscn",
}
const MISSION_ORDER := ["gogunda", "haldighati", "aravalli"]
const MISSION_TITLES := {
	"gogunda": "1. The Oath of Mewar  (Gogunda, 1572)",
	"haldighati": "2. The Yellow Pass  (Haldighati, 1576)",
	"aravalli": "3. Chetak - The Final Ride  (Aravalli, 1576)",
}

## Palette shared by procedural placeholder art (see documentation/ASSET_MANIFEST.md).
const C_INDIGO := Color("2b2f6b")
const C_SAFFRON := Color("e8892b")
const C_GOLD := Color("c9a14a")
const C_SANDSTONE := Color("d6a86c")
const C_SANDSTONE_DARK := Color("a8784a")
const C_BROWN := Color("4a2e1d")
const C_SILVER := Color("a7adb4")
const C_SKIN := Color("b97a4f")

var settings := {
	"button_opacity": 0.55,
	"button_scale": 1.0,
	"music_volume": 0.7,
	"sfx_volume": 0.9,
	"touch_controls": "auto",   # auto / on / off
}

var progress := {
	"missions_unlocked": ["gogunda"],
	"current_mission": "",
	"checkpoint": -1,
	"collectibles": [],
	"missions_completed": [],
}

## Run-time (not saved) values passed between scenes.
var pending_story: Array = []
var pending_next_scene := ""
var mission_start_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	load_game()


# ---------------------------------------------------------------- input map

func _setup_input() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"jump": [KEY_SPACE],
		"attack": [KEY_J],
		"block": [KEY_K],
		"dodge": [KEY_L],
		"interact": [KEY_E],
		"mount": [KEY_F],
		"gallop": [KEY_SHIFT, KEY_J],
		"pause": [KEY_ESCAPE, KEY_P],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
	# Gamepad (useful on desktop and Android with controllers).
	_add_joy("jump", JOY_BUTTON_A)
	_add_joy("attack", JOY_BUTTON_X)
	_add_joy("block", JOY_BUTTON_RIGHT_SHOULDER)
	_add_joy("dodge", JOY_BUTTON_B)
	_add_joy("interact", JOY_BUTTON_Y)
	_add_joy("pause", JOY_BUTTON_START)
	_add_joy("gallop", JOY_BUTTON_LEFT_SHOULDER)
	for pair in [["move_left", JOY_AXIS_LEFT_X, -1.0], ["move_right", JOY_AXIS_LEFT_X, 1.0],
			["move_up", JOY_AXIS_LEFT_Y, -1.0], ["move_down", JOY_AXIS_LEFT_Y, 1.0]]:
		var jm := InputEventJoypadMotion.new()
		jm.axis = pair[1]
		jm.axis_value = pair[2]
		InputMap.action_add_event(pair[0], jm)


func _add_joy(action: String, button: JoyButton) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


func touch_controls_enabled() -> bool:
	match settings.touch_controls:
		"on":
			return true
		"off":
			return false
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")


func set_setting(key: String, value) -> void:
	settings[key] = value
	Audio.apply_volumes()
	settings_changed.emit()
	save_game()


# ---------------------------------------------------------------- save / load

func save_game() -> void:
	var data := {"version": SAVE_VERSION, "settings": settings, "progress": progress}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("Could not write save: %s" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(data, "\t"))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file unreadable; using defaults.")
		return
	if parsed.has("settings") and typeof(parsed.settings) == TYPE_DICTIONARY:
		for k in parsed.settings:
			if settings.has(k):
				settings[k] = parsed.settings[k]
	if parsed.has("progress") and typeof(parsed.progress) == TYPE_DICTIONARY:
		for k in parsed.progress:
			if progress.has(k):
				progress[k] = parsed.progress[k]
	progress.checkpoint = int(progress.checkpoint)


func has_continue() -> bool:
	return progress.current_mission != "" and MISSIONS.has(progress.current_mission)


func reset_progress() -> void:
	progress = {
		"missions_unlocked": ["gogunda"],
		"current_mission": "",
		"checkpoint": -1,
		"collectibles": [],
		"missions_completed": [],
	}
	save_game()


func record_checkpoint(mission: String, index: int) -> void:
	progress.current_mission = mission
	progress.checkpoint = index
	save_game()


func add_collectible(id: String) -> bool:
	if id in progress.collectibles:
		return false
	progress.collectibles.append(id)
	save_game()
	return true


func complete_mission(mission: String) -> void:
	if not mission in progress.missions_completed:
		progress.missions_completed.append(mission)
	progress.current_mission = ""
	progress.checkpoint = -1
	save_game()


# ---------------------------------------------------------------- scene flow

func new_game() -> void:
	progress.current_mission = "gogunda"
	progress.checkpoint = -1
	progress.collectibles = progress.collectibles.filter(func(c): return not String(c).begins_with("gogunda"))
	save_game()
	show_story(intro_for("gogunda"), MISSIONS.gogunda)


func intro_for(mission: String) -> Array:
	match mission:
		"gogunda": return StoryText.MISSION_1_INTRO
		"haldighati": return StoryText.MISSION_2_INTRO
		"aravalli": return StoryText.MISSION_3_INTRO
	return []


## Chapter select: replay any unlocked mission from its start.
func play_chapter(mission: String) -> void:
	if not mission in progress.missions_unlocked or not MISSIONS.has(mission):
		return
	progress.current_mission = mission
	progress.checkpoint = -1
	save_game()
	show_story(intro_for(mission), MISSIONS[mission])


func continue_game() -> void:
	if has_continue():
		start_mission(progress.current_mission)
	else:
		new_game()


func start_mission(mission: String) -> void:
	mission_start_msec = Time.get_ticks_msec()
	goto(MISSIONS[mission])


func show_story(pages: Array, next_scene: String) -> void:
	pending_story = pages
	pending_next_scene = next_scene
	goto(SCENE_STORY)


func goto(path: String) -> void:
	get_tree().paused = false
	if not ResourceLoader.exists(path):
		push_error("Missing scene: " + path)
		path = SCENE_MENU
	get_tree().change_scene_to_file.call_deferred(path)


func _notification(what: int) -> void:
	# Pause when Android app is backgrounded / desktop window loses focus.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		app_focus_lost.emit()
		save_game()
