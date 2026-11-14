class_name Horse
extends CharacterBody2D
## Chetak - dedicated mounted controller (separate from the player controller).
## Hold a direction to trot, hold Gallop to gallop (drains stamina), tap Jump.
## Hitting a wall/obstacle at speed causes a short, non-graphic stumble
## (rear-up, lose momentum and some stamina) - never a fall or injury.

signal stamina_changed(current: float, maximum: float)
signal stumbled

enum S { IDLE, RIDDEN, STUMBLE }

@export var walk_speed := 150.0
@export var trot_speed := 310.0
@export var gallop_speed := 560.0
@export var accel := 620.0
@export var gallop_accel := 820.0
@export var decel := 900.0
@export var turn_speed_limit := 140.0   ## must slow below this to turn around
@export var jump_velocity := -740.0
@export var gravity := 2000.0
@export var fall_mult := 1.25
@export var coyote_time := 0.14
@export var jump_buffer := 0.16
@export var max_stamina := 100.0
@export var gallop_drain := 15.0
@export var stamina_regen := 24.0
@export var exhausted_recover := 35.0
@export var stumble_speed := 300.0
@export var allow_dismount := true

var state: S = S.IDLE
var facing := 1
var rider: Player = null
var stamina := 100.0
var exhausted := false
var input_enabled := true
var _coyote := 0.0
var _buffer := 0.0
var _t := 0.0
var _air := 0.0
var _greeted := false
var terrain_speed_mult := 1.0   ## set by water zones (streams slow Chetak)
var auto_dir := 0               ## cinematic control: -1/0/1 overrides input
var auto_speed := 0.0
var resting := false
var horse_name := "Chetak"

@onready var rig: HorseRig = $Rig
@onready var mount_zone: Area2D = $MountZone


func _ready() -> void:
	add_to_group("horse")
	add_to_group("interactable")
	collision_layer = 8
	collision_mask = 1
	floor_snap_length = 14.0
	floor_max_angle = deg_to_rad(50)
	mount_zone.collision_layer = 32
	mount_zone.collision_mask = 2
	mount_zone.body_entered.connect(_on_zone_body_entered)
	stamina = max_stamina


# ---------------------------------------------------------- interaction API

func get_prompt() -> String:
	return "Mount " + horse_name


func can_interact(p: Node) -> bool:
	return rider == null and state == S.IDLE and not resting and p.is_on_floor()


func interact(p: Node) -> void:
	if can_interact(p):
		mount_rider(p)


func mount_rider(p: Player) -> void:
	rider = p
	state = S.RIDDEN
	facing = p.facing
	p.mount(self)
	rig.play("idle")
	Audio.sfx("neigh", 0.05, -4.0)
	if CameraRig.current:
		CameraRig.current.set_mounted(true)


func can_dismount() -> bool:
	return allow_dismount and is_on_floor() and absf(velocity.x) < 160.0 and state == S.RIDDEN


func release_rider() -> void:
	if rider == null:
		return
	var p := rider
	rider = null
	state = S.IDLE
	var spot := global_position + Vector2(-facing * 46.0, -2.0)
	p.dismount(spot)
	if CameraRig.current:
		CameraRig.current.set_mounted(false)


func rider_position() -> Vector2:
	var sp := rig.saddle_point()
	return global_position + Vector2(sp.x * facing, sp.y + rig.rider_drop())


func speed_ratio() -> float:
	return clampf(absf(velocity.x) / gallop_speed, 0.0, 1.0)


func is_mounted() -> bool:
	return rider != null


# ---------------------------------------------------------- physics

func _physics_process(delta: float) -> void:
	_t += delta
	var on_floor := is_on_floor()
	_coyote = coyote_time if on_floor else maxf(0.0, _coyote - delta)
	var ridden := state == S.RIDDEN and input_enabled
	if ridden and Input.is_action_just_pressed("jump"):
		_buffer = jump_buffer
	else:
		_buffer = maxf(0.0, _buffer - delta)

	var galloping := false
	match state:
		S.IDLE:
			velocity.x = move_toward(velocity.x, 0.0, decel * delta)
			if not resting:
				_idle_personality()
		S.RIDDEN:
			var x := Input.get_axis("move_left", "move_right") if input_enabled else 0.0
			var want_gallop := input_enabled and Input.is_action_pressed("gallop") and not exhausted
			if auto_dir != 0:
				x = float(auto_dir)
				want_gallop = false
			if absf(x) > 0.2:
				var d := 1 if x > 0.0 else -1
				if d != facing:
					# turning: brake first, then pivot (prevents snap reversals)
					velocity.x = move_toward(velocity.x, 0.0, decel * 1.5 * delta)
					if absf(velocity.x) < turn_speed_limit:
						facing = d
				else:
					var target := (gallop_speed if want_gallop else trot_speed) * terrain_speed_mult
					if auto_dir != 0:
						target = auto_speed
					galloping = want_gallop
					var a := gallop_accel if want_gallop else accel
					if absf(velocity.x) > target:
						a = decel * 0.6
					velocity.x = move_toward(velocity.x, d * target, a * delta)
			else:
				velocity.x = move_toward(velocity.x, 0.0, decel * delta)
			if _buffer > 0.0 and _coyote > 0.0:
				velocity.y = jump_velocity
				_buffer = 0.0
				_coyote = 0.0
				Audio.sfx("horse_jump", 0.05, -3.0)
				Fx.dust(global_position, 10)
		S.STUMBLE:
			velocity.x = move_toward(velocity.x, 0.0, decel * delta)
			if _t > 0.55:
				state = S.RIDDEN if rider else S.IDLE

	_tick_stamina(delta, galloping)
	var g := gravity * (fall_mult if velocity.y > 0.0 else 1.0)
	velocity.y = minf(velocity.y + g * delta, 1300.0)
	var pre_vx := velocity.x
	move_and_slide()
	if not is_on_floor():
		_air += delta
	else:
		if _air > 0.18:
			Audio.sfx("hoof_land", 0.08, -3.0)
			Fx.dust(global_position, 12)
			CameraRig.shake_global(2.0)
		_air = 0.0
	# obstacle collision at speed -> stumble (non-graphic)
	if state == S.RIDDEN and is_on_wall() and absf(pre_vx) > stumble_speed:
		_stumble(pre_vx)
	_update_anim()
	rig.scale.x = facing


## External obstacle hit (falling stone, low branch, arrow volley). Non-graphic.
func hit_obstacle(from_dir := 0.0) -> void:
	if state == S.STUMBLE or rider == null:
		return
	_stumble(velocity.x if from_dir == 0.0 else -from_dir * 400.0)


func _stumble(pre_vx: float) -> void:
	state = S.STUMBLE
	_t = 0.0
	velocity.x = -signf(pre_vx) * 160.0
	velocity.y = -220.0
	stamina = maxf(0.0, stamina - 15.0)
	stamina_changed.emit(stamina, max_stamina)
	rig.play("rear")
	Audio.sfx("neigh", 0.1, -2.0)
	CameraRig.shake_global(7.0)
	stumbled.emit()


func _tick_stamina(delta: float, galloping: bool) -> void:
	var before := stamina
	if galloping and absf(velocity.x) > trot_speed:
		stamina = maxf(0.0, stamina - gallop_drain * delta)
		if stamina <= 0.0:
			exhausted = true
			Audio.sfx("snort", 0.05, -4.0)
	else:
		stamina = minf(max_stamina, stamina + stamina_regen * delta)
	if exhausted and stamina >= exhausted_recover:
		exhausted = false
	if before != stamina:
		stamina_changed.emit(stamina, max_stamina)


func _update_anim() -> void:
	var sp := absf(velocity.x)
	rig.speed_ratio = speed_ratio()
	if resting:
		rig.play("rest")
	elif state == S.STUMBLE:
		rig.play("rear")
	elif not is_on_floor() and _air > 0.06:
		rig.play("jump" if velocity.y < 0.0 else "fall")
	elif sp > trot_speed + 30.0:
		rig.play("gallop")
	elif sp > walk_speed + 20.0:
		rig.play("trot")
	elif sp > 12.0:
		rig.play("walk")
	else:
		rig.play("idle" if rider or not _greeted else "settled")


## Chetak turns his head toward Pratap when he's close - small personality beat.
func _idle_personality() -> void:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return
	var dx := p.global_position.x - global_position.x
	rig.head_look = clampf(dx / 200.0, -1.0, 1.0) * float(facing)


func _on_zone_body_entered(b: Node) -> void:
	if b is Player and not _greeted and rider == null:
		_greeted = true
		Audio.sfx("neigh", 0.05, -8.0)


## Respawn helper for checkpoints.
func reset_to(pos: Vector2, dir := 1) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	facing = dir
	state = S.RIDDEN if rider else S.IDLE
	stamina = max_stamina
	exhausted = false
	terrain_speed_mult = 1.0
	stamina_changed.emit(stamina, max_stamina)
