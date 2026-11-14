class_name TrainingDummy
extends CharacterBody2D
## PLACEHOLDER ART: straw training target on a wooden post. Wobbles when hit.

signal struck(dummy: TrainingDummy, heavy: bool)

var hits := 0
var _wobble := 0.0
var _wobble_v := 0.0


func _ready() -> void:
	collision_layer = 4   # hittable by player hitbox, not solid for player
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(34, 90)
	cs.shape = sh
	cs.position = Vector2(0, -45)
	add_child(cs)


func take_hit(info: Dictionary) -> void:
	hits += 1
	_wobble_v += 7.0 * float(info.get("dir", 1.0)) * (2.0 if info.get("heavy", false) else 1.0)
	Audio.sfx("dummy", 0.15, -2.0)
	Fx.dust(global_position + Vector2(0, -60), 6)
	struck.emit(self, info.get("heavy", false))


func _process(delta: float) -> void:
	_wobble_v += -_wobble * 60.0 * delta
	_wobble_v *= exp(-4.0 * delta)
	_wobble += _wobble_v * delta
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, _wobble * 0.15, Vector2.ONE)
	var wood := Color("6b4428")
	draw_rect(Rect2(-4, -100, 8, 100), wood)
	draw_rect(Rect2(-26, -78, 52, 7), wood)
	# straw body
	draw_colored_polygon(PackedVector2Array([Vector2(-16, -86), Vector2(16, -86), Vector2(19, -30), Vector2(-19, -30)]), Color("d8b56a"))
	for i in 5:
		draw_line(Vector2(-14 + i * 7, -84), Vector2(-16 + i * 8, -32), Color("b8914a"), 1.0)
	draw_line(Vector2(-18, -58), Vector2(18, -58), Color("7a2630"), 4.0)
	draw_circle(Vector2(0, -96), 11.0, Color("d8b56a"))
	draw_line(Vector2(-11, -100), Vector2(11, -100), Color("7a2630"), 3.0)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_rect(Rect2(-14, -4, 28, 4), wood.darkened(0.3))
