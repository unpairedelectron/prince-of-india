class_name Player
extends CharacterBody2D
## Maharana Pratap - on-foot controller.
## Movement (accel/decel, run/sprint, variable jump, coyote time, jump buffer,
## crouch, ladders) + combat (3-hit combo, held heavy, block, timed parry,
## dodge with i-frames) + a state lock so incompatible actions can't overlap.
## All feel values are exported for playtest tuning.

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal defeated
signal mounted_changed(is_mounted: bool, horse: Node)
signal context_changed

enum State { NORMAL, CLIMB, ATTACK, HEAVY_WINDUP, HEAVY, BLOCK, DODGE, HURT, DEAD, MOUNTED, LOCKED }

@export_group("Movement")
@export var walk_speed := 175.0
@export var run_speed := 285.0
@export var sprint_speed := 360.0
@export var run_after := 0.22        ## seconds holding a direction before running
@export var sprint_after := 1.4      ## seconds of running before sprinting
@export var ground_accel := 2300.0
@export var ground_decel := 2800.0
@export var air_accel := 1500.0
@export var crouch_speed := 95.0
@export var climb_speed := 160.0
@export_group("Jump")
@export var gravity := 1900.0
@export var fall_gravity_mult := 1.35
@export var jump_velocity := -700.0
@export var jump_cut_mult := 0.45    ## velocity kept when jump is released early
@export var max_fall_speed := 1100.0
@export var coyote_time := 0.1
@export var jump_buffer := 0.12
@export_group("Combat")
@export var light_damage := [12.0, 12.0, 18.0]
@export var light_duration := 0.34
@export var heavy_damage := 30.0
@export var heavy_windup := 0.32
@export var heavy_duration := 0.42
@export var parry_window := 0.18
@export var dodge_speed := 470.0
@export var dodge_time := 0.3
@export var hurt_time := 0.3
@export var iframes_after_hit := 0.7
@export_group("Stamina")
@export var max_stamina := 100.0
@export var stamina_regen := 30.0
@export var stamina_regen_delay := 0.55
@export var cost_light := 5.0
@export var cost_heavy := 20.0
@export var cost_dodge := 22.0
@export var cost_block_hit := 14.0
@export var cost_sprint := 9.0        ## per second

var state: State = State.NORMAL
var facing := 1
var input_enabled := true
var stamina := 100.0
var horse: Node = null

var _state_time := 0.0
var _coyote := 0.0
var _jump_buffer := 0.0
var _move_hold := 0.0
var _was_on_floor := true
var _land_timer := 0.0
var _crouching := false
var _combo := 0
var _combo_queued := false
var _iframes := 0.0
var _regen_wait := 0.0
var _ladder: Area2D = null
var _ladders: Array = []
var _interactables: Array = []
var _block_time := 0.0
var _jumping := false
var _air_time := 0.0
# hero traits (see data/campaigns.gd HEROES[..].stats)
var hero := {}
var block_cost_mult := 1.0
var parry_refund := 0.0
var dodge_crit := 1.0
var _crit_window := 0.0

@onready var rig: HumanRig = $Rig
@onready var health: Health = $Health
@onready var body_shape: CollisionShape2D = $BodyShape
@onready var sensor: Area2D = $Sensor
var hitbox: Hitbox
var _stand_shape: RectangleShape2D
var _crouch_shape: RectangleShape2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 10.0
	_stand_shape = body_shape.shape
	_crouch_shape = RectangleShape2D.new()
	_crouch_shape.size = Vector2(_stand_shape.size.x, 58)
	hitbox = Hitbox.new()
	add_child(hitbox)
	hitbox.setup(self, Vector2(70, 56), Vector2(48, -52), 4)  # mask: enemy layer (3)
	sensor.collision_layer = 0
	sensor.collision_mask = 32  # interact layer (6)
	sensor.area_entered.connect(_on_sensor_area_entered)
	sensor.area_exited.connect(_on_sensor_area_exited)
	health.changed.connect(func(c, m): health_changed.emit(c, m))
	health.died.connect(_on_died)
	stamina = max_stamina


## Applies a hero definition: look (procedural rig + palette unless the hero
## has sprite art) and the stat changes that make each hero play differently.
func apply_hero(cfg: Dictionary) -> void:
	hero = cfg
	var look: Dictionary = cfg.get("look", {})
	if not look.get("sprite", false):
		if rig is SpriteRig:
			(rig as SpriteRig).disable_sprite()
		rig.apply_look(look)
	var st: Dictionary = cfg.get("stats", {})
	var sp: float = st.get("speed", 1.0)
	walk_speed *= sp
	run_speed *= sp
	sprint_speed *= sp
	cost_dodge *= st.get("dodge_cost", 1.0)
	dodge_crit = st.get("dodge_crit", 1.0)
	var aspd: float = st.get("attack_speed", 1.0)
	light_duration /= aspd
	heavy_duration /= aspd
	cost_light *= st.get("light_cost", 1.0)
	block_cost_mult = st.get("block_cost", 1.0)
	parry_window *= st.get("parry_window", 1.0)
	parry_refund = st.get("parry_refund", 0.0)
	heavy_damage *= st.get("heavy_damage", 1.0)
	heavy_windup *= st.get("heavy_windup", 1.0)
	if st.has("health"):
		health.max_health = st.health
		health.restore_full()


## Damage multiplier for the strike being launched; consumes the post-dodge bonus.
func _strike_bonus() -> float:
	if _crit_window > 0.0 and dodge_crit > 1.0:
		_crit_window = 0.0
		Fx.spark(global_position + Vector2(facing * 40, -60), Color(1.0, 0.6, 0.2), 16)
		Audio.sfx("parry", 0.1, -6.0)
		return dodge_crit
	return 1.0


# ================================================================== input

func _axis() -> float:
	if not input_enabled:
		return 0.0
	return Input.get_axis("move_left", "move_right")


func _vaxis() -> float:
	if not input_enabled:
		return 0.0
	return Input.get_axis("move_up", "move_down")


func _pressed(action: String) -> bool:
	return input_enabled and Input.is_action_just_pressed(action)


func _held(action: String) -> bool:
	return input_enabled and Input.is_action_pressed(action)


# ================================================================== main loop

func _physics_process(delta: float) -> void:
	_state_time += delta
	_iframes = maxf(0.0, _iframes - delta)
	_crit_window = maxf(0.0, _crit_window - delta)
	_tick_stamina(delta)
	if _pressed("jump"):
		_jump_buffer = jump_buffer
	else:
		_jump_buffer = maxf(0.0, _jump_buffer - delta)

	match state:
		State.NORMAL: _state_normal(delta)
		State.CLIMB: _state_climb(delta)
		State.ATTACK: _state_attack(delta)
		State.HEAVY_WINDUP: _state_heavy_windup(delta)
		State.HEAVY: _state_heavy(delta)
		State.BLOCK: _state_block(delta)
		State.DODGE: _state_dodge(delta)
		State.HURT: _state_hurt(delta)
		State.DEAD: _state_simple_physics(delta, 0.0)
		State.LOCKED: _state_simple_physics(delta, 0.0)
		State.MOUNTED: _state_mounted(delta)

	rig.scale.x = facing
	hitbox.scale.x = facing
	# i-frame flicker
	if _iframes > 0.0 and state != State.DODGE:
		rig.modulate.a = 0.45 if int(_iframes * 20.0) % 2 == 0 else 1.0
	else:
		rig.modulate.a = 1.0


func _set_state(s: State) -> void:
	state = s
	_state_time = 0.0
	hitbox.deactivate()
	context_changed.emit()


# ------------------------------------------------------------------ NORMAL

func _state_normal(delta: float) -> void:
	var on_floor := is_on_floor()
	var x := _axis()
	var want_crouch := on_floor and _vaxis() > 0.5 and _ladder_below() == null
	if want_crouch != _crouching:
		if want_crouch or _can_stand():
			_set_crouch(want_crouch)

	# horizontal
	if absf(x) > 0.1:
		_move_hold += delta
		facing = 1 if x > 0.0 else -1
	else:
		_move_hold = 0.0
	var target_speed := walk_speed
	if _crouching:
		target_speed = crouch_speed
	elif _move_hold > run_after + sprint_after and stamina > 5.0 and on_floor:
		target_speed = sprint_speed
		_use_stamina(cost_sprint * delta, false)
	elif _move_hold > run_after:
		target_speed = run_speed
	var accel := ground_accel if on_floor else air_accel
	if absf(x) > 0.1:
		velocity.x = move_toward(velocity.x, signf(x) * target_speed, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, (ground_decel if on_floor else air_accel * 0.6) * delta)

	# vertical
	if on_floor:
		_coyote = coyote_time
		_jumping = false
	else:
		_coyote = maxf(0.0, _coyote - delta)
	_apply_gravity(delta)
	if _jump_buffer > 0.0 and _coyote > 0.0 and not _crouching:
		_do_jump()
	if _jumping and velocity.y < 0.0 and not _held("jump"):
		velocity.y *= jump_cut_mult
		_jumping = false

	move_and_slide()
	_after_move(on_floor)

	# transitions
	if _ladders.size() > 0 and absf(_vaxis()) > 0.5:
		var l := _pick_ladder()
		if l:
			# Up grabs only below the top (no re-grab loop after topping out);
			# Down grabs from the top or mid-ladder, not at the bottom.
			var at_top := global_position.y <= _ladder_top(l) + 8.0
			var up_ok := _vaxis() < 0.0 and not at_top
			var down_ok := _vaxis() > 0.0 and global_position.y < _ladder_bottom(l) - 6.0
			if up_ok or down_ok:
				_start_climb(l)
				return
	if not on_floor:
		pass
	elif _pressed("attack"):
		_start_attack(0)
	elif _held("block"):
		_set_crouch(false)
		_block_time = 0.0
		_set_state(State.BLOCK)
	elif _pressed("dodge"):
		_start_dodge()
	elif _pressed("interact") or _pressed("mount"):
		_try_interact()
	# only animate locomotion if no action started this frame (an attack/dodge
	# started above must not be overwritten by idle/walk in the same frame)
	if state == State.NORMAL:
		_update_locomotion_anim()


func _do_jump() -> void:
	velocity.y = jump_velocity
	_jump_buffer = 0.0
	_coyote = 0.0
	_jumping = true
	Audio.sfx("jump", 0.1, -4.0)
	Fx.dust(global_position, 6)


func _apply_gravity(delta: float) -> void:
	var g := gravity * (fall_gravity_mult if velocity.y > 0.0 else 1.0)
	velocity.y = minf(velocity.y + g * delta, max_fall_speed)


func _after_move(was_on_floor: bool) -> void:
	var now := is_on_floor()
	if not now:
		_air_time += get_physics_process_delta_time()
	if now and not was_on_floor and _air_time > 0.12:
		_land_timer = 0.12
		Audio.sfx("land", 0.1, -6.0)
		Fx.dust(global_position, 8)
	if now:
		_air_time = 0.0
	_land_timer = maxf(0.0, _land_timer - get_physics_process_delta_time())


func _update_locomotion_anim() -> void:
	var sp := absf(velocity.x)
	rig.speed_ratio = clampf(sp / sprint_speed, 0.0, 1.0)
	if not is_on_floor():
		rig.play("jump" if velocity.y < 0.0 else "fall")
	elif _land_timer > 0.0:
		rig.play("land")
	elif _crouching:
		rig.play("crouch_walk" if sp > 10.0 else "crouch")
	elif sp > run_speed + 20.0:
		rig.play("sprint")
	elif sp > walk_speed + 20.0:
		rig.play("run")
	elif sp > 15.0:
		rig.play("walk")
	else:
		rig.play("idle")


func _set_crouch(c: bool) -> void:
	_crouching = c
	body_shape.shape = _crouch_shape if c else _stand_shape
	body_shape.position.y = -_crouch_shape.size.y * 0.5 if c else -_stand_shape.size.y * 0.5


func _can_stand() -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = _stand_shape
	q.transform = Transform2D(0, global_position + Vector2(0, -_stand_shape.size.y * 0.5 - 1.0))
	q.collision_mask = 1
	q.exclude = [get_rid()]
	return get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()


func is_crouching() -> bool:
	return _crouching


# ------------------------------------------------------------------ CLIMB

func _pick_ladder() -> Area2D:
	var best: Area2D = null
	var bd := INF
	for l in _ladders:
		var d := absf(l.global_position.x - global_position.x)
		if d < bd:
			bd = d
			best = l
	return best


func _ladder_top(l: Area2D) -> float:
	return l.global_position.y - float(l.get_meta("height", 200.0)) * 0.5


func _ladder_bottom(l: Area2D) -> float:
	return l.global_position.y + float(l.get_meta("height", 200.0)) * 0.5


func _ladder_below() -> Area2D:
	for l in _ladders:
		if absf(_ladder_top(l) - global_position.y) < 14.0:
			return l
	return null


func _start_climb(l: Area2D) -> void:
	_ladder = l
	_set_crouch(false)
	velocity = Vector2.ZERO
	_set_state(State.CLIMB)
	rig.play("climb")
	if absf(_ladder_top(l) - global_position.y) < 14.0:
		global_position.y += 16.0  # step down onto ladder from its top


func _state_climb(delta: float) -> void:
	if _ladder == null or not is_instance_valid(_ladder):
		_set_state(State.NORMAL)
		return
	var v := _vaxis()
	global_position.x = move_toward(global_position.x, _ladder.global_position.x, 400.0 * delta)
	velocity = Vector2(0, v * climb_speed)
	rig.speed_ratio = absf(v)
	rig.play("climb")
	# Climbing up passes through one-way lips; climbing down stops on solid ground.
	if v > 0.0:
		var col := move_and_collide(velocity * delta)
		if col:
			_set_state(State.NORMAL)
			return
	else:
		global_position += velocity * delta
	if global_position.y <= _ladder_top(_ladder):
		global_position.y = _ladder_top(_ladder) - 2.0
		velocity = Vector2(facing * 60.0, -120.0)
		_set_state(State.NORMAL)
		return
	if global_position.y > _ladder_bottom(_ladder) + 4.0:
		_set_state(State.NORMAL)
		return
	if _pressed("jump"):
		_set_state(State.NORMAL)
		var x := _axis()
		if absf(x) > 0.1:
			facing = 1 if x > 0 else -1
		velocity = Vector2(facing * 180.0, jump_velocity * 0.75)
		_jumping = true


# ------------------------------------------------------------------ ATTACKS

func _start_attack(index: int) -> void:
	if stamina < cost_light * 0.5:
		return
	_use_stamina(cost_light)
	_set_crouch(false)
	_combo = index
	_combo_queued = false
	_set_state(State.ATTACK)
	rig.play("attack%d" % (index + 1), true)
	var x := _axis()
	if absf(x) > 0.1:
		facing = 1 if x > 0.0 else -1


func _state_attack(delta: float) -> void:
	var u := _state_time / light_duration
	rig.set_progress(u)
	# small forward lunge during strike frames, otherwise brake hard
	if u > 0.3 and u < 0.5:
		velocity.x = facing * (130.0 if _combo == 2 else 70.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, ground_decel * delta)
	_state_simple_physics(delta, -1.0)
	if u >= 0.3 and u < 0.58:
		if not hitbox.is_active():
			hitbox.activate({"damage": light_damage[_combo] * _strike_bonus(), "knockback": 120.0 if _combo < 2 else 260.0, "heavy": false, "stagger": 0.25 if _combo < 2 else 0.45})
			rig.swoosh = 1.0
			Fx.effect("slash", global_position + Vector2(facing * 46, -58), 0.75, facing < 0, (-0.3 if _combo == 1 else 0.0))
			Audio.sfx("swing", 0.12, -3.0)
	elif hitbox.is_active():
		hitbox.deactivate()
	if _pressed("attack") and u > 0.25:
		_combo_queued = true
	if u >= 1.0:
		if _combo_queued and _combo < 2:
			_start_attack(_combo + 1)
		elif _held("attack") and stamina >= cost_heavy:
			_set_state(State.HEAVY_WINDUP)
			rig.play("heavy_windup", true)
		else:
			_set_state(State.NORMAL)


func _state_heavy_windup(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, ground_decel * delta)
	_state_simple_physics(delta, -1.0)
	if _state_time >= heavy_windup and (not _held("attack") or _state_time > heavy_windup + 0.45):
		_use_stamina(cost_heavy)
		_set_state(State.HEAVY)
		rig.play("heavy", true)
	elif _pressed("block") or _pressed("dodge"):
		_set_state(State.NORMAL)  # cancel charge


func _state_heavy(delta: float) -> void:
	var u := _state_time / heavy_duration
	rig.set_progress(u)
	if u > 0.25 and u < 0.45:
		velocity.x = facing * 160.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, ground_decel * delta)
	_state_simple_physics(delta, -1.0)
	if u >= 0.25 and u < 0.5:
		if not hitbox.is_active():
			hitbox.activate({"damage": heavy_damage * _strike_bonus(), "knockback": 380.0, "heavy": true, "stagger": 0.8})
			rig.swoosh = 1.4
			Fx.effect("slash", global_position + Vector2(facing * 50, -60), 1.05, facing < 0, 0.4)
			Audio.sfx("heavy", 0.08, -2.0)
	elif hitbox.is_active():
		hitbox.deactivate()
	if u >= 1.0:
		_set_state(State.NORMAL)


# ------------------------------------------------------------------ DEFENCE

func _state_block(delta: float) -> void:
	_block_time += delta
	rig.play("block" if _block_time > parry_window else "parry")
	velocity.x = move_toward(velocity.x, 0.0, ground_decel * delta)
	_state_simple_physics(delta, -1.0)
	var x := _axis()
	if absf(x) > 0.5:
		facing = 1 if x > 0.0 else -1
	if not _held("block") or not is_on_floor():
		_set_state(State.NORMAL)
	elif _pressed("dodge"):
		_start_dodge()


func _start_dodge() -> void:
	if stamina < cost_dodge:
		Audio.sfx("tired", 0.0, -8.0)
		return
	_use_stamina(cost_dodge)
	_set_crouch(false)
	var x := _axis()
	var d := facing
	if absf(x) > 0.1:
		d = 1 if x > 0.0 else -1
	velocity.x = d * dodge_speed
	facing = d
	_set_state(State.DODGE)
	rig.play("dodge", true)
	Audio.sfx("dodge", 0.1, -5.0)
	Fx.dust(global_position, 6)


func _state_dodge(delta: float) -> void:
	rig.modulate.a = 0.6
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	_state_simple_physics(delta, -1.0)
	if _state_time >= dodge_time:
		_crit_window = 0.75
		_set_state(State.NORMAL)


func _state_hurt(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
	_state_simple_physics(delta, -1.0)
	if _state_time >= hurt_time:
		_set_state(State.NORMAL)


## Gravity + move only. target_vx < 0 keeps current velocity.x.
func _state_simple_physics(delta: float, target_vx: float) -> void:
	if target_vx >= 0.0:
		velocity.x = move_toward(velocity.x, target_vx, ground_decel * delta)
	_apply_gravity(delta)
	var was := is_on_floor()
	move_and_slide()
	_after_move(was)


# ------------------------------------------------------------------ DAMAGE

func is_invulnerable() -> bool:
	return _iframes > 0.0 or state == State.DODGE or state == State.DEAD or state == State.MOUNTED or state == State.LOCKED


func take_hit(info: Dictionary) -> void:
	if is_invulnerable():
		return
	var src: Node2D = info.get("source")
	var from_dir := -int(info.get("dir", 1.0))  # direction from me to attacker
	var dmg: float = info.get("damage", 10.0)
	if state == State.BLOCK and from_dir == facing and not info.get("unblockable", false):
		if _block_time <= parry_window:
			# timed parry: no damage, attacker staggered
			Audio.sfx("parry", 0.05, 0.0)
			Fx.spark(global_position + Vector2(facing * 22, -58), Color(1, 0.9, 0.5), 18)
			Fx.hitstop(0.09)
			CameraRig.shake_global(4.0)
			if src and src.has_method("on_parried"):
				src.on_parried()
			if parry_refund > 0.0:
				stamina = minf(max_stamina, stamina + parry_refund)
				stamina_changed.emit(stamina, max_stamina)
			return
		_use_stamina(cost_block_hit * block_cost_mult * (1.8 if info.get("heavy", false) else 1.0))
		Audio.sfx("block", 0.08, -2.0)
		Fx.spark(global_position + Vector2(facing * 20, -58), Color(1, 0.8, 0.4), 8)
		velocity.x = -facing * 140.0
		if stamina > 0.0:
			return
		dmg *= 0.5  # guard broken
	if health.damage(dmg):
		Audio.sfx("hurt", 0.1, -2.0)
		Fx.spark(global_position + Vector2(0, -55), Color(1, 1, 1), 6)
		CameraRig.shake_global(6.0)
		_iframes = iframes_after_hit
		if not health.is_dead():
			velocity = Vector2(-from_dir * float(info.get("knockback", 160.0)), -160.0)
			facing = from_dir
			_set_state(State.HURT)
			rig.play("hurt", true)


func fall_damage(amount: float) -> void:
	_iframes = 0.0
	health.damage(amount)


func _on_died() -> void:
	_set_crouch(false)
	_set_state(State.DEAD)
	rig.play("defeated", true)
	velocity.x = 0.0
	get_tree().create_timer(1.6).timeout.connect(func(): defeated.emit())


func revive_at(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	health.restore_full()
	stamina = max_stamina
	stamina_changed.emit(stamina, max_stamina)
	_iframes = 1.0
	_set_crouch(false)
	_set_state(State.NORMAL)
	rig.play("idle", true)


# ------------------------------------------------------------------ STAMINA

func _use_stamina(amount: float, reset_delay := true) -> void:
	stamina = maxf(0.0, stamina - amount)
	if reset_delay:
		_regen_wait = stamina_regen_delay
	stamina_changed.emit(stamina, max_stamina)


func _tick_stamina(delta: float) -> void:
	if _regen_wait > 0.0:
		_regen_wait -= delta
		return
	if stamina < max_stamina and not (state == State.NORMAL and _move_hold > run_after + sprint_after):
		stamina = minf(max_stamina, stamina + stamina_regen * delta * (1.6 if state == State.MOUNTED else 1.0))
		stamina_changed.emit(stamina, max_stamina)


# ------------------------------------------------------------------ INTERACTION / MOUNT

func _on_sensor_area_entered(a: Area2D) -> void:
	if a.is_in_group("ladder"):
		_ladders.append(a)
	if a.is_in_group("interactable") or a.get_parent().is_in_group("interactable"):
		_interactables.append(a)
	context_changed.emit()


func _on_sensor_area_exited(a: Area2D) -> void:
	_ladders.erase(a)
	_interactables.erase(a)
	context_changed.emit()


func _interact_target() -> Node:
	for a in _interactables:
		if not is_instance_valid(a):
			continue
		var t: Node = a if a.has_method("interact") else a.get_parent()
		if t.has_method("can_interact") and not t.can_interact(self):
			continue
		if t.has_method("interact"):
			return t
	return null


func get_context_prompt() -> String:
	if state == State.MOUNTED:
		return "Dismount" if horse and horse.can_dismount() else ""
	var t := _interact_target()
	if t and t.has_method("get_prompt"):
		return t.get_prompt()
	return ""


func near_ladder() -> bool:
	return state == State.CLIMB or _ladders.size() > 0


func _try_interact() -> void:
	var t := _interact_target()
	if t:
		rig.play("interact", true)
		t.interact(self)


func mount(h: Node) -> void:
	horse = h
	_set_crouch(false)
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	_set_state(State.MOUNTED)
	rig.play("mounted")
	z_index = 2
	Audio.sfx("mount", 0.05, -3.0)
	mounted_changed.emit(true, h)


func dismount(pos: Vector2) -> void:
	collision_layer = 2
	collision_mask = 1
	global_position = pos
	velocity = Vector2.ZERO
	z_index = 0
	var h := horse
	horse = null
	_set_state(State.NORMAL)
	rig.play("land", true)
	_land_timer = 0.15
	mounted_changed.emit(false, h)


func is_mounted() -> bool:
	return state == State.MOUNTED


func _state_mounted(_delta: float) -> void:
	if horse == null or not is_instance_valid(horse):
		dismount(global_position)
		return
	global_position = horse.rider_position()
	facing = horse.facing
	rig.speed_ratio = horse.speed_ratio()
	rig.play("mounted")
	if (_pressed("mount") or _pressed("interact")) and horse.can_dismount():
		horse.release_rider()


## Cutscene / victory lock.
func lock(anim_name := "idle") -> void:
	_set_crouch(false)
	if state == State.MOUNTED:
		input_enabled = false
		return
	_set_state(State.LOCKED)
	rig.play(anim_name, true)
	velocity.x = 0.0


func unlock() -> void:
	input_enabled = true
	if state == State.LOCKED:
		_set_state(State.NORMAL)


func state_name() -> String:
	return State.keys()[state]
