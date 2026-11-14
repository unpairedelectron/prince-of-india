class_name Hitbox
extends Area2D
## Attack hitbox, switched on only during an attack's active frames.
## Each activation tracks which bodies were already hit, so one swing can
## never register twice on the same target.

var owner_actor: Node2D
var _active := false
var _hit_list: Array = []
var _info := {}


func setup(actor: Node2D, size: Vector2, offset: Vector2, mask: int) -> void:
	owner_actor = actor
	collision_layer = 0
	collision_mask = mask
	monitoring = true
	monitorable = false
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	cs.shape = shape
	cs.position = offset
	add_child(cs)


## info keys: damage (float), knockback (float), heavy (bool), stagger (float)
func activate(info: Dictionary) -> void:
	_info = info
	_hit_list.clear()
	_active = true


func deactivate() -> void:
	_active = false


func is_active() -> bool:
	return _active


func _physics_process(_delta: float) -> void:
	if not _active:
		return
	for body in get_overlapping_bodies():
		if body == owner_actor or body in _hit_list:
			continue
		if body.has_method("take_hit"):
			_hit_list.append(body)
			var info := _info.duplicate()
			info["source"] = owner_actor
			info["dir"] = signf(body.global_position.x - owner_actor.global_position.x)
			if info.dir == 0.0:
				info.dir = 1.0
			body.take_hit(info)
