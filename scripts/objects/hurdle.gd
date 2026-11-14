class_name Hurdle
extends StaticBody2D
## Horse-course obstacle: wooden fence, fallen log or stone barrier.

var size := Vector2(20, 52)
var style := "fence"  # fence | log | rocks


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	cs.position = Vector2(0, -size.y * 0.5)
	add_child(cs)


func _draw() -> void:
	var w := size.x
	var h := size.y
	match style:
		"fence":
			var wood := Color("7a5030")
			draw_rect(Rect2(-w * 0.5 - 14, -h, 6, h), wood)
			draw_rect(Rect2(w * 0.5 + 8, -h, 6, h), wood)
			for i in 3:
				draw_line(Vector2(-w * 0.5 - 18, -h + 8 + i * 15), Vector2(w * 0.5 + 18, -h + 4 + i * 15), wood.lightened(0.12), 5.0)
			# saffron flags mark the jump point
			draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.5 - 11, -h - 18), Vector2(-w * 0.5 + 4, -h - 13), Vector2(-w * 0.5 - 11, -h - 8)]), Game.C_SAFFRON)
			draw_line(Vector2(-w * 0.5 - 11, -h - 18), Vector2(-w * 0.5 - 11, -h), Color("3a2418"), 2.0)
		"log":
			var bark := Color("5e3d24")
			draw_rect(Rect2(-w * 0.5, -h, w, h), bark)
			draw_circle(Vector2(w * 0.5, -h * 0.5), h * 0.5, bark.lightened(0.2))
			draw_arc(Vector2(w * 0.5, -h * 0.5), h * 0.3, 0, TAU, 16, bark.darkened(0.2), 1.5)
			draw_line(Vector2(-w * 0.3, -h), Vector2(-w * 0.45, -h - 16), bark, 4.0)
		"cart":
			var wood := Color("6b4428")
			draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.5, -h * 0.4), Vector2(w * 0.5, -h), Vector2(w * 0.5, -h * 0.75), Vector2(-w * 0.5, -h * 0.15)]), wood)
			draw_circle(Vector2(-w * 0.25, -h * 0.3), h * 0.3, wood.darkened(0.2))
			draw_arc(Vector2(-w * 0.25, -h * 0.3), h * 0.3, 0, TAU, 12, wood.darkened(0.5), 2.0)
			draw_line(Vector2(w * 0.2, -h * 0.8), Vector2(w * 0.6, 0), wood.lightened(0.1), 4.0)
		_:
			var rt := MewarAssets.prop("rock")
			if rt:
				draw_texture_rect(rt, Rect2(-w * 0.9, -h * 1.55, w * 1.8, h * 1.8), false)
				return
			draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(-w * 0.4, -h * 0.8), Vector2(0, -h), Vector2(w * 0.45, -h * 0.7), Vector2(w * 0.5, 0)]), Color("9a8064"))
