class_name FallingStones
extends Node2D
## Telegraphed drops from above: loose masonry ("stones") or arrow volleys
## ("arrows"). A growing ground shadow warns first. Fixed drop points, or
## follow mode that aims just ahead of the player (or Chetak) - still with warning.
## Hitting Pratap on foot costs a little health; hitting Chetak causes a stumble.

var drop_points: Array = []   # local x offsets (fixed mode)
var surface_y := 0.0          # local y of the walkway
var period := 2.2
var warn_time := 0.8
var damage := 12.0
var style := "stones"
var radius := 34.0
var follow := false           ## aim ahead of the player instead of fixed points
var active := true
var x_range := Vector2(-INF, INF)   ## follow mode only fires inside this global x range
var _t := 0.0
var _idx := 0
var _warn := {}   # local x -> time left
var _drops := [] # [x, y, vy]


func _process(delta: float) -> void:
	if not active:
		_warn.clear()
		queue_redraw()
		return
	_t += delta
	if _t >= period:
		_t = 0.0
		if follow:
			var p := _target()
			if p and p.global_position.x > x_range.x and p.global_position.x < x_range.y:
				var vx: float = p.horse.velocity.x if (p is Player and p.horse) else p.velocity.x
				var gx: float = p.global_position.x + vx * warn_time * randf_range(0.7, 1.1)
				_warn[to_local(Vector2(gx, 0)).x] = warn_time
		elif drop_points.size() > 0:
			_warn[drop_points[_idx]] = warn_time
			_idx = (_idx + 1) % drop_points.size()
	for x in _warn.keys():
		_warn[x] -= delta
		if _warn[x] <= 0.0:
			_warn.erase(x)
			_drops.append([x, surface_y - 420.0, 0.0])
	var keep := []
	for s in _drops:
		s[2] += 1800.0 * delta
		s[1] += s[2] * delta
		if s[1] >= surface_y - 12.0:
			_impact(s[0])
		else:
			keep.append(s)
	_drops = keep
	queue_redraw()


func _target() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


func _impact(x: float) -> void:
	var pos := to_global(Vector2(x, surface_y))
	Fx.dust(pos, 5 if style == "arrows" else 10)
	Audio.sfx({"stones": "stone", "shells": "cannon"}.get(style, "arrow_volley"), 0.15, -4.0)
	CameraRig.shake_global({"stones": 2.0, "shells": 5.0}.get(style, 1.0))
	if style == "shells":
		Fx.spark(pos + Vector2(0, -10), Color(1.0, 0.6, 0.2), 22)
	for h in get_tree().get_nodes_in_group("horse"):
		if h is Horse and h.rider and absf(h.global_position.x - pos.x) < radius + 40.0 and absf(h.global_position.y - pos.y) < 60.0:
			h.hit_obstacle()
	for p in get_tree().get_nodes_in_group("player"):
		if p is Player and not p.is_mounted() and absf(p.global_position.x - pos.x) < radius and absf(p.global_position.y - pos.y) < 40.0:
			var d := signf(p.global_position.x - pos.x)
			p.take_hit({"damage": damage, "dir": d if d != 0.0 else 1.0, "knockback": 150.0, "unblockable": true, "source": self})


func _draw() -> void:
	for x in _warn:
		var k: float = 1.0 - _warn[x] / warn_time
		draw_set_transform(Vector2(x, surface_y), 0, Vector2(1, 0.3))
		draw_circle(Vector2.ZERO, radius * 0.3 + radius * 0.6 * k, Color(0, 0, 0, 0.15 + 0.35 * k))
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		if style != "stones":
			draw_arc(Vector2(x, surface_y - 4), radius * (1.2 - 0.4 * k), PI, TAU, 16, Color(1, 0.35, 0.2, 0.5 + 0.5 * k), 2.0)
	for s in _drops:
		if style == "arrows":
			for i in 6:
				var o := Vector2((i - 2.5) * radius * 0.35, -(i % 3) * 18.0)
				var p: Vector2 = Vector2(s[0], s[1]) + o
				draw_line(p + Vector2(-8, -22), p, Color("6b4428"), 2.0)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-2, -2), p + Vector2(2, 2), p + Vector2(1, -4)]), Color("b8bec6"))
		elif style == "shells":
			draw_line(Vector2(s[0], s[1] - 60), Vector2(s[0], s[1]), Color(1, 0.7, 0.3, 0.5), 5.0)
			draw_circle(Vector2(s[0], s[1]), 9.0, Color("26262a"))
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(s[0] - 12, s[1] - 8), Vector2(s[0] + 10, s[1] - 12), Vector2(s[0] + 14, s[1] + 6), Vector2(s[0] - 6, s[1] + 12), Vector2(s[0] - 14, s[1] + 4)]), Game.C_SANDSTONE_DARK)
