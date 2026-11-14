class_name CameraRig
extends Camera2D
## Cinematic side-scroll camera: smoothed follow, velocity look-ahead,
## vertical dead-zone, level limits, decaying screen shake and a wider
## framing preset for horseback sections.

static var current: CameraRig

@export var target_path: NodePath
@export var look_ahead := 110.0
@export var look_ahead_mounted := 260.0
@export var follow_speed := 6.0
@export var vertical_offset := -70.0

var target: Node2D
var _look := 0.0
var _shake := 0.0
@export var foot_zoom := 1.28
@export var mounted_zoom := 1.0
var _zoom_target := Vector2(1.28, 1.28)
var _focus_override: Node2D = null


func _ready() -> void:
	current = self
	if target_path:
		target = get_node_or_null(target_path)
	position_smoothing_enabled = false
	if target:
		global_position = target.global_position + Vector2(0, vertical_offset)
	zoom = _zoom_target
	make_current()


func _exit_tree() -> void:
	if current == self:
		current = null


static func shake_global(amount: float) -> void:
	if current:
		current._shake = maxf(current._shake, amount)


func set_mounted(m: bool) -> void:
	_zoom_target = Vector2.ONE * (mounted_zoom if m else foot_zoom)


func focus_on(node: Node2D) -> void:
	_focus_override = node


func set_level_limits(left: int, top: int, right: int, bottom: int) -> void:
	limit_left = left
	limit_top = top
	limit_right = right
	limit_bottom = bottom


func _process(delta: float) -> void:
	var t: Node2D = _focus_override if _focus_override else target
	if t == null or not is_instance_valid(t):
		return
	var vx := 0.0
	var mounted := false
	if t is CharacterBody2D:
		vx = (t as CharacterBody2D).velocity.x
	if t.has_method("is_mounted") and t.is_mounted():
		mounted = true
		if t.horse:
			vx = t.horse.velocity.x
	var la := look_ahead_mounted if mounted else look_ahead
	var desired_look := clampf(vx / 300.0, -1.0, 1.0) * la
	_look = lerpf(_look, desired_look, 1.0 - exp(-2.5 * delta))
	var goal := t.global_position + Vector2(_look, vertical_offset)
	var w := 1.0 - exp(-follow_speed * delta)
	global_position.x = lerpf(global_position.x, goal.x, w)
	# vertical: slower, avoids bobbing on every jump
	var wy := 1.0 - exp(-(follow_speed * 0.6) * delta)
	global_position.y = lerpf(global_position.y, goal.y, wy)
	zoom = zoom.lerp(_zoom_target, 1.0 - exp(-2.0 * delta))
	if _shake > 0.05:
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake
		_shake = lerpf(_shake, 0.0, 1.0 - exp(-10.0 * delta))
	else:
		offset = Vector2.ZERO
