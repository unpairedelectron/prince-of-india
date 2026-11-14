class_name LowBranch
extends Node2D
## Low tree branch across the riding path. Ride under it on the ground;
## jumping into it makes Chetak stumble. Position = ground at the trunk.

var span := 160.0     ## branch length to the right of the trunk
var clearance := 26.0 ## how high Chetak may be (px above ground) and still pass
var _cooldown := 0.0


func _physics_process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	if _cooldown > 0.0:
		return
	for h in get_tree().get_nodes_in_group("horse"):
		if h is Horse and h.rider:
			var lx: float = h.global_position.x - global_position.x
			var airborne: float = global_position.y - h.global_position.y
			if lx > 20.0 and lx < span + 40.0 and airborne > clearance:
				_cooldown = 1.0
				Audio.sfx("branch", 0.1, -3.0)
				Fx.dust(global_position + Vector2(lx, -170), 8)
				h.hit_obstacle()


func _draw() -> void:
	var bark := Color("4e3624")
	draw_rect(Rect2(-16, -320, 32, 320), bark)
	draw_line(Vector2(0, -170), Vector2(span, -150), bark, 12.0)
	draw_line(Vector2(span * 0.5, -160), Vector2(span * 0.75, -200), bark, 6.0)
	for i in 6:
		var p := Vector2(span * (0.35 + i * 0.12), -150 - (i % 2) * 14.0)
		draw_circle(p, 18.0, Color("6f7f3e"))
	draw_circle(Vector2(0, -330), 70.0, Color("5f6f36"))
	draw_circle(Vector2(-40, -300), 50.0, Color("6f7f3e"))
	draw_circle(Vector2(40, -300), 54.0, Color("66763a"))
