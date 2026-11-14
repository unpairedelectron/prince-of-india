extends "res://tests/bot_base.gd"
## Asset-pack integration test: drives the real controls in the Asset Test Room and
## checks that the sprite animations, tile collision, Chetak, enemy art, effects,
## icons and backgrounds are actually in use.

var effects_spawned := {}


func _ready() -> void:
	Game.reset_progress()
	Game.settings.touch_controls = "on"
	load_mission("res://scenes/environments/test/asset_test_room.tscn")
	mission.get_tree().node_added.connect(func(n):
		if n is AnimatedSprite2D and n.sprite_frames == MewarAssets.effect_frames():
			(func(): effects_spawned[n.animation] = true).call_deferred())
	await wait(0.8)
	var rig: SpriteRig = p.rig
	var spr := rig.sprite
	check("Pratap uses the sprite atlas (not procedural)", rig.uses_sprite() and spr != null)
	var sf := spr.sprite_frames
	var names := ["idle", "walk", "run", "jump", "attack", "block", "hurt", "victory"]
	var all8 := true
	for n in names:
		all8 = all8 and sf.has_animation(n) and sf.get_frame_count(n) == 4
	check("All 8 Pratap animations configured, 4 frames each", all8, str(sf.get_animation_names()))
	check("Pratap stands on TileMapLayer floor (y ~ 0)", p.is_on_floor() and absf(p.global_position.y) < 2.0, "y %.1f" % p.global_position.y)
	check("Idle animation playing", spr.animation == "idle" and spr.is_playing())

	var seen := {}
	var watch := func():
		if spr.visible:
			seen[spr.animation] = true
	get_tree().physics_frame.connect(watch)
	press("move_right")
	await wait(0.15)
	check("Walk animation on short move", spr.animation == "walk")
	await wait(0.8)
	check("Run animation after holding", spr.animation == "run", spr.animation)
	release("move_right")
	await wait(0.4)
	press("jump")
	await wait(0.15)
	check("Jump animation in the air", spr.animation == "jump" and not p.is_on_floor())
	release("jump")
	await wait(1.0)
	await tap("attack", 0.03)
	var frames_seen := {}
	for i in 20:
		await get_tree().physics_frame
		if spr.animation == "attack":
			frames_seen[spr.frame] = true
	check("Attack animation steps through frames", frames_seen.size() >= 3, "frames %s" % str(frames_seen.keys()))
	check("Slash effect sprite spawned on swing", effects_spawned.has("slash"))
	await wait(0.5)
	press("block")
	await wait(0.4)
	check("Block animation while holding block", spr.animation == "block")
	release("block")
	await wait(0.3)
	p.take_hit({"damage": 5.0, "dir": -1.0, "knockback": 60.0, "source": mission})
	await wait(0.05)
	check("Hurt animation when hit", spr.animation == "hurt")
	await wait(1.2)
	p.lock("victory")
	await wait(0.2)
	check("Victory animation on lock('victory')", spr.animation == "victory")
	p.unlock()
	await wait(0.3)
	check("Transitions return to idle", spr.animation == "idle", spr.animation)

	# --- one-way platforms placed at the measured art height
	for spec in [[Vector2(580, -300), -86.0, "wood_platform"], [Vector2(890, -300), -144.0, "platform_edge"], [Vector2(1056, -320), -204.0, "stone_ledge"]]:
		p.global_position = spec[0]
		p.velocity = Vector2.ZERO
		await wait(1.0)
		check("Lands on %s at its drawn surface" % spec[2], p.is_on_floor() and absf(p.global_position.y - spec[1]) < 2.5, "y %.1f (expected %.0f)" % [p.global_position.y, spec[1]])
	p.global_position = Vector2(580, -2)
	await wait(0.5)
	press("jump")
	await wait(0.45)
	release("jump")
	await wait(0.8)
	check("Can jump up through a one-way platform", p.is_on_floor() and absf(p.global_position.y + 86.0) < 2.5, "y %.1f" % p.global_position.y)
	p.global_position = Vector2(1400, -300)
	await wait(1.0)
	check("Solid tile tower (wall_cap) collides", p.is_on_floor() and absf(p.global_position.y + 256.0) < 2.0, "y %.1f" % p.global_position.y)

	# --- ladder from floor to tower
	p.global_position = Vector2(1200, -2)
	await wait(0.4)
	press("move_right")
	await wait(0.25)
	release("move_right")
	press("move_up")
	await wait(2.5)
	release("move_up")
	press("move_right")
	await wait(0.5)
	release_all()
	await wait(0.4)
	check("Ladder climb onto the tile tower", p.global_position.y < -250.0 and p.is_on_floor(), "x %.0f y %.0f" % [p.global_position.x, p.global_position.y])

	# --- Chetak
	var h: Horse = mission.horse
	var hs: HorseSprite = h.rig
	check("Chetak uses the sprite atlas", hs._use_sprite)
	var hall := true
	for n in ["idle", "walk", "gallop", "jump"]:
		hall = hall and hs.sprite.sprite_frames.has_animation(n) and hs.sprite.sprite_frames.get_frame_count(n) == 4
	check("All 4 Chetak animations configured", hall)
	p.global_position = h.global_position + Vector2(-60, -2)
	await wait(0.4)
	await tap("mount")
	await wait(0.4)
	check("Mounted", p.is_mounted())
	check("Rider shows upper-body crop, full sprite hidden", rig.rider_crop.visible and not spr.visible)
	var dy := p.global_position.y - (h.global_position.y + h.rig.saddle_point().y)
	check("Rider anchored at Chetak's saddle", absf(dy - 6.0) < 1.0, "dy %.1f" % dy)
	var hseen := {}
	var hwatch := func(): hseen[hs.sprite.animation] = true
	get_tree().physics_frame.connect(hwatch)
	press("move_left")
	await wait(0.6)
	press("gallop")
	await wait(1.0)
	press("jump")
	await wait(0.25)
	release_all()
	await wait(1.2)
	check("Chetak plays walk, gallop and jump while ridden", hseen.has("walk") and hseen.has("gallop") and hseen.has("jump"), str(hseen.keys()))
	check("Chetak returns to idle when stopped", hs.sprite.animation == "idle")
	await tap("mount")
	await wait(0.5)
	check("Dismounted back to full sprite", not p.is_mounted() and spr.visible)

	# --- imperial soldier + ally
	var s: Soldier = mission.soldier
	var ssr: SpriteRig = s.rig
	check("Imperial soldier uses the enemy sheet", ssr.uses_sprite() and ssr.sprite.sprite_frames == MewarAssets.frames("imperial"))
	check("Ally uses the Rajput ally standee", mission.ally.rig.uses_sprite() and mission.ally.rig._standee)
	p.global_position = Vector2(3150, -2)
	var sseen := {}
	var swatch := func(): sseen[ssr.sprite.animation] = true
	get_tree().physics_frame.connect(swatch)
	var t := 0.0
	while t < 25.0 and s.state != Soldier.S.DEFEATED:
		await fight_step(s)
		await wait(0.05)
		t += 0.05
	release_all()
	check("Soldier animations: walk, attack, hurt observed", sseen.has("walk") and sseen.has("attack") and sseen.has("hurt"), str(sseen.keys()))
	check("Spark effect sprite on hits", effects_spawned.has("spark"))
	check("Soldier defeated (non-graphic yield)", s.state == Soldier.S.DEFEATED)

	# --- UI icons, backgrounds, props
	var tb: TouchButton = mission.ui.touch.buttons.left
	check("Touch buttons use asset-pack icons", MewarAssets.icon("left") != null and TouchButton.ICONS.has(tb.glyph))
	var bg_layers: int = mission._screen_layers.size()
	check("Painted background parallax layers present", bg_layers == 2, "%d" % bg_layers)
	check("Props / fire effect available", MewarAssets.prop("torch") != null and MewarAssets.effect_frames().has_animation("fire"))
	report()
