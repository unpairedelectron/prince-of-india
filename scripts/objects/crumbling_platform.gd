class_name CrumblingPlatform
extends AnimatableBody2D
## Damaged stone slab or rope-bridge plank: shakes when stood on (by Pratap or
## Chetak), falls, then reforms. style: "stone" | "bridge".

var size := Vector2(100, 18)
var delay := 0.55
var respawn := 3.0
var style := "stone"
var _home := Vector2.ZERO
var _timer := -1.0
var _down := false
var _shape: CollisionShape2D
var _detector: Area2D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = false
	_home = position
	_shape = CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	_shape.shape = sh
	_shape.position = Vector2(size.x * 0.5, size.y * 0.5)
	_shape.one_way_collision = true
	add_child(_shape)
	_detector = Area2D.new()
	_detector.collision_layer = 0
	_detector.collision_mask = 2 | 8
	var dcs := CollisionShape2D.new()
	var dsh := RectangleShape2D.new()
	dsh.size = Vector2(size.x - 4, 12)
	dcs.shape = dsh
	dcs.position = Vector2(size.x * 0.5, -6)
	_detector.add_child(dcs)
	add_child(_detector)


func _physics_process(delta: float) -> void:
	if _down:
		return
	if _timer < 0.0:
		for b in _detector.get_overlapping_bodies():
			if (b is Player or b is Horse) and b.is_on_floor():
				_timer = delay
				Audio.sfx("crumble", 0.1, -6.0)
	else:
		_timer -= delta
		if _timer <= 0.0:
			_fall()
	queue_redraw()


func _fall() -> void:
	_down = true
	_shape.set_deferred("disabled", true)
	Fx.dust(global_position + Vector2(size.x * 0.5, 10), 10)
	var tw := create_tween()
	tw.tween_property(self, "position:y", _home.y + 500.0, 0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.7)
	tw.tween_interval(respawn)
	tw.tween_callback(_restore)


func _restore() -> void:
	position = _home
	_timer = -1.0
	_down = false
	_shape.set_deferred("disabled", false)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.4)


func reset() -> void:
	if _down:
		position = _home
		modulate.a = 1.0
		_down = false
		_shape.set_deferred("disabled", false)
	_timer = -1.0


func _draw() -> void:
	var shake := Vector2(randf_range(-2, 2), 0) if _timer > 0.0 else Vector2.ZERO
	if style == "bridge":
		var wood := Color("8a5a32")
		draw_rect(Rect2(shake, size), wood)
		var x := 0.0
		while x < size.x:
			draw_line(shake + Vector2(x, 0), shake + Vector2(x, size.y), wood.darkened(0.35), 1.5)
			x += 14.0
		draw_line(shake + Vector2(0, -26), shake + Vector2(size.x, -24), Color("c9a86a"), 2.0)
		return
	var c := Game.C_SANDSTONE
	draw_rect(Rect2(shake, size), c)
	draw_rect(Rect2(shake + Vector2(0, size.y - 4), Vector2(size.x, 4)), c.darkened(0.3))
	draw_polyline(PackedVector2Array([shake + Vector2(20, 0), shake + Vector2(28, 8), shake + Vector2(24, 16)]), c.darkened(0.45), 1.5)
	draw_polyline(PackedVector2Array([shake + Vector2(70, 0), shake + Vector2(62, 9), shake + Vector2(72, 17)]), c.darkened(0.45), 1.5)
