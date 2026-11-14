class_name MissionBase
extends Node2D
## Shared mission framework: builds a level from a layout data script,
## spawns Pratap (+ Chetak), wires HUD/touch UI, checkpoints, respawn,
## save/continue, collectibles, hints and completion.
## Subclasses set the config vars in _init() and override the hook methods.

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const HORSE_SCENE := preload("res://scenes/companions/chetak.tscn")
const SOLDIER_SCENE := preload("res://scenes/enemies/soldier.tscn")

# ---- config (set in subclass _init)
var mission_id := ""
var title := ""
var place_caption := ""
var layout: GDScript
var sky_colors: Array = [Color("86b6d8"), Color("f0cf98"), Color("f5d9a6")]
var grade := Color(1.0, 0.97, 0.92)
## [scroll(Vector2), kind, base_y, seed, z, tint]
var parallax: Array = []
var ambient := {}            ## {"color": Color, "amount": int, "speed": float}
var music := ""
var ambience := "wind"
var horse_home := Vector2.INF   ## INF = no Chetak in this mission
var start_objective := ""
var outro_story: Array = []
var next_scene := ""
var next_mission := ""
var faction := {}             ## Campaigns.FACTIONS entry: recolours every soldier (empty = Mewar pack art)
var tier := 1.0               ## difficulty: scales enemy health, damage and tempo

# ---- runtime
var C: Dictionary
var player: Player
var horse: Horse
var camera: CameraRig
var ui: MissionUI
var decor: GogundaDecor
var checkpoints: Array = []
var current_cp := 0
var leaves_total := 0
var retries := 0
var _hints_shown := {}
var _respawning := false
var _complete := false
var _elapsed := 0.0
var _grade_node: CanvasModulate
var _screen_layers: Array = []


func _ready() -> void:
	C = _layout_map()
	Soldier.faction = faction
	if next_mission == "" and next_scene == "":
		next_mission = Campaigns.next_level(mission_id)
	_build_sky()
	for l in parallax:
		_layer(l[0], l[1], l[2], l[3], l[4], l[5] if l.size() > 5 else Color.WHITE)
	_build_terrain()
	decor = GogundaDecor.new()
	decor.items = C.get("DECOR", []).duplicate(true)
	add_child(decor)
	_build_objects()
	_build_actors()
	_build_mission()
	_build_ui()
	_build_ambient()
	_apply_save()
	if music != "":
		Audio.play_music(music)
	if ambience != "":
		Audio.play_ambience(ambience)


# ================================================================ hooks

func _layout_map() -> Dictionary:
	return layout.get_script_constant_map()

func _build_mission() -> void:
	pass

func _on_trigger(_id: String, _body: Node) -> void:
	pass

func _apply_progress_state(_cp: int) -> void:
	pass

func _on_place_extra(_index: int, _cp: Checkpoint) -> void:
	pass

func _reset_encounters() -> void:
	pass

func _on_mounted_changed(_m: bool, _h: Node) -> void:
	pass

func _stats_title() -> String:
	return title


# ================================================================ build

func _build_sky() -> void:
	var sky_layer := CanvasLayer.new()
	sky_layer.layer = -20
	add_child(sky_layer)
	var tex := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, sky_colors[0])
	g.set_color(1, sky_colors[2])
	g.add_point(0.75, sky_colors[1])
	tex.gradient = g
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 8
	tex.height = 256
	var rect := TextureRect.new()
	rect.texture = tex
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky_layer.add_child(rect)
	_grade_node = CanvasModulate.new()
	_grade_node.color = grade
	add_child(_grade_node)


func _layer(scroll: Vector2, kind: String, base_y: float, seed_value: int, z: int, tint := Color.WHITE) -> void:
	if kind.begins_with("bg:"):
		_texture_layer(scroll, kind.substr(3), base_y, z, tint, float(seed_value) / 100.0)
		return
	var lim: Rect2i = C.LIMITS
	var p := Parallax2D.new()
	p.scroll_scale = scroll
	p.z_index = z
	add_child(p)
	var b := Backdrop.new()
	b.kind = kind
	b.base_y = base_y
	b.seed_value = seed_value
	b.tint = tint
	b.width = float(lim.size.x) * scroll.x + 2200.0
	b.position.x = lim.position.x * scroll.x - 800.0
	p.add_child(b)


## Asset-pack painted background, drawn in screen space (see ScreenBackdrop).
## base_y here = image bottom as a percentage of screen height; seed slot = height %.
func _texture_layer(scroll: Vector2, bg_name: String, base_y: float, z: int, tint: Color, k: float) -> void:
	var t := MewarAssets.background(bg_name)
	if t == null:
		return
	var layer := CanvasLayer.new()
	layer.layer = -19 + int(clampf(z + 56, 0, 15))
	add_child(layer)
	var sb := ScreenBackdrop.new()
	sb.texture = t
	sb.scroll = scroll
	sb.bottom_frac = base_y / 100.0
	sb.height_frac = k
	sb.tint = tint
	sb.set_meta("base_tint", tint)
	layer.add_child(sb)
	_screen_layers.append(sb)


func _build_terrain() -> void:
	for b in C.get("BLOCKS", []):
		var t := TerrainBlock.new()
		t.rect = Rect2(b[0], b[1], b[2], b[3])
		t.style = b[4]
		t.merlons = b[5] if b.size() > 5 else false
		add_child(t)
	for sl in C.get("SLOPES", []):
		var tp := TerrainPoly.new()
		tp.points = PackedVector2Array(sl)
		add_child(tp)
	var lim: Rect2i = C.LIMITS
	var kz := KillZone.new()
	kz.size = Vector2(lim.size.x + 400, 200)
	kz.position = Vector2(lim.position.x - 200, 260)
	kz.fell.connect(_on_fell)
	add_child(kz)


func _build_objects() -> void:
	for l in C.get("LADDERS", []):
		var ld := Ladder.new()
		ld.position = Vector2(l[0], l[1])
		ld.height = l[2]
		add_child(ld)
	for c in C.get("CRUMBLING", []):
		var cp := CrumblingPlatform.new()
		cp.position = Vector2(c[0], c[1])
		cp.size = Vector2(c[2], 18)
		if c.size() > 3:
			cp.style = c[3]
		if c.size() > 4:
			cp.delay = c[4]
		cp.add_to_group("crumbling")
		add_child(cp)
	for f in C.get("FALLING_STONES", []):
		var fs := FallingStones.new()
		fs.position = Vector2(f[0], f[1])
		fs.drop_points = f[2]
		fs.z_index = 3
		add_child(fs)
	for h in C.get("HURDLES", []):
		var hd := Hurdle.new()
		hd.position = Vector2(h[0], h[4] if h.size() > 4 else 0.0)
		hd.size = Vector2(h[1], h[2])
		hd.style = h[3]
		add_child(hd)
	for w in C.get("WATER", []):
		var wz := WaterZone.new()
		wz.position = Vector2(w[0], w[1])
		wz.size = Vector2(w[2], w[3])
		add_child(wz)
	for br in C.get("BRANCHES", []):
		var lb := LowBranch.new()
		lb.position = Vector2(br[0], br[1] if br.size() > 1 else 0.0)
		lb.span = br[2] if br.size() > 2 else 160.0
		lb.z_index = 4
		add_child(lb)
	var cps: Array = C.get("CHECKPOINTS", [])
	for i in cps.size():
		var d: Array = cps[i]
		var cp := Checkpoint.new()
		cp.index = i
		cp.position = Vector2(d[0], d[1])
		cp.mounted = d[2]
		cp.reached.connect(_on_checkpoint)
		add_child(cp)
		checkpoints.append(cp)
	var leaves: Array = C.get("LEAVES", [])
	leaves_total = leaves.size()
	for i in leaves.size():
		var id := "%s_leaf_%d" % [mission_id, i]
		if id in Game.progress.collectibles:
			continue
		var c := Collectible.new()
		c.id = id
		c.kind = "leaf"
		c.position = Vector2(leaves[i][0], leaves[i][1])
		c.collected.connect(_on_collected)
		add_child(c)
	for s in C.get("SUPPLIES", []):
		var c := Collectible.new()
		c.kind = "supply"
		c.position = Vector2(s[0], s[1])
		add_child(c)
	for t in C.get("TRIGGERS", []):
		var z := TriggerZone.new()
		z.id = t[0]
		z.position = Vector2(t[1], t[2])
		z.size = Vector2(t[3], 320)
		z.once = t[4] if t.size() > 4 else true
		z.triggered.connect(func(zone, body): _on_trigger(zone.id, body))
		add_child(z)


func _build_actors() -> void:
	if horse_home != Vector2.INF:
		horse = HORSE_SCENE.instantiate()
		horse.position = horse_home
		horse.facing = -1
		add_child(horse)
		horse.collision_mask = 1 | 16
		horse.stumbled.connect(func(): _hint_once("stumble", "%s balks at obstacles. Leap a little earlier - or stay low under branches." % horse.horse_name))
	player = PLAYER_SCENE.instantiate()
	player.position = checkpoints[0].position
	add_child(player)
	var hero := Campaigns.hero_of(mission_id)
	if hero != "":
		player.apply_hero(Campaigns.HEROES[hero])
	player.defeated.connect(_on_player_defeated)
	player.mounted_changed.connect(_on_mounted_changed)
	camera = CameraRig.new()
	camera.target = player
	add_child(camera)
	camera.global_position = player.global_position
	var lim: Rect2i = C.LIMITS
	camera.set_level_limits(lim.position.x, lim.position.y, lim.end.x, lim.end.y)


func spawn_soldier(pos: Vector2, archetype := "sword", team := "imperial", overrides := {}) -> Soldier:
	var s: Soldier = SOLDIER_SCENE.instantiate()
	s.position = pos
	s.archetype = archetype
	s.team = team
	s.set_meta("home", pos)
	add_child(s)
	for k in overrides:
		s.set(k, overrides[k])
	if overrides.has("max_health"):
		s.health.max_health = overrides.max_health
		s.health.current = overrides.max_health
	if team == "imperial":
		s.apply_tier(tier, not overrides.has("max_health"))
	return s


func _build_ui() -> void:
	ui = MissionUI.new()
	add_child(ui)
	ui.bind_player(player)
	ui.set_mission(title, start_objective)
	ui.set_collectibles(_leaves_collected(), leaves_total)
	ui.restart_checkpoint.connect(func(): _respawn(true))
	ui.restart_mission.connect(func():
		Game.progress.checkpoint = -1
		Game.save_game()
		Game.start_mission(mission_id))
	ui.quit_to_menu.connect(func():
		Audio.stop_all_loops()
		Game.goto(Game.SCENE_MENU))
	ui.complete_continue.connect(func():
		Audio.stop_all_loops()
		if next_mission != "" and Game.MISSIONS.has(next_mission):
			Game.progress.current_mission = next_mission
			Game.progress.checkpoint = -1
			Game.save_game()
			Game.show_story(outro_story + Game.intro_for(next_mission), Game.MISSIONS[next_mission])
		else:
			Game.show_story(outro_story, next_scene if next_scene != "" else Game.SCENE_MENU))


func _build_ambient() -> void:
	if ambient.is_empty():
		return
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	var p := CPUParticles2D.new()
	p.amount = ambient.get("amount", 40)
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(40, 400)
	p.position = Vector2(1400, 360)
	p.direction = Vector2(-1, -0.1)
	p.spread = 12.0
	p.gravity = Vector2(0, 6)
	p.initial_velocity_min = ambient.get("speed", 220.0) * 0.6
	p.initial_velocity_max = ambient.get("speed", 220.0)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 4.0
	p.color = ambient.get("color", Color(0.95, 0.8, 0.5, 0.35))
	layer.add_child(p)


func _apply_save() -> void:
	var cp: int = Game.progress.checkpoint if Game.progress.current_mission == mission_id else -1
	Game.progress.current_mission = mission_id
	if cp > 0 and cp < checkpoints.size():
		for i in cp + 1:
			checkpoints[i].activate(true)
		current_cp = cp
		_apply_progress_state(cp)
		_place_at_checkpoint(cp, true)
		ui.fade_to(0.0, 0.6)
		ui.toast("Resumed")
	else:
		checkpoints[0].activate(true)
		Game.record_checkpoint(mission_id, 0)
		if checkpoints[0].mounted:
			_place_at_checkpoint(0, true)
		_intro()


func _intro() -> void:
	player.lock("idle")
	await ui.fade_to(0.0, 1.0)
	if place_caption != "":
		ui.toast(place_caption)
	await get_tree().create_timer(1.2).timeout
	player.unlock()


# ================================================================ helpers

func _touch() -> bool:
	return Game.touch_controls_enabled()


func _k(keyboard: String, touch: String) -> String:
	return touch if _touch() else keyboard


func _hint_once(id: String, text: String, dur := 6.5) -> void:
	if _hints_shown.has(id):
		return
	_hints_shown[id] = true
	ui.show_hint(text, dur)


func _leaves_collected() -> int:
	var n := 0
	for c in Game.progress.collectibles:
		if String(c).begins_with(mission_id + "_leaf"):
			n += 1
	return n


func _process(delta: float) -> void:
	if not _complete and not get_tree().paused:
		_elapsed += delta
	# CanvasModulate does not reach CanvasLayers: apply the grade to painted backdrops
	for sb in _screen_layers:
		sb.tint = (sb.get_meta("base_tint") as Color) * _grade_node.color


# ================================================================ events

func _on_collected(c: Collectible) -> void:
	if Game.add_collectible(c.id):
		ui.set_collectibles(_leaves_collected(), leaves_total)
		ui.toast("Chronicle Leaf  %d/%d" % [_leaves_collected(), leaves_total])
		_hint_once("leaf", "Chronicle Leaves are fictional game collectibles - not historical artefacts.", 4.0)


func _on_checkpoint(cp: Checkpoint) -> void:
	if cp.index <= current_cp:
		return
	current_cp = cp.index
	for i in current_cp:
		checkpoints[i].active = true
	Game.record_checkpoint(mission_id, current_cp)
	player.health.restore_full()
	ui.toast("Checkpoint")


func _on_fell(body: Node) -> void:
	if _respawning or _complete:
		return
	if body is Player or (body is Horse and (body as Horse).rider != null):
		retries += 1
		if not player.is_mounted():
			player.fall_damage(15.0)
			if player.health.is_dead():
				return  # defeat handler takes over
		_respawn(false)


func _on_player_defeated() -> void:
	retries += 1
	_respawn(true)


func _respawn(full_restore: bool) -> void:
	if _respawning:
		return
	_respawning = true
	player.input_enabled = false
	await ui.fade_to(1.0, 0.35)
	_place_at_checkpoint(current_cp, full_restore)
	_reset_encounters()
	for c in get_tree().get_nodes_in_group("crumbling"):
		c.reset()
	await get_tree().create_timer(0.15).timeout
	player.input_enabled = true
	_respawning = false
	await ui.fade_to(0.0, 0.4)


func _place_at_checkpoint(index: int, full_restore: bool) -> void:
	var cp: Checkpoint = checkpoints[index]
	var pos := cp.global_position + Vector2(0, -2)
	if cp.mounted and horse:
		if player.is_mounted():
			horse.reset_to(pos, 1)
		else:
			player.revive_at(pos)
			horse.reset_to(pos, 1)
			horse.mount_rider(player)
		horse.allow_dismount = false
	else:
		if player.is_mounted():
			horse.release_rider()
		if full_restore or player.health.is_dead():
			player.revive_at(pos)
		else:
			player.global_position = pos
			player.velocity = Vector2.ZERO
			player.unlock()
	if full_restore:
		player.health.restore_full()
	_on_place_extra(index, cp)
	camera.global_position = player.global_position + Vector2(0, -90)


func complete_mission(extra_stats := {}) -> void:
	if _complete:
		return
	_complete = true
	Game.complete_mission(mission_id)
	if next_mission != "" and not next_mission in Game.progress.missions_unlocked:
		Game.progress.missions_unlocked.append(next_mission)
		Game.save_game()
	var stats := {
		"title": _stats_title(),
		"time": _elapsed,
		"leaves": _leaves_collected(),
		"leaves_total": leaves_total,
		"retries": retries,
	}
	stats.merge(extra_stats, true)
	# Stars: 1 for finishing, +1 for two or fewer falls/defeats, +1 for every Chronicle Leaf.
	var stars := 1 + (1 if retries <= 2 else 0) + (1 if _leaves_collected() >= leaves_total else 0)
	stats["stars"] = stars
	stats["best"] = Game.record_stars(mission_id, stars)
	stats["hero_done"] = next_mission == "" and Campaigns.hero_of(mission_id) != ""
	ui.show_complete(stats)
