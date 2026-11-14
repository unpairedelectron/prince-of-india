extends "res://tests/bot_base.gd"
## Mission 3 (Chetak: The Final Ride) automated playtest.


func _ready() -> void:
	Game.reset_progress()
	Game.settings.touch_controls = "on"
	load_mission("res://scenes/environments/aravalli/aravalli.tscn")
	await wait(2.6)
	var m: MissionAravalli = mission
	check("Starts mounted on Chetak", p.is_mounted() and m.horse.rider == p)
	check("Touch layout is mounted", m.ui.touch.buttons.gallop.visible)
	var L = m.L

	# stream slowdown (direct check)
	var h := m.horse
	var stumbles := [0]
	h.stumbled.connect(func(): stumbles[0] += 1)
	var hurdles := []
	for x in L.HURDLES:
		hurdles.append(x[0])
	var gaps := [1200, 2910, 8100, 9000]
	var branches := []
	for b in L.BRANCHES:
		branches.append([b[0], b[2]])
	var slowed := [false]
	var checker := func():
		if h.terrain_speed_mult < 1.0:
			slowed[0] = true
	get_tree().physics_frame.connect(checker)
	# scripted: leaping under a low branch makes Chetak balk
	h.reset_to(Vector2(3790, -2), 1)
	await wait(0.2)
	press("move_right")
	await wait(0.3)
	press("jump")
	await wait(0.4)
	release_all()
	await wait(0.6)
	check("Jumping into a low branch causes a stumble", stumbles[0] >= 1, "%d" % stumbles[0])
	# scripted: a falling stone striking Chetak causes a stumble (no injury shown)
	var s0: int = stumbles[0]
	h.reset_to(Vector2(5850, -2), 1)
	await wait(0.3)
	var fs: FallingStones = null
	for c in m.get_children():
		if c is FallingStones:
			fs = c
	fs._impact(h.global_position.x - fs.global_position.x)
	await wait(0.2)
	check("Falling stone striking Chetak causes a stumble", stumbles[0] > s0)
	m.retries = 0
	h.reset_to(Vector2(60, -2), 1)
	stumbles[0] = 0
	await wait(0.6)
	var ok := await ride_to(9460.0, 120.0, hurdles, gaps, branches)
	check("Rode the full Aravalli course", ok, "x %.0f" % h.global_position.x)
	check("Stream slowed Chetak", slowed[0])
	check("Bridge / descent crumbling platforms exist", get_tree().get_nodes_in_group("crumbling").size() == 7)
	print("info: falls %d, stumbles %d, time %.0fs" % [m.retries, stumbles[0], m._elapsed])
	check("Course fair for a simple bot (<= 3 falls)", m.retries <= 3, "%d falls" % m.retries)

	# final sequence
	var t := 0.0
	while not m._tribute_ready and t < 20.0 and m._tribute == null:
		await wait(0.2)
		t += 0.2
	check("Final sequence: rider dismounts", not p.is_mounted())
	check("Chetak rests (non-graphic pose)", h.resting and h.rig.anim == "rest")
	check("Control returns to player", p.input_enabled and p.state == Player.State.NORMAL)
	# walk to Chetak and stay a while
	var dx := h.global_position.x - p.global_position.x
	press("move_right" if dx > 0 else "move_left")
	for i in 240:
		await get_tree().physics_frame
		if p.get_context_prompt() == "Stay a while":
			break
	release_all()
	check("Prompt 'Stay a while' appears", p.get_context_prompt() == "Stay a while", p.get_context_prompt())
	await tap("interact")
	for i in 900:
		await get_tree().physics_frame
		if m._complete:
			break
	await wait(0.5)
	check("Mission 3 completes after tribute", m._complete and "aravalli" in Game.progress.missions_completed)
	check("Memorial shown after farewell", m.decor.items.any(func(it): return it.type == "memorial"))
	check("Outro labelled as traditional account", StoryText.MISSION_3_OUTRO[0].tag == StoryText.TRADITION)
	report()
