extends "res://tests/bot_base.gd"
## Mission 2 (Haldighati) automated playtest.

var arrows_fired := 0
var ally_damage := 0.0
var volley_hits := 0


func _ready() -> void:
	Game.reset_progress()
	Game.settings.touch_controls = "on"
	load_mission("res://scenes/environments/haldighati/haldighati.tscn")
	mission.child_entered_tree.connect(func(n):
		if n.get_script() == preload("res://scripts/enemies/arrow.gd"):
			arrows_fired += 1)
	await wait(2.6)
	var m: MissionHaldighati = mission
	var kinds := {}
	for s in get_tree().get_nodes_in_group("imperial"):
		kinds[s.archetype] = true
		s.health.damaged.connect(func(_a):
			if absf(s.global_position.x - p.global_position.x) > 250.0:
				ally_damage += _a)
	check("Archetypes present: sword, spear, archer, armoured", kinds.has("sword") and kinds.has("spear") and kinds.has("archer") and kinds.has("armoured"), str(kinds.keys()))
	check("Allies present (mewar team)", get_tree().get_nodes_in_group("mewar").size() >= 3)
	check("Player starts unmounted, intro done", p.state == Player.State.NORMAL)

	# arrow vs shield (scripted)
	press("block")
	await wait(0.4)
	var hp := p.health.current
	var a: Area2D = preload("res://scripts/enemies/arrow.gd").new()
	a.team = "imperial"
	a.velocity = Vector2(-600, 0)
	a.global_position = p.global_position + Vector2(220, -60)
	mission.add_child(a)
	await wait(0.6)
	check("Shield blocks a frontal arrow", p.health.current == hp, "%.0f -> %.0f" % [hp, p.health.current])
	release("block")
	await wait(0.2)

	# sections 1-2: fight through to the chokepoint checkpoint
	var ok := await advance_to(5160.0, 150.0)
	check("Fought through pass + battlefield", ok, "x %.0f" % p.global_position.x)
	check("Archers fired arrows", arrows_fired > 0, "%d" % arrows_fired)
	check("Allies damaged imperial soldiers", ally_damage > 0.0, "%.0f dmg" % ally_damage)
	check("Checkpoint before chokepoint", m.current_cp >= 2, "cp %d" % m.current_cp)

	# section 3: chokepoint waves
	await advance_to(5520.0, 20.0)
	check("Chokepoint starts: barricade closes", m.arena_state == "active" and not m.gate_in.is_open)
	var t := 0.0
	while m.arena_state == "active" and t < 160.0:
		var e := nearest_imperial(90.0)
		if e:
			await fight_step(e)
		else:
			press("move_right"); release("move_left")
			if p.global_position.x > 6450:
				release("move_right")
		await wait(0.05)
		t += 0.05
	release_all()
	check("All 3 waves cleared", m.arena_state == "done" and m.wave == 3, "state %s wave %d" % [m.arena_state, m.wave])
	await wait(1.6)
	check("Exit barricade opens", m.gate_out.is_open)

	# section 4: rear guard with volleys, carts, ditches
	var hp_before := p.health.current
	p.health.damaged.connect(func(_x): volley_hits += 1)
	ok = await advance_to(9300.0, 120.0, 140.0)
	check("Rear guard traversed (carts, ditches, volleys)", ok, "x %.0f retries %d" % [p.global_position.x, m.retries])
	check("Arrow volleys active in rear guard", m.volley_rear.active)
	check("Rear-guard checkpoint reached", m.current_cp >= 4, "cp %d" % m.current_cp)

	# section 5: Chetak escape
	await advance_to(9440.0, 10.0, 0.0)
	await wait(0.3)
	check("Mount prompt at Chetak", p.get_context_prompt() == "Mount Chetak", p.get_context_prompt())
	await tap("mount")
	await wait(0.5)
	check("Mounted for the escape", p.is_mounted())
	check("Dismount locked during escape", not m.horse.can_dismount())
	var r0 := m.retries
	ok = await ride_to(12820.0, 60.0, [10150, 11500, 12050, 12600], [10700], [])
	check("Escape ride reaches the hills", ok, "x %.0f, falls %d" % [m.horse.global_position.x, m.retries - r0])
	for i in 300:
		await get_tree().physics_frame
		if m._complete:
			break
	await wait(2.6)
	check("Mission 2 completes (survival, not victory)", m._complete and "haldighati" in Game.progress.missions_completed)
	check("Mission 3 unlocked", "aravalli" in Game.progress.missions_unlocked)
	check("Outro text: imperial army held the field", "held the field" in StoryText.MISSION_2_OUTRO[0].body)
	print("info: retries %d, time %.0fs" % [m.retries, m._elapsed])
	report()
