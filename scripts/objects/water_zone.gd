class_name WaterZone
extends Area2D
## Shallow stream. Slows Chetak (and Pratap on foot) and splashes.

var size := Vector2(300, 40)
var slow := 0.6
var _t := 0.0
var _inside := []


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 | 8
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	cs.position = size * 0.5
	add_child(cs)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	z_index = 3


func _on_enter(b: Node) -> void:
	if b is Horse:
		(b as Horse).terrain_speed_mult = slow
	_inside.append(b)
	Audio.sfx("splash", 0.1, -4.0)


func _on_exit(b: Node) -> void:
	if b is Horse:
		(b as Horse).terrain_speed_mult = 1.0
	_inside.erase(b)


func _physics_process(_d: float) -> void:
	for b in _inside:
		if is_instance_valid(b) and b is Player and not b.is_mounted():
			b.velocity.x *= 0.93
		if is_instance_valid(b) and absf(b.velocity.x) > 120.0 and randf() < 0.3:
			Fx.spark(b.global_position + Vector2(randf_range(-30, 30), -6), Color(0.75, 0.88, 1.0, 0.9), 3)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2(0, 6), size - Vector2(0, 6)), Color(0.35, 0.55, 0.65, 0.55))
	var x := 0.0
	while x < size.x:
		var y := 6.0 + sin(_t * 3.0 + x * 0.05) * 2.0
		draw_line(Vector2(x, y), Vector2(x + 18, y), Color(0.85, 0.95, 1.0, 0.6), 2.0)
		x += 30.0
