class_name Soldier
extends CharacterBody2D
## Foot-soldier AI used for every human NPC in combat.
## Archetypes: training (wooden sword), sword, spear, archer, armoured.
## Teams: "imperial" (opponents) or "mewar" (allies who fight beside the player).
## All NPC soldiers are FICTIONAL composites; none represent named historical people.
## Defeat is non-graphic: the soldier kneels (yields / falls back / withdraws) and fades.
## State machine: Idle > Patrol > Detect > Approach > Telegraph > Attack > Recover,
## plus Block, Stagger, Retreat, Defeated. Every attack is telegraphed.

signal defeated(soldier: Soldier)

enum S { IDLE, PATROL, DETECT, APPROACH, TELEGRAPH, ATTACK, RECOVER, BLOCK, STAGGER, RETREAT, DEFEATED }

const ARROW := preload("res://scripts/enemies/arrow.gd")

## Set by the mission before soldiers spawn (Campaigns.FACTIONS entry). Empty =
## the original Mewar look (asset-pack imperial soldiers, Mewar allies).
static var faction := {}

@export var archetype := "training"
@export var team := "imperial"
@export var max_health := 60.0
@export var attack_damage := 12.0
@export var attack_range := 74.0
@export var detect_range := 380.0
@export var move_speed := 115.0
@export var telegraph_time := 0.55
@export var recover_time := 0.6
@export var attack_cooldown := Vector2(0.9, 1.6)
@export var block_chance := 0.3
@export var patrol_distance := 0.0
@export var preferred_range := 0.0     ## archers keep this distance
@export var defeat_text := "Yields"

var state: S = S.IDLE
var facing := -1
var target: Node2D
var player: Node2D   # kept for compatibility with older callers
var _t := 0.0
var _cooldown := 0.6
var _stagger_time := 0.3
var _home := Vector2.ZERO
var _patrol_dir := 1
var _gravity := 1900.0
var _retarget := 0.0
var _hitbox_reach := Vector2(64, 50)
var display_name := ""
var _size := 1.0
var _chain := 1
var _enraged := false

@onready var rig: HumanRig = $Rig
@onready var health: Health = $Health
var hitbox: Hitbox


func _ready() -> void:
	_apply_archetype()
	add_to_group("soldiers")
	add_to_group(team)
	collision_layer = 4 if team == "imperial" else 64
	collision_mask = 1
	_home = global_position
	health.max_health = max_health
	health.current = max_health
	health.died.connect(_on_died)
	hitbox = Hitbox.new()
	add_child(hitbox)
	var mask := (2 | 64) if team == "imperial" else 4
	hitbox.setup(self, _hitbox_reach, Vector2(_hitbox_reach.x * 0.5 + 10.0, -50), mask)
	_apply_palette()


func _apply_archetype() -> void:
	match archetype:
		"sword":
			max_health = 55.0; attack_damage = 12.0; telegraph_time = 0.5; block_chance = 0.25
			defeat_text = "Falls back"
		"spear":
			max_health = 60.0; attack_damage = 14.0; attack_range = 112.0; telegraph_time = 0.62
			move_speed = 95.0; block_chance = 0.12; _hitbox_reach = Vector2(108, 30)
			defeat_text = "Falls back"
		"archer":
			max_health = 32.0; attack_damage = 9.0; telegraph_time = 0.75; recover_time = 0.5
			preferred_range = 300.0; attack_range = 560.0; detect_range = 640.0; block_chance = 0.0
			attack_cooldown = Vector2(1.4, 2.2); defeat_text = "Falls back"
		"armoured":
			max_health = 110.0; attack_damage = 16.0; telegraph_time = 0.6; move_speed = 85.0
			block_chance = 0.65; recover_time = 0.75; defeat_text = "Falls back"
		"musket":
			# Slow, hard-hitting straight shot with a long, obvious aim. Dodge through it.
			max_health = 40.0; attack_damage = 15.0; telegraph_time = 1.0; recover_time = 0.9
			preferred_range = 380.0; attack_range = 620.0; detect_range = 700.0; block_chance = 0.0
			attack_cooldown = Vector2(2.0, 3.0); defeat_text = "Falls back"
		"champion":
			# Boss: fictional composite commander. Chains blows, and fights harder below half health.
			max_health = 300.0; attack_damage = 18.0; attack_range = 86.0; telegraph_time = 0.52
			move_speed = 125.0; block_chance = 0.4; recover_time = 0.5; attack_cooldown = Vector2(0.6, 1.1)
			_hitbox_reach = Vector2(86, 56); _size = 1.22; defeat_text = "Is beaten"
	if team == "mewar":
		defeat_text = "Withdraws"


func is_ranged() -> bool:
	return archetype == "archer" or archetype == "musket"


## Difficulty scaling (MissionBase.tier): later levels hit harder and attack sooner.
func apply_tier(t: float, scale_health := true) -> void:
	var k := maxf(0.0, t - 1.0)
	attack_damage *= 1.0 + 0.07 * k
	telegraph_time *= maxf(0.72, 1.0 - 0.04 * k)   # never faster than a player can read
	recover_time *= maxf(0.7, 1.0 - 0.04 * k)
	attack_cooldown *= maxf(0.65, 1.0 - 0.05 * k)
	move_speed *= 1.0 + 0.03 * k
	if scale_health:
		max_health *= 1.0 + 0.12 * k
		health.max_health = max_health
		health.current = max_health


func _apply_palette() -> void:
	_choose_art()
	rig.palette = rig.palette.duplicate()
	var pl: Dictionary = rig.palette
	rig.has_shield = false
	rig.has_armour = false
	rig.blade_length = 40.0
	if archetype == "training":
		# Fictional practice opponents: maroon turban, ochre jama, wooden sword.
		pl.turban = Color("7a2630"); pl.turban_band = Color("d9c38a"); pl.jama = Color("b0874f")
		pl.jama_trim = Color("7a2630"); pl.sash = Color("7a2630"); pl.pants = Color("d8ccb2")
		rig.wooden_sword = true
		return
	if team == "imperial":
		# Generic imperial-army colours (slate jama, cream turban). No faith symbols.
		pl.turban = Color("e4ddc8"); pl.turban_band = Color("8a2b2b"); pl.jama = Color("5f7385")
		pl.jama_trim = Color("c9b98a"); pl.sash = Color("8a2b2b"); pl.pants = Color("d8d0bc")
	else:
		# Mewar allies (composite): red turban, ochre jama.
		pl.turban = Color("a8322a"); pl.turban_band = Game.C_GOLD; pl.jama = Color("c27b2e")
		pl.jama_trim = Game.C_GOLD; pl.sash = Color("a8322a"); pl.pants = Color("e9dcc0")
	if not faction.is_empty():
		var look: Dictionary = faction["imperial" if team == "imperial" else "ally"]
		for k in look:
			if pl.has(k):
				pl[k] = look[k]
		rig.headgear = look.get("headgear", "turban")
		rig.has_moustache = look.get("moustache", true)
	match archetype:
		"spear":
			rig.weapon = "spear"
		"archer":
			rig.weapon = "bow"
			if team == "mewar" and faction.is_empty():
				# Bhil archer ally (composite): white turban, plain off-white garments.
				pl.turban = Color("efe9da"); pl.turban_band = Color("8a4b2a"); pl.jama = Color("d8c7a2")
				pl.sash = Color("8a4b2a"); pl.jama_trim = Color("8a4b2a")
		"armoured":
			rig.has_armour = true
			rig.has_shield = true
			pl.armour = Color("b8bec6"); pl.turban = Color("9aa2ab"); pl.turban_band = Color("6c737b")
			pl.shield = Color("4a4f57"); pl.shield_boss = Color("c9ced4")
		"musket":
			rig.weapon = "musket"
		"champion":
			rig.has_armour = true
			rig.has_shield = true
			rig.blade_length = 50.0
			rig.plume = true
			pl.armour = Color("d9b84a"); pl.jama = (pl.jama as Color).darkened(0.35); pl.jama_trim = Color("e0b84a")
			pl.shield = Color("2a1a14"); pl.shield_boss = Color("e0b84a"); pl.sash = Color("e0b84a")


## Asset-pack art where it exists: imperial sword/spear/armoured soldiers use the
## imperial soldier sheet; Mewar allies use the Rajput ally / Bhil warrior standees.
## Training partners and archers keep procedural art (the pack has no matching art).
func _choose_art() -> void:
	if not rig is SpriteRig:
		return
	var sr := rig as SpriteRig
	if not faction.is_empty() or archetype in ["champion", "musket"]:
		sr.disable_sprite()
		return
	if team == "imperial" and archetype in ["sword", "spear", "armoured"] and sr.uses_sprite():
		if archetype == "armoured":
			sr.modulate = Color(0.85, 0.9, 1.0)
			sr.sprite_scale = 0.72
		return
	if team == "mewar":
		var tex := MewarAssets.tex("Characters/Allies/%s.png" % ("bhil_warrior" if archetype == "archer" else "rajput_ally"))
		sr.use_standee(tex)
		sr.sprite_scale = 0.66
		sr.sprite.scale = Vector2.ONE * 0.66
		return
	sr.disable_sprite()


func _physics_process(delta: float) -> void:
	_t += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	_retarget -= delta
	if not is_instance_valid(target):
		target = null   # e.g. an arena unit freed on respawn
	if _retarget <= 0.0 or not _target_valid(target):
		target = _find_target()
		player = target
		_retarget = 0.4
	var dx := 0.0
	var dist := INF
	var available := false
	if target:
		dx = target.global_position.x - global_position.x
		dist = absf(dx)
		available = _target_valid(target)

	match state:
		S.IDLE:
			_brake(delta)
			rig.play("idle")
			if available and dist < detect_range:
				_go(S.DETECT)
			elif patrol_distance > 0.0 and _t > 1.2:
				_go(S.PATROL)
		S.PATROL:
			velocity.x = _patrol_dir * move_speed * 0.5
			facing = _patrol_dir
			rig.play("walk")
			if absf(global_position.x - _home.x) > patrol_distance:
				_patrol_dir = -int(signf(global_position.x - _home.x))
			if available and dist < detect_range:
				_go(S.DETECT)
		S.DETECT:
			_brake(delta)
			_face(dx)
			rig.play("block" if not is_ranged() else "idle")
			if _t > 0.35:
				_go(S.APPROACH)
		S.APPROACH:
			_face(dx)
			if not available:
				_go(S.IDLE)
			elif preferred_range > 0.0:
				_approach_ranged(delta, dx, dist)
			elif dist > attack_range:
				velocity.x = signf(dx) * move_speed
				rig.play("walk" if move_speed < 150 else "run")
			elif dist < attack_range * 0.5:
				velocity.x = -signf(dx) * move_speed * 0.6  # keep fair spacing
				rig.play("walk")
			else:
				_brake(delta)
				rig.play("block")
				if _cooldown <= 0.0:
					_go(S.TELEGRAPH)
			if health.current < max_health * 0.35 and randf() < 0.004:
				_go(S.RETREAT)
		S.TELEGRAPH:
			_brake(delta)
			if is_ranged():
				rig.play("aim")
				rig.set_progress(_t / telegraph_time)
			else:
				rig.play("telegraph")
			rig.modulate = Color(1.0, 0.75, 0.7) if team == "imperial" else Color(1, 1, 0.85)
			if _t >= telegraph_time:
				rig.modulate = Color.WHITE
				if is_ranged():
					_fire_arrow()
					_go(S.RECOVER)
				else:
					_go(S.ATTACK)
					rig.play("attack3" if archetype == "spear" else "attack1", true)
					Audio.sfx("swing", 0.1, -5.0)
		S.ATTACK:
			var u := _t / 0.36
			rig.set_progress(u)
			var lunge := 120.0 if archetype == "spear" else 90.0
			velocity.x = facing * lunge if u > 0.3 and u < 0.5 else move_toward(velocity.x, 0.0, 2000.0 * delta)
			if u >= 0.3 and u < 0.55:
				if not hitbox.is_active():
					hitbox.activate({"damage": attack_damage, "knockback": 200.0, "heavy": archetype in ["armoured", "champion"]})
					rig.swoosh = 0.8
					Fx.effect("slash", global_position + Vector2(facing * 44, -56), 0.6, facing < 0)
			elif hitbox.is_active():
				hitbox.deactivate()
			if u >= 1.0:
				if archetype == "champion" and _chain > 0 and available and dist < attack_range * 1.6:
					# chained blow: a shorter (but still visible) wind-up
					_chain -= 1
					_face(dx)
					_go(S.TELEGRAPH)
					_t = telegraph_time * 0.45
				else:
					_go(S.RECOVER)
		S.RECOVER:
			_brake(delta)
			rig.play("idle")
			if _t >= recover_time:
				_cooldown = randf_range(attack_cooldown.x, attack_cooldown.y) * (0.6 if _enraged else 1.0)
				_chain = 2 if _enraged else 1
				_go(S.APPROACH)
		S.BLOCK:
			_brake(delta)
			rig.play("block")
			if _t > 0.4:
				_cooldown = 0.0   # quick counter after a successful block
				_go(S.APPROACH)
		S.STAGGER:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			rig.play("hurt")
			if _t >= _stagger_time:
				_cooldown = maxf(_cooldown, 0.35)
				_go(S.APPROACH)
		S.RETREAT:
			_face(dx)
			velocity.x = -signf(dx) * move_speed * 0.8
			rig.play("walk")
			if _t > 0.7:
				_go(S.APPROACH)
		S.DEFEATED:
			_brake(delta)
			rig.play("yield")

	if archetype == "champion" and not _enraged and health.current < max_health * 0.5 and state != S.DEFEATED:
		_enraged = true
		Fx.spark(global_position + Vector2(0, -70), Color(1, 0.5, 0.2), 24)
		CameraRig.shake_global(6.0)
	rig.scale = Vector2(facing * _size, _size)
	if _enraged and state != S.TELEGRAPH and state != S.DEFEATED:
		rig.modulate = Color(1.0, 0.82, 0.72)
	hitbox.scale.x = facing
	velocity.y = minf(velocity.y + _gravity * delta, 1100.0)
	move_and_slide()
	queue_redraw()


func _approach_ranged(delta: float, dx: float, dist: float) -> void:
	if dist < preferred_range * 0.6:
		velocity.x = -signf(dx) * move_speed * 0.7
		rig.play("walk")
	elif dist > attack_range:
		velocity.x = signf(dx) * move_speed
		rig.play("walk")
	else:
		_brake(delta)
		rig.play("idle")
		if _cooldown <= 0.0:
			_go(S.TELEGRAPH)


# ------------------------------------------------------------------ targeting

func _target_valid(t: Node2D) -> bool:
	if t == null or not is_instance_valid(t) or not t.is_inside_tree() or not t.visible:
		return false
	if absf(t.global_position.y - global_position.y) > 150.0 and preferred_range <= 0.0:
		return false
	if t is Player:
		var p := t as Player
		return not (p.state in [Player.State.DEAD, Player.State.MOUNTED, Player.State.LOCKED])
	if t is Soldier:
		return (t as Soldier).state != S.DEFEATED
	return true


func _find_target() -> Node2D:
	var cands: Array = []
	if team == "imperial":
		cands.append_array(get_tree().get_nodes_in_group("player"))
		cands.append_array(get_tree().get_nodes_in_group("mewar"))
	else:
		cands.append_array(get_tree().get_nodes_in_group("imperial"))
	var best: Node2D = null
	var bd := INF
	for c in cands:
		if c == self or not _target_valid(c):
			continue
		var d := global_position.distance_to(c.global_position)
		if c is Player:
			d *= 0.8   # opponents prefer engaging the player
		if d < bd:
			bd = d
			best = c
	return best


func _fire_arrow() -> void:
	var a: Area2D = ARROW.new()
	a.team = team
	a.damage = attack_damage
	a.shooter = self
	var origin := global_position + Vector2(facing * 22.0, -66.0)
	var aim := Vector2(facing, 0.0)
	if target:
		var to := (target.global_position + Vector2(0, -50)) - origin
		aim = to.normalized()
		aim.y -= clampf(to.length() / 2400.0, 0.0, 0.25)   # slight arc
		aim = aim.normalized()
	a.velocity = aim * 620.0
	if archetype == "musket":
		a.style = "ball"
		a.velocity = Vector2(facing, clampf(aim.y, -0.12, 0.12)).normalized() * 1050.0
		Fx.spark(origin + Vector2(facing * 30.0, 0), Color(1, 0.8, 0.4), 10)
	a.global_position = origin
	get_parent().add_child(a)
	Audio.sfx("musket" if archetype == "musket" else "bow", 0.1, -4.0)


func _go(s: S) -> void:
	state = s
	_t = 0.0
	hitbox.deactivate()
	if s != S.TELEGRAPH:
		rig.modulate = Color.WHITE


func _brake(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)


func _face(dx: float) -> void:
	if absf(dx) > 4.0:
		facing = 1 if dx > 0.0 else -1


func take_hit(info: Dictionary) -> void:
	if state == S.DEFEATED:
		return
	var from_dir := -int(info.get("dir", 1.0))
	var can_block := state in [S.IDLE, S.PATROL, S.DETECT, S.APPROACH, S.BLOCK, S.RECOVER] and from_dir == facing
	if can_block and not info.get("heavy", false) and (state == S.BLOCK or randf() < block_chance):
		_go(S.BLOCK)
		Audio.sfx("block", 0.1, -3.0)
		Fx.spark(global_position + Vector2(facing * 18, -58), Color(1, 0.85, 0.5), 8)
		velocity.x = -facing * 120.0
		return
	health.damage(info.get("damage", 10.0))
	Audio.sfx("hit", 0.12, -1.0)
	Fx.spark(global_position + Vector2(0, -56), Color(1, 0.95, 0.75), 10)
	if info.get("source") is Player:
		Fx.hitstop(0.05 if not info.get("heavy", false) else 0.1)
		CameraRig.shake_global(3.0 if not info.get("heavy", false) else 7.0)
	rig.modulate = Color(2.0, 2.0, 2.0)
	get_tree().create_timer(0.07, false).timeout.connect(_unflash)
	if health.is_dead():
		return
	var kb := float(info.get("knockback", 120.0)) * (0.5 if archetype == "armoured" else 1.0)
	velocity.x = -from_dir * kb
	facing = from_dir
	_stagger_time = float(info.get("stagger", 0.3)) * (0.6 if archetype == "armoured" and not info.get("heavy", false) else 1.0)
	_go(S.STAGGER)


func on_parried() -> void:
	if state == S.DEFEATED:
		return
	velocity.x = -facing * 160.0
	_stagger_time = 1.0
	_go(S.STAGGER)


func reset_to_home() -> void:
	global_position = _home
	velocity = Vector2.ZERO
	health.restore_full()
	_go(S.IDLE)


func _on_died() -> void:
	_go(S.DEFEATED)
	collision_layer = 0
	Audio.sfx("yield", 0.0, -2.0)
	defeated.emit(self)
	var tw := create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(self, "modulate:a", 0.0, 0.8)
	tw.tween_callback(_retire)


func _unflash() -> void:
	if state != S.TELEGRAPH:
		rig.modulate = Color.WHITE


func _retire() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED


func _draw() -> void:
	if state == S.TELEGRAPH and team == "imperial":
		var a := 0.6 + 0.4 * sin(_t * 30.0)
		draw_string(ThemeDB.fallback_font, Vector2(-6, -112), "!", HORIZONTAL_ALIGNMENT_CENTER, -1, 30, Color(1, 0.3, 0.2, a))
	elif state == S.DETECT and team == "imperial":
		draw_string(ThemeDB.fallback_font, Vector2(-6, -112), "?", HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color(1, 0.9, 0.5))
	elif state == S.DEFEATED and _t < 1.8:
		draw_string(ThemeDB.fallback_font, Vector2(-40, -108), defeat_text, HORIZONTAL_ALIGNMENT_CENTER, 80, 18, Color(1, 0.95, 0.8, 1.0 - _t / 1.8))
	if state != S.DEFEATED and health.current < max_health:
		var w := 44.0
		draw_rect(Rect2(-w * 0.5, -124, w, 5), Color(0, 0, 0, 0.5))
		draw_rect(Rect2(-w * 0.5, -124, w * health.current / max_health, 5), Color("d9a441") if team == "imperial" else Color("6fbf73"))
	if team == "mewar" and state != S.DEFEATED:
		draw_colored_polygon(PackedVector2Array([Vector2(-5, -132), Vector2(5, -132), Vector2(0, -124)]), Color("6fbf73"))
