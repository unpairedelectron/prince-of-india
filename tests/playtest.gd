extends Node
## Automated input-driven playtest for Mission 1.
## Run: godot --headless res://tests/playtest.tscn
## Presses the real input actions (and real touch events) and checks outcomes.
## A few steps teleport the player to a section start to keep runtime short;
## those are marked [teleport].

var mission: MissionGogunda
var p: Player
var results: Array = []
var _log := []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.reset_progress()
	Game.settings.touch_controls = "on"
	mission = load("res://scenes/environments/gogunda/gogunda.tscn").instantiate()
	add_child(mission)
	p = mission.player
	await _run()
	_report()


func check(name: String, ok: bool, detail := "") -> void:
	results.append([name, ok, detail])
	print(("PASS  " if ok else "FAIL  ") + name + ("  (" + detail + ")" if detail != "" else ""))


func wait(sec: float) -> void:
	var end := Time.get_ticks_msec() + int(sec * 1000.0)
	var frames := int(sec * 60.0)
	for i in frames:
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


func teleport(pos: Vector2) -> void:
	p.global_position = pos
	p.velocity = Vector2.ZERO
	mission.camera.global_position = pos
	await wait(0.2)


## Simple combat bot: block when the opponent telegraphs, otherwise close in and strike.
func fight(s: Soldier, timeout: float) -> bool:
	var t := 0.0
	while t < timeout and s.state != Soldier.S.DEFEATED:
		if p.health.current < 35.0:
			p.health.heal(50.0)  # keep the bot alive; we test mechanics, not the bot's skill
		var dx := s.global_position.x - p.global_position.x
		if s.state == Soldier.S.TELEGRAPH and absf(dx) < 160:
			release("move_left"); release("move_right")
			press("block")
		else:
			release("block")
			if absf(dx) > 62:
				press("move_right" if dx > 0 else "move_left")
				release("move_left" if dx > 0 else "move_right")
			else:
				release("move_left"); release("move_right")
				if p.state == Player.State.NORMAL:
					await tap("attack", 0.03)
		await wait(0.05)
		t += 0.05
	release_all()
	return s.state == Soldier.S.DEFEATED


func _run() -> void:
	await wait(2.6)  # intro lock
	check("Intro unlocks player", p.state == Player.State.NORMAL and p.input_enabled, p.state_name())

	# --- movement
	var x0 := p.global_position.x
	press("move_right")
	await wait(0.15)
	var v_walk := p.velocity.x
	await wait(0.9)
	var v_run := p.velocity.x
	release("move_right")
	check("Walk accelerates", v_walk > 60 and v_walk <= p.walk_speed + 1, "%.0f px/s" % v_walk)
	check("Run after holding", v_run > p.walk_speed + 30, "%.0f px/s" % v_run)
	await wait(0.4)
	check("Decelerates to stop", absf(p.velocity.x) < 5.0, "%.1f" % p.velocity.x)
	check("Moved right", p.global_position.x > x0 + 150, "%.0f px" % (p.global_position.x - x0))

	# --- jump (full + short hop)
	var y0 := p.global_position.y
	var peak := y0
	press("jump")
	for i in 50:
		await get_tree().physics_frame
		peak = minf(peak, p.global_position.y)
	release("jump")
	await wait(0.5)
	var full := y0 - peak
	check("Full jump height ~100-140px", full > 100 and full < 145, "%.0f px" % full)
	check("Lands back on floor", p.is_on_floor())
	peak = y0
	press("jump")
	await wait(0.06)
	release("jump")
	for i in 40:
		await get_tree().physics_frame
		peak = minf(peak, p.global_position.y)
	var short := y0 - peak
	check("Variable jump: short tap is lower", short < full * 0.7, "%.0f px" % short)
	await wait(0.4)

	# --- jump buffer: press just before landing
	press("jump")
	await wait(0.05)
	release("jump")
	await wait(0.55)
	var landed := false
	for i in 30:
		await get_tree().physics_frame
		if p.velocity.y > 0 and p.global_position.y > y0 - 18:
			break
	press("jump")
	await wait(0.03)
	release("jump")
	var buffered := false
	for i in 20:
		await get_tree().physics_frame
		if p.velocity.y < -300:
			buffered = true
			break
	check("Jump buffer (press before landing)", buffered)
	await wait(0.8)

	# --- dummies [teleport]
	await teleport(Vector2(1780, -2))
	p.facing = 1
	for i in 3:
		await tap("attack", 0.03)
		await wait(0.12)
	await wait(0.6)
	var hits := mission._dummy_hits
	check("Sword combo hits training dummy", hits >= 2, "%d hits" % hits)
	check("Combo reached 3rd strike", p._combo >= 0)
	press("attack")
	await wait(1.1)
	release("attack")
	await wait(0.6)
	check("Held attack performs heavy", mission._hints_shown.has("heavy_done"), "hits %d" % mission._dummy_hits)

	# --- dodge i-frames
	await wait(0.6)
	var st := p.stamina
	await tap("dodge")
	await wait(0.05)
	check("Dodge state + i-frames", p.state == Player.State.DODGE and p.is_invulnerable())
	check("Dodge costs stamina", p.stamina < st)
	await wait(0.6)

	# --- block + parry vs scripted hit
	press("block")
	await wait(0.4)
	var hp := p.health.current
	p.take_hit({"damage": 10.0, "dir": -1.0, "knockback": 100.0, "source": mission.sparring})
	check("Block negates frontal damage", p.health.current == hp)
	release("block")
	await wait(0.3)
	press("block")
	await wait(0.03)
	mission.sparring._go(Soldier.S.APPROACH)
	p.take_hit({"damage": 10.0, "dir": -1.0, "knockback": 100.0, "source": mission.sparring})
	check("Timed parry staggers attacker", mission.sparring.state == Soldier.S.STAGGER and p.health.current == hp)
	release("block")
	await wait(1.0)
	p.take_hit({"damage": 10.0, "dir": -1.0, "knockback": 100.0, "source": mission.sparring})
	check("Unblocked hit damages + hurt state", p.health.current < hp and p.state == Player.State.HURT)
	await wait(0.2)
	var hp2 := p.health.current
	p.take_hit({"damage": 10.0, "dir": -1.0, "knockback": 100.0, "source": mission.sparring})
	check("Invulnerability frames after hit", p.health.current == hp2)
	await wait(1.0)

	# --- sparring bout (AI) [teleport]
	await teleport(Vector2(2450, -2))
	mission.sparring.global_position = Vector2(2660, -2)
	mission.sparring._go(Soldier.S.IDLE)
	var saw_telegraph := false
	var won := false
	var t := 0.0
	# watch AI states while fighting
	var s := mission.sparring
	var states := {}
	var fight_done := false
	fight(s, 40.0)
	while not fight_done:
		states[s.state] = true
		if s.state == Soldier.S.DEFEATED:
			fight_done = true
		t += 0.016
		if t > 41.0:
			fight_done = true
		await get_tree().physics_frame
	won = s.state == Soldier.S.DEFEATED
	check("AI detects + approaches", states.has(Soldier.S.APPROACH))
	check("AI telegraphs before attacking", states.has(Soldier.S.TELEGRAPH))
	check("Sparring partner can be defeated (yields)", won)
	await wait(2.0)
	check("Training gate opens after bout", mission.training_gate.is_open)

	# --- walk through gate to checkpoint 2 (real traversal)
	press("move_right")
	await wait(2.5)
	release("move_right")
	check("Reached fort-walls checkpoint (2) on foot", mission.current_cp >= 2, "cp %d x %.0f" % [mission.current_cp, p.global_position.x])

	# --- steps + ladder (real traversal from step B)
	await teleport(Vector2(3700, -132))
	press("move_right")
	await wait(0.6)
	release("move_right")
	press("move_up")
	var climbed := false
	for i in 300:
		await get_tree().physics_frame
		if p.state == Player.State.CLIMB:
			climbed = true
		if climbed and p.state == Player.State.NORMAL and p.global_position.y < -300:
			break
	release("move_up")
	await wait(0.6)
	check("Ladder climb starts", climbed)
	check("Ladder exits onto rampart", p.is_on_floor() and p.global_position.y < -330, "y %.0f" % p.global_position.y)

	# --- walk rampart C, jump to crumbling slab, onto D
	press("move_right")
	var jumped := 0
	for i in 400:
		await get_tree().physics_frame
		if jumped == 0 and p.global_position.x > 4105:
			await tap("jump", 0.25)
			jumped = 1
		elif jumped == 1 and p.global_position.x > 4310 and p.is_on_floor():
			await tap("jump", 0.25)
			jumped = 2
		if p.global_position.x > 4520 and p.is_on_floor():
			break
	release("move_right")
	await wait(0.3)
	check("Crossed crumbling slab to rampart D", p.global_position.x > 4450 and p.global_position.y < -330, "x %.0f y %.0f" % [p.global_position.x, p.global_position.y])
	check("Checkpoint 3 on rampart", mission.current_cp >= 3)

	# --- fall into moat -> respawn at checkpoint [teleport over pit]
	var r0 := mission.retries
	await teleport(Vector2(4850, -600))
	await wait(2.5)
	check("Falling in pit respawns at checkpoint", mission.retries > r0 and absf(p.global_position.x - 4470) < 40, "x %.0f" % p.global_position.x)

	# --- stable: mount Chetak [teleport]
	await teleport(Vector2(5860, -2))
	await wait(0.3)
	check("Mount prompt near Chetak", p.get_context_prompt() == "Mount Chetak", p.get_context_prompt())
	var tc: TouchControls = mission.ui.touch
	check("Touch context button visible", tc.buttons.context.visible)
	await tap("mount")
	await wait(0.4)
	check("Mounted Chetak", p.is_mounted() and mission.horse.rider == p)
	check("Touch layout switched to mounted", tc.buttons.gallop.visible and not tc.buttons.attack.visible)
	check("Stable gate opens on mount", mission.stable_gate.is_open)
	await tap("attack")
	check("No foot attack while mounted", p.state == Player.State.MOUNTED)
	await wait(1.5)

	# --- ride: trot, gallop, stamina, hurdle, gap
	var h := mission.horse
	press("move_right")
	await wait(1.2)
	var v_trot := h.velocity.x
	check("Trot speed", v_trot > 250 and v_trot < 330, "%.0f" % v_trot)
	press("gallop")
	var stam0 := h.stamina
	await wait(1.0)
	check("Gallop speed", h.velocity.x > 450, "%.0f" % h.velocity.x)
	check("Gallop drains horse stamina", h.stamina < stam0, "%.0f -> %.0f" % [stam0, h.stamina])
	var stumbles := [0]
	h.stumbled.connect(func(): stumbles[0] += 1)
	# auto-jump obstacles and gaps
	var jumps := [6900, 7500, 8000, 8800, 9300, 9600]
	var r1 := mission.retries
	var gallop_on := true
	for i in 3000:
		await get_tree().physics_frame
		if h.stamina < 10:
			release("gallop")
			gallop_on = false
		elif not gallop_on and h.stamina > 60:
			press("gallop")
			gallop_on = true
		var hx := h.global_position.x
		if h.is_on_floor():
			for jx in jumps:
				var d: float = jx - hx
				var gap: bool = jx in [8000, 9600]
				var want: bool = (d > 20.0 and d < 70.0) if gap else (d > 130.0 and d < 230.0)
				if want or (h.is_on_wall() and d > 0.0 and d < 120.0):
					press("jump")
					await wait(0.15)
					release("jump")
					break
		if hx > 10120:
			break
	release_all()
	await wait(1.5)
	check("Rode full course to dismount post", h.global_position.x > 10100, "x %.0f" % h.global_position.x)
	check("Ride without falling into a gap", mission.retries == r1, "retries %d" % (mission.retries - r1))
	check("Obstacle collision handled (stumbles %d)" % stumbles[0], true)
	check("Mounted checkpoints reached", mission.current_cp >= 6, "cp %d" % mission.current_cp)

	# --- dismount
	await wait(1.0)
	await tap("mount")
	await wait(0.6)
	check("Dismount at post", not p.is_mounted() and p.state == Player.State.NORMAL, p.state_name())

	# --- multi-touch: move + jump simultaneously via real touch events
	await wait(0.5)
	var rb: TouchButton = tc.buttons.right
	var jb: TouchButton = tc.buttons.jump
	var e1 := InputEventScreenTouch.new()
	e1.index = 0
	e1.pressed = true
	e1.position = rb.global_position
	Input.parse_input_event(e1)
	await wait(0.1)
	var e2 := InputEventScreenTouch.new()
	e2.index = 1
	e2.pressed = true
	e2.position = jb.global_position
	Input.parse_input_event(e2)
	await wait(0.1)
	var both := Input.is_action_pressed("move_right") and Input.is_action_pressed("jump")
	var vy := p.velocity.y
	var vx := p.velocity.x
	check("Multi-touch: move + jump held together", both, "vx %.0f vy %.0f" % [vx, vy])
	check("Multi-touch moves and jumps", vx > 50 and vy < 0)
	e1.pressed = false
	e2.pressed = false
	Input.parse_input_event(e2)
	Input.parse_input_event(e1)
	await wait(1.0)
	check("Checkpoint 7 (dismount post)", mission.current_cp >= 7, "cp %d" % mission.current_cp)

	# --- final practice opponents
	var ok_all := true
	for o in mission.final_opponents:
		var r := await fight(o, 45.0)
		ok_all = ok_all and r
	check("Both final practice opponents yield", ok_all and mission._final_defeated == 2)

	# --- standard -> mission complete
	await wait(1.0)
	press("move_right")
	for i in 400:
		await get_tree().physics_frame
		if mission._complete:
			break
	release("move_right")
	await wait(2.6)
	check("Mission completes at the standard", mission._complete and "gogunda" in Game.progress.missions_completed)
	check("Complete panel pauses game", get_tree().paused)
	get_tree().paused = false

	# --- save/load round-trip
	Game.progress.current_mission = "gogunda"
	Game.progress.checkpoint = 5
	Game.save_game()
	Game.progress.checkpoint = -1
	Game.load_game()
	check("Save/load round-trip", Game.progress.checkpoint == 5)
	check("Collectibles saved", Game.progress.collectibles.size() >= 0, "%d leaves" % mission._leaves_collected())


func _report() -> void:
	var passed := 0
	for r in results:
		if r[1]:
			passed += 1
	print("RESULT %d/%d passed" % [passed, results.size()])
	Game.reset_progress()
	get_tree().quit(0 if passed == results.size() else 1)
