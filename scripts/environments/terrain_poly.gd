class_name TerrainPoly
extends StaticBody2D
## Sloped ground (hills, descents). points = surface line left->right;
## the polygon is closed down to `bottom`. PLACEHOLDER ART.

var points: PackedVector2Array
var bottom := 600.0
var color := Color("b8864e")
var top_color := Color("c89a5c")


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cp := CollisionPolygon2D.new()
	cp.polygon = _poly()
	add_child(cp)


func _poly() -> PackedVector2Array:
	var poly := PackedVector2Array(points)
	poly.append(Vector2(points[points.size() - 1].x, bottom))
	poly.append(Vector2(points[0].x, bottom))
	return poly


func _draw() -> void:
	draw_colored_polygon(_poly(), color)
	draw_polyline(points, top_color, 10.0)
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var x := a.x
		while x < b.x:
			var y := lerpf(a.y, b.y, (x - a.x) / (b.x - a.x))
			draw_line(Vector2(x, y), Vector2(x - 3, y - 9), Color("a99a4a"), 2.0)
			x += 26.0
