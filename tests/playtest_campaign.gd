extends "res://tests/bot_base.gd"
## Plays campaign levels end to end with an input-driven bot.
## Usage: godot --path . res://tests/playtest_campaign.tscn -- <level id> [<level id> ...]
## (no ids = every LevelBuilder level). The bot heals itself in fights: this
## proves each level can be finished and its systems fire, not that it is easy.

const SPEED := 3.0
var _air_mode := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var ids: Array = []
	for a in OS.get_cmdline_user_args():
		ids.append(a)
	if ids.is_empty():
		for id in Campaigns.LEVELS:
			if Campaigns.LEVELS[id].get("kind", "") != "scene":
				ids.append(id)
	Engine.max_physics_steps_per_frame = 24
	for id in ids:
		await _play(id)
	Engine.time_scale = 1.0
	report()


func _play(id: String) -> void:
	Game.reset_progress()
	Game.settings.touch_controls = "off"
	Game.progress.missions_completed = []
	for h in Campaigns.HERO_ORDER:   # open every hero; the level under test stays uncompleted
		if Campaigns.HEROES[h].levels[0] != id:
			Game.progress.missions_completed.append(Campaigns.HEROES[h].levels[0])
	Game.progress.current_mission = id
	mission = load(Game.MISSIONS[id]).instantiate()
	add_child(mission)
	p = mission.player
	var m: MissionCampaign = mission
	var hero: Dictionary = Campaigns.HEROES[m.hero_id]
	check("%s builds: hero %s, %d px" % [id, m.hero_id, m.built.end_x], p != null and m.checkpoints.size() >= 3)
	if not hero.look.get("sprite", false):
		check("%s hero look applied (%s)" % [id, hero.look.headgear], p.rig.headgear == hero.look.headgear and not (p.rig as SpriteRig).uses_sprite())
	var saw := {"arena": false, "boss": false, "spike_hit": 0, "mounted": false}
	var hits := [0]
	p.health.damaged.connect(func(_a): hits[0] += 1)
	var t := 0.0
	var last_x := p.global_position.x
	var stuck := 0.0
	var limit := 900.0
	var next_status := 60.0
	while not m._complete and t < limit and m.retries < 30 and m._elapsed < 1200.0:
		if Engine.time_scale == 1.0:
			Engine.time_scale = SPEED
		if m._respawning or p.state == Player.State.DEAD or p.state == Player.State.LOCKED or not p.input_enabled:
			release_all()
			await wait(0.2)
			t += 0.2
			continue
		if m.boss and is_instance_valid(m.boss):
			saw.boss = true
		for a in m.arena_state:
			if m.arena_state[a] == "active":
				saw.arena = true
		if p.is_mounted():
			saw.mounted = true
			await ride_to(m.built.end_x + 60.0, 120.0, m.built.ride_hurdles, m.built.ride_gaps, [])
			t += 5.0
			continue
		if m.horse and absf(p.global_position.x - m.horse.global_position.x) < 50.0 and p.get_context_prompt().begins_with("Mount"):
			release_all()
			await tap("mount")
			await wait(0.4)
			continue
		await _step()
		await get_tree().physics_frame
		t += 1.0 / 60.0
		if m._elapsed >= next_status:
			next_status += 60.0
			var alive := 0
			for s in get_tree().get_nodes_in_group("imperial"):
				if s.visible and s.state != Soldier.S.DEFEATED and absf(s.global_position.x - p.global_position.x) < 1500.0:
					alive += 1
			print("status %s t=%.0f x=%.0f y=%.0f %s retries=%d arenas=%s foes_near=%d" % [id, m._elapsed, p.global_position.x, p.global_position.y, p.state_name(), m.retries, m.arena_state, alive])
		if OS.has_environment("BOT_TRACE") and Engine.get_physics_frames() % 240 == 0:
			print("trace t=%.0f x=%.0f y=%.0f %s floor=%s wall=%s vx=%.0f" % [m._elapsed, p.global_position.x, p.global_position.y, p.state_name(), p.is_on_floor(), p.is_on_wall(), p.velocity.x])
		if absf(p.global_position.x - last_x) > 60.0:
			last_x = p.global_position.x
			stuck = 0.0
		else:
			stuck += 1.0 / 60.0
			if stuck > 45.0:
				break
	release_all()
	Engine.time_scale = 1.0
	check("%s completed" % id, m._complete, "x %.0f / %.0f, state %s, %.0fs, retries %d, hits %d" % [p.global_position.x, m.built.end_x, p.state_name(), m._elapsed, m.retries, hits[0]])
	if not m.built.arenas.is_empty():
		check("%s arena fought" % id, saw.arena)
	for a in m.built.arenas:
		if not a.boss.is_empty():
			check("%s boss fought and beaten" % id, saw.boss and m.arena_state[a.id] == "done")
	if m.built.horse_home != Vector2.INF:
		check("%s mounted finale ridden" % id, saw.mounted)
	check("%s stars recorded" % id, Game.stars_for(id) >= 1, "%d" % Game.stars_for(id))
	var nxt := Campaigns.next_level(id)
	if nxt != "":
		check("%s unlocks %s" % [id, nxt], Game.is_level_unlocked(nxt))
	print("info: %s  time %.0fs  retries %d  hits taken %d" % [id, m._elapsed, m.retries, hits[0]])
	get_tree().paused = false
	mission.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame


func _ray(x: float, y0: float, y1: float) -> Dictionary:
	var q := PhysicsRayQueryParameters2D.create(Vector2(x, y0), Vector2(x, y1), 1)
	return p.get_world_2d().direct_space_state.intersect_ray(q)


## Distance to the first landing spot beyond the edge in front (INF = none in reach).
func _landing() -> Array:
	var py := p.global_position.y
	var d := 30.0
	while d <= 240.0:
		var hit := _ray(p.global_position.x + d, py - 60.0, py + 30.0)
		if not hit.is_empty() and not _ray(p.global_position.x + d + 30.0, py - 60.0, py + 30.0).is_empty():
			return [d, hit.collider]
		d += 12.0
	return [INF, null]


func _step() -> void:
	if p.health.current < 45.0:
		p.health.heal(60.0)   # the bot tests mechanics, not skill
	var px := p.global_position.x
	var py := p.global_position.y
	# ladders: climb whenever one is in reach and we are below its top
	if p.state == Player.State.CLIMB:
		release("move_right"); release("block")
		press("move_up")
		return
	release("move_up")
	var e := nearest_imperial(90.0)
	if e and absf(e.global_position.x - px) < 300.0 and p.is_on_floor():
		# only close in if there is ground between us; otherwise cross the gap first
		var toward := signf(e.global_position.x - px)
		if absf(e.global_position.x - px) < 70.0 or not _ray(px + 24.0 * toward, py - 20.0, py + 90.0).is_empty():
			await fight_step(e)
			return
	release("block")
	if p.near_ladder() and p.is_on_floor() and p.is_on_wall():
		release("move_right")
		press("move_up")
		return
	# spear traps: wait until the cycle leaves room to cross
	for s in get_tree().get_nodes_in_group("spike"):
		var dx: float = s.global_position.x - px
		if dx > -40.0 and dx < 120.0 and absf(s.global_position.y - py) < 40.0:
			var need := (dx + 60.0) / 250.0 + 0.15
			if s.is_up() or s.time_until_up() < need:
				if dx > 55.0:
					release("move_right")
					return
	if not p.is_on_floor():
		# air control: after a gap jump, stop pushing once there is ground to drop onto
		var over := _air_mode == "gap" and p.velocity.y > -250.0 and not _ray(px + p.velocity.x * 0.1, py - 10.0, py + 240.0).is_empty()
		if over:
			release("move_right")
		else:
			press("move_right")
		return
	_air_mode = ""
	if p.is_on_wall():
		_air_mode = "wall"
		press("move_right")
		press("jump")
		await wait(0.28)
		release("jump")
		return
	if _ray(px + 22.0, py - 20.0, py + 90.0).is_empty():
		var land := _landing()
		var d: float = land[0]
		var speed := absf(p.velocity.x)
		var running := speed > 230.0
		var ok := d <= (185.0 if running else 110.0)
		var mine := 0.0
		var under := _ray(px - 10.0, py - 10.0, py + 20.0)
		var on_mover: bool = not under.is_empty() and under.collider is MovingPlatform
		if on_mover:
			mine = (under.collider as MovingPlatform).vel_x()
			if mine < -20.0:
				ok = false   # never leap off a raft that is carrying us backwards
		if ok and land[1] is MovingPlatform:
			ok = (land[1] as MovingPlatform).vel_x() - mine < 40.0 and d < 100.0
			running = false
		if OS.has_environment("BOT_TRACE") and (ok or mine != 0.0):
			var mv := ""
			for mo in get_tree().get_nodes_in_group("mover"):
				if absf(mo.global_position.x - px) < 700.0:
					mv += " mover[%.0f v%.0f]" % [mo.global_position.x, mo.vel_x()]
			print("jump x=%.0f y=%.0f d=%.0f speed=%.0f running=%s target=%s%s" % [px, py, d, speed, running, land[1], mv])
		if ok:
			_air_mode = "gap"
			press("move_right")
			press("jump")
			# running start: full jump over a real gap; standing start: a hop sized to the gap
			await wait((0.3 if d > 70.0 else 0.08) if running else (0.18 if d > 75.0 else 0.07))
			release("jump")
		elif d <= 185.0 and not (land[1] is MovingPlatform) and not on_mover and speed < 60.0:
			# too far for a standing jump: step back and take a run-up
			release("move_right")
			press("move_left")
			await wait(0.7)
			release("move_left")
			press("move_right")
			await wait(0.35)
		else:
			release("move_right")
			if p.velocity.x > 40.0 and _ray(px + 8.0, py - 20.0, py + 90.0).is_empty():
				press("move_left")
				await wait(0.05)
				release("move_left")
		return
	press("move_right")
	release("move_left")
