class_name MissionCampaign
extends MissionBase
## Generic, data-driven level. Reads the level named by
## Game.progress.current_mission from data/campaigns.gd, builds it with
## LevelBuilder and runs its encounters: field enemies, allies, wave arenas,
## boss fights, spear traps, drifting platforms, volleys and a mounted finale.

var level: Dictionary
var theme: Dictionary
var built: LevelBuilder
var hero_id := ""
var arena_state := {}       ## arena id -> "idle" | "active" | "done"
var _arena_gates := {}      ## arena id -> [Gate in, Gate out]
var _arena_units := {}      ## arena id -> Array of spawned soldiers
var _arena_wave := {}
var field_enemies: Array = []
var boss: Soldier
var _ending := false


func _init() -> void:
	mission_id = Game.progress.current_mission
	if not Campaigns.LEVELS.has(mission_id) or Campaigns.LEVELS[mission_id].get("kind", "") == "scene":
		mission_id = "shivaji_1"
	level = Campaigns.LEVELS[mission_id]
	hero_id = Campaigns.hero_of(mission_id)
	theme = Campaigns.THEMES[level.theme]
	tier = float(level.get("tier", 1)) + 0.25 * Campaigns.HERO_ORDER.find(hero_id)
	built = LevelBuilder.new().build(level.segments, theme, int(level.get("tier", 1)), mission_id.hash())
	title = "Level %d - %s" % [Campaigns.level_index(mission_id) + 1, level.title]
	place_caption = level.get("caption", level.place.to_upper())
	sky_colors = theme.sky
	grade = theme.grade
	parallax = theme.parallax
	ambient = theme.get("ambient", {})
	music = theme.get("music", "battle_theme")
	ambience = theme.get("ambience", "wind")
	horse_home = built.horse_home
	start_objective = level.get("objective", "")
	outro_story = level.get("outro", [])
	faction = Campaigns.faction_of(mission_id)


func _layout_map() -> Dictionary:
	return built.C


func _stats_title() -> String:
	return "%s  -  %s" % [level.title, level.place]


# ================================================================ build

func _build_mission() -> void:
	for f in built.foes:
		field_enemies.append(spawn_soldier(f.pos, f.type))
	for a in built.allies:
		spawn_soldier(a.pos, a.type, "mewar", {"max_health": 90.0 + 10.0 * tier})
	for s in built.spikes:
		var t := SpikeTrap.new()
		t.position = s.pos
		t.phase = s.phase
		t.period = maxf(1.7, 2.7 - 0.2 * tier)
		t.damage = 10.0 + 2.0 * tier
		add_child(t)
	for m in built.movers:
		var mp := MovingPlatform.new()
		mp.position = m.pos
		mp.travel = m.travel
		mp.phase = m.phase
		mp.style = m.style
		mp.period = maxf(2.6, 4.2 - 0.3 * tier)
		add_child(mp)
	for v in built.volleys:
		var fs := FallingStones.new()
		fs.style = v.style
		fs.follow = true
		fs.x_range = Vector2(v.x0, v.x1)
		fs.position = Vector2(0, v.y)
		fs.period = maxf(1.0, 2.1 - 0.2 * tier)
		fs.warn_time = maxf(0.75, 1.1 - 0.06 * tier)
		fs.radius = 52.0 if v.style == "arrows" else 62.0
		fs.damage = 8.0 + 2.0 * tier
		fs.z_index = 3
		add_child(fs)
	for a in built.arenas:
		var gin := _gate(a.x0, a.y)
		gin.set_open_instant()
		var gout := _gate(a.x1, a.y)
		_arena_gates[a.id] = [gin, gout]
		arena_state[a.id] = "idle"
		_arena_units[a.id] = []
		_arena_wave[a.id] = 0
	if theme.get("water", false) or not built.pits.is_empty():
		var w := _Water.new()
		w.pits = built.pits
		w.full = theme.get("terrain", "") == "deck"
		w.is_water = theme.get("water", false)
		w.span = Vector2(-600.0, built.end_x + 900.0)
		w.z_index = 1
		add_child(w)
	if theme.get("rain", false):
		_build_rain()
	if horse:
		horse.horse_name = Campaigns.HEROES[hero_id].get("horse", "the horse")


func _gate(x: float, y: float) -> Gate:
	var g := Gate.new()
	g.position = Vector2(x, y)
	g.size = Vector2(36, 300)
	add_child(g)
	return g


func _build_rain() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 6
	add_child(layer)
	var p := CPUParticles2D.new()
	p.amount = 260
	p.lifetime = 0.9
	p.preprocess = 1.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(900, 10)
	p.position = Vector2(760, -30)
	p.direction = Vector2(-0.25, 1)
	p.spread = 3.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 900.0
	p.initial_velocity_max = 1150.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.6
	p.color = Color(0.75, 0.85, 1.0, 0.4)
	layer.add_child(p)


# ================================================================ events

func _on_trigger(id: String, body: Node) -> void:
	if built.hints.has(id):
		ui.show_hint(_fit_controls(built.hints[id]), 7.0)
	elif built.objectives.has(id):
		ui.set_objective(built.objectives[id])
	elif arena_state.has(id):
		if arena_state[id] == "idle" and body is Player:
			_start_arena.call_deferred(id)
	elif id == "horse":
		_hint_once("horse", _k("%s is waiting. Press F to mount, hold SHIFT to gallop, SPACE to leap.", "%s is waiting. Tap MOUNT, hold GALLOP for speed, JUMP to leap.") % horse.horse_name, 8.0)
	elif id == "end":
		_finish()


## Hint text is written for keyboards; swap the key names on touch screens.
func _fit_controls(text: String) -> String:
	if not _touch():
		return text
	for pair in [["A/D", "LEFT/RIGHT"], ["SPACE", "JUMP"], ["HOLD J", "HOLD ATTACK"], ["J, J, J", "ATTACK, ATTACK, ATTACK"], ["Tap J", "Tap ATTACK"], [" J,", " ATTACK,"], [" K,", " BLOCK,"], [" K ", " BLOCK "], [" L.", " DODGE."], [" L)", " DODGE)"], ["with L", "with DODGE"]]:
		text = text.replace(pair[0], pair[1])
	return text


func _arena(id: String) -> Dictionary:
	for a in built.arenas:
		if a.id == id:
			return a
	return {}


func _start_arena(id: String) -> void:
	if arena_state[id] != "idle":
		return
	arena_state[id] = "active"
	_arena_wave[id] = 0
	(_arena_gates[id][0] as Gate).close()
	var a := _arena(id)
	if not a.boss.is_empty():
		_start_boss(a)
	else:
		_next_wave(id)


func _next_wave(id: String) -> void:
	if arena_state[id] != "active":
		return
	var a := _arena(id)
	var n: int = _arena_wave[id]
	ui.toast("Wave %d / %d" % [n + 1, a.waves.size()])
	for e in a.waves[n]:
		_arena_spawn(a, e[0], e[1])


func _arena_spawn(a: Dictionary, type: String, frac: float, extra := {}) -> Soldier:
	var o := {"detect_range": 1400.0}
	o.merge(extra, true)
	var s := spawn_soldier(Vector2(lerpf(a.x0, a.x1, frac), a.y), type, "imperial", o)
	s.defeated.connect(_on_arena_enemy_defeated.bind(a.id))
	_arena_units[a.id].append(s)
	return s


func _start_boss(a: Dictionary) -> void:
	var cfg: Dictionary = a.boss
	boss = _arena_spawn(a, "champion", 0.72, {"max_health": float(cfg.get("hp", 300.0))})
	boss.display_name = cfg.get("name", "Champion")
	for e in cfg.get("adds", []):
		_arena_spawn(a, e[0], e[1])
	ui.show_boss(boss.display_name, boss.health)
	Audio.play_music("boss_theme")
	CameraRig.shake_global(5.0)


func _on_arena_enemy_defeated(_s: Soldier, id: String) -> void:
	if arena_state[id] != "active":
		return
	for e in _arena_units[id]:
		if is_instance_valid(e) and e.state != Soldier.S.DEFEATED:
			return
	var a := _arena(id)
	_arena_wave[id] += 1
	if a.boss.is_empty() and _arena_wave[id] < a.waves.size():
		await get_tree().create_timer(1.4).timeout
		_next_wave(id)
		return
	_finish_arena(id, false)


func _finish_arena(id: String, instant: bool) -> void:
	arena_state[id] = "done"
	var gates: Array = _arena_gates[id]
	if instant:
		(gates[0] as Gate).set_open_instant()
		(gates[1] as Gate).set_open_instant()
		return
	var a := _arena(id)
	if not a.boss.is_empty():
		ui.hide_boss()
		ui.toast("%s is beaten" % a.boss.get("name", "The champion"))
		Audio.sfx("victory", 0.0, -4.0)
		Audio.play_music(music)
		Fx.hitstop(0.25)
	else:
		ui.toast("The way is open")
	(gates[0] as Gate).open()
	(gates[1] as Gate).open()


func _apply_progress_state(cp: int) -> void:
	var x: float = checkpoints[cp].position.x
	for a in built.arenas:
		if a.x1 < x:
			_finish_arena(a.id, true)


func _on_place_extra(_index: int, cp: Checkpoint) -> void:
	if horse and not cp.mounted:
		horse.reset_to(built.horse_home, -1)
		horse.allow_dismount = true


func _reset_encounters() -> void:
	for id in arena_state:
		if arena_state[id] == "active":
			for e in _arena_units[id]:
				if is_instance_valid(e):
					e.queue_free()
			_arena_units[id] = []
			arena_state[id] = "idle"
			(_arena_gates[id][0] as Gate).open()
			if not _arena(id).boss.is_empty():
				ui.hide_boss()
				Audio.play_music(music)
	for s in field_enemies:
		if is_instance_valid(s) and s.visible and s.state != Soldier.S.DEFEATED:
			if absf(s.global_position.x - player.global_position.x) < 900.0:
				s.reset_to_home()


func _on_mounted_changed(m: bool, _h: Node) -> void:
	if m and horse:
		horse.allow_dismount = false
		ui.set_objective("Ride! Leap the wreckage and gallop across the gaps.")


func _finish() -> void:
	if _ending or _complete:
		return
	for id in arena_state:
		if arena_state[id] != "done":
			return
	_ending = true
	Audio.sfx("victory", 0.0, -2.0)
	if player.is_mounted():
		player.input_enabled = false
		horse.input_enabled = false
		horse.auto_dir = 1
		horse.auto_speed = 420.0
	else:
		player.lock("victory")
	await get_tree().create_timer(1.8).timeout
	complete_mission()


## Water in the pits (river levels) or a soft shadow in dry chasms. On the
## Brahmaputra the whole level floats: one strip of river under every deck.
class _Water extends Node2D:
	var pits: Array = []
	var full := false
	var is_water := false
	var span := Vector2.ZERO
	var _t := 0.0

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _strip(x0: float, x1: float, y: float) -> void:
		var top := y + 44.0
		draw_rect(Rect2(x0, top, x1 - x0, 700.0), Color(0.16, 0.36, 0.44, 0.9))
		var x := x0
		while x < x1:
			var w := minf(46.0, x1 - x)
			var yy := top + sin(_t * 2.0 + x * 0.03) * 3.0
			draw_line(Vector2(x, yy), Vector2(x + w * 0.6, yy), Color(0.8, 0.95, 1.0, 0.45), 2.0)
			x += 46.0

	func _draw() -> void:
		if full:
			_strip(span.x, span.y, 0.0)
			return
		for p in pits:
			if is_water:
				_strip(p[0], p[1], p[2])
			else:
				for i in 5:
					draw_rect(Rect2(p[0], p[2] + 30.0 + i * 50.0, p[1] - p[0], 600.0), Color(0, 0, 0, 0.12))
