extends Node
## Shared helpers for automated mission playtests (input-driven bots).

var mission: MissionBase
var p: Player
var results: Array = []


func check(name: String, ok: bool, detail := "") -> void:
	results.append([name, ok, detail])
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))


func wait(sec: float) -> void:
	for i in int(sec * 60.0):
		await get_tree().physics_frame


func press(a: String) -> void:
	Input.action_press(a)


func release(a: String) -> void:
	Input.action_release(a)


func tap(a: String, hold := 0.05) -> void:
	press(a)
	await wait(hold)
	release(a)


func release_all() -> void:
	for a in ["move_left", "move_right", "move_up", "move_down", "jump", "attack", "block", "dodge", "interact", "mount", "gallop"]:
		Input.action_release(a)


func load_mission(path: String) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mission = load(path).instantiate()
	add_child(mission)
	p = mission.player


func ground_ahead(dist: float, from_y := 0.0) -> bool:
	var space := p.get_world_2d().direct_space_state
	var x := p.global_position.x + dist * p.facing
	var q := PhysicsRayQueryParameters2D.create(Vector2(x, p.global_position.y - 20.0), Vector2(x, p.global_position.y + 90.0), 1)
	return not space.intersect_ray(q).is_empty()


func nearest_imperial(max_dy := 70.0) -> Soldier:
	var best: Soldier = null
	var bd := INF
	for s in get_tree().get_nodes_in_group("imperial"):
		if s is Soldier and s.visible and s.state != Soldier.S.DEFEATED and absf(s.global_position.y - p.global_position.y) < max_dy:
			var d := absf(s.global_position.x - p.global_position.x)
			if d < bd:
				bd = d
				best = s
	return best


## Melee bot step: block on telegraph, close in, strike (heavy vs armoured).
func fight_step(s: Soldier) -> void:
	if p.health.current < 40.0:
		p.health.heal(50.0)   # bot tests mechanics, not skill
	var dx := s.global_position.x - p.global_position.x
	if s.state == Soldier.S.TELEGRAPH and absf(dx) < 200 and s.archetype != "archer":
		release("move_left"); release("move_right")
		press("block")
		return
	release("block")
	if absf(dx) > 62:
		press("move_right" if dx > 0 else "move_left")
		release("move_left" if dx > 0 else "move_right")
		if p.is_on_wall() and p.is_on_floor():
			await tap("jump", 0.2)
	else:
		release("move_left"); release("move_right")
		if p.state == Player.State.NORMAL and p.is_on_floor():
			if s.archetype == "armoured" and p.stamina > 40:
				press("attack")
				await wait(0.9)
				release("attack")
			else:
				await tap("attack", 0.03)


## Walk right toward target_x, fighting anyone on our level, jumping walls and ditches.
func advance_to(target_x: float, timeout: float, fight_range := 260.0) -> bool:
	var t := 0.0
	while t < timeout and p.global_position.x < target_x:
		if mission._respawning or p.state == Player.State.DEAD:
			release_all()
			await wait(0.3)
			t += 0.3
			continue
		var e := nearest_imperial()
		if e and absf(e.global_position.x - p.global_position.x) < fight_range and e.global_position.x > p.global_position.x - 120:
			await fight_step(e)
		else:
			release("block")
			press("move_right")
			release("move_left")
			if p.is_on_floor() and (p.is_on_wall() or not ground_ahead(55.0)):
				press("jump")
				await wait(0.3)
				release("jump")
		await wait(0.05)
		t += 0.05
	release_all()
	return p.global_position.x >= target_x


## Horse bot: gallop, leap listed obstacles/gaps, never jump inside branch zones.
func ride_to(target_x: float, timeout: float, hurdles: Array, gaps: Array, branches: Array) -> bool:
	var h := mission.horse
	press("move_right")
	var t := 0.0
	while t < timeout and h.global_position.x < target_x:
		if mission._respawning:
			await wait(0.2)
			t += 0.2
			press("move_right")
			continue
		if h.stamina > 25.0:
			press("gallop")
		elif h.stamina < 8.0:
			release("gallop")
		var hx := h.global_position.x
		var jump := false
		if h.is_on_floor():
			for jx in hurdles:
				var d: float = jx - hx
				if d > 140.0 and d < 230.0:
					jump = true
			for g in gaps:
				var d2: float = g - hx
				if d2 > 30.0 and d2 < 75.0:
					jump = true
			if h.is_on_wall():
				jump = true
			for b in branches:
				if hx > b[0] - 260.0 and hx < b[0] + b[1] + 30.0:
					jump = jump and h.is_on_wall() and false
		if jump:
			press("jump")
			await wait(0.12)
			release("jump")
		await get_tree().physics_frame
		t += 1.0 / 60.0
	release_all()
	return h.global_position.x >= target_x


func report() -> void:
	var passed := 0
	for r in results:
		if r[1]:
			passed += 1
	print("RESULT %d/%d passed" % [passed, results.size()])
	Game.reset_progress()
	get_tree().paused = false
	get_tree().quit(0 if passed == results.size() else 1)
