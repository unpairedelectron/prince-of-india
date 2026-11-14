class_name MovingPlatform
extends AnimatableBody2D
## Drifting raft / war-boat deck / builders' lift. Glides back and forth along
## `travel` and carries whoever stands on it. Position = top-left of the deck.

var size := Vector2(120, 20)
var travel := Vector2(150, 0)
var period := 3.6
var phase := 0.0          ## 0..1 offset in the cycle
var style := "raft"       ## raft | boat | lift
var _home := Vector2.ZERO
var _t := 0.0


func _ready() -> void:
	add_to_group("mover")
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	_home = position
	_t = phase * period
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	cs.position = size * 0.5
	add_child(cs)
	position = _home + travel * offset_at(_t)


## 0..1 position along the travel line (eases at both ends, so it lingers there).
func offset_at(t: float) -> float:
	return 0.5 - 0.5 * cos(TAU * t / period)


func vel_x() -> float:
	return travel.x * 0.5 * sin(TAU * _t / period) * TAU / period


func _physics_process(delta: float) -> void:
	_t += delta
	position = _home + travel * offset_at(_t)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	match style:
		"boat":
			var hull := Color("5a3a22")
			draw_colored_polygon(PackedVector2Array([Vector2(-26, 2), Vector2(w + 26, 2), Vector2(w + 6, 44), Vector2(-6, 44)]), hull)
			draw_line(Vector2(-26, 2), Vector2(-40, -18), hull.lightened(0.1), 6.0)
			draw_line(Vector2(w + 26, 2), Vector2(w + 40, -18), hull.lightened(0.1), 6.0)
			draw_rect(Rect2(0, 0, w, 8), Color("9a6a3a"))
			draw_line(Vector2(-20, 22), Vector2(w + 20, 22), Color("c9a14a"), 2.0)
		"lift":
			var wood := Color("7a5030")
			draw_rect(Rect2(0, 0, w, 14), wood)
			draw_line(Vector2(4, 4), Vector2(w - 4, 4), wood.lightened(0.15), 1.5)
			for x in [8.0, w - 8.0]:
				draw_line(Vector2(x, 0), Vector2(x, -420), Color("c9a86a", 0.8), 2.0)
			for i in 4:
				draw_line(Vector2(6 + i * (w - 12) / 3.0, 14), Vector2(6 + i * (w - 12) / 3.0, 20), wood.darkened(0.3), 3.0)
		_:
			var bamboo := Color("b89a4a")
			var x := 0.0
			var i := 0
			while x < w:
				draw_rect(Rect2(x, 0, minf(14.0, w - x) - 1.0, 16), bamboo.darkened(0.08 * (i % 3)))
				x += 14.0
				i += 1
			draw_line(Vector2(0, 5), Vector2(w, 5), Color("6b4428"), 2.0)
			draw_line(Vector2(0, 12), Vector2(w, 12), Color("6b4428"), 2.0)
