class_name TerrainBlock
extends StaticBody2D
## Solid level geometry with procedural Rajasthani surface art.
## style: fort (dressed sandstone + kangura merlons), ground (ochre earth +
## dry grass), plank (one-way wooden beam), paving (courtyard flagstones).
## PLACEHOLDER ART.

var rect := Rect2(0, 0, 100, 100)
var style := "ground"
var merlons := false
var one_way := false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = rect.size
	cs.shape = sh
	cs.position = rect.position + rect.size * 0.5
	cs.one_way_collision = one_way or style == "plank"
	add_child(cs)


## Draws a 64x64 asset-pack tile repeatedly over a rect (partial tiles clipped).
func _tile_fill(r: Rect2, names: Array, rng: RandomNumberGenerator) -> bool:
	var first := MewarAssets.tile(names[0])
	if first == null:
		return false
	var y := r.position.y
	while y < r.end.y:
		var x := r.position.x
		var h := minf(64.0, r.end.y - y)
		while x < r.end.x:
			var w := minf(64.0, r.end.x - x)
			var t: AtlasTexture = MewarAssets.tile(names[rng.randi() % names.size()])
			draw_texture_rect_region(t.atlas, Rect2(x, y, w, h), Rect2(t.region.position, Vector2(w, h)))
			x += 64.0
		y += 64.0
	return true


func _draw() -> void:
	var r := rect
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x * 13.0 + r.position.y * 7.0)
	match style:
		"fort", "paving":
			var base := Game.C_SANDSTONE if style == "fort" else Color("d9b07a")
			# Asset-pack fort tiles (64x64). Falls back to procedural courses if missing.
			var names := ["sandstone_wall", "sandstone_wall", "fort_masonry"] if style == "fort" else ["sandstone_floor", "sandstone_brick"]
			if _tile_fill(r, names, rng):
				draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 5), base.lightened(0.2))
				var dpt := minf(r.size.y, 400.0)
				for i in 6:
					draw_rect(Rect2(r.position.x, r.position.y + dpt * (0.4 + i * 0.1), r.size.x, dpt * 0.1), Color(0.15, 0.08, 0.04, 0.05 + i * 0.03))
				if merlons:
					var mx0 := r.position.x + 6.0
					while mx0 + 18.0 <= r.end.x:
						var p0 := Vector2(mx0, r.position.y)
						draw_colored_polygon(PackedVector2Array([p0, p0 + Vector2(18, 0), p0 + Vector2(18, -14), p0 + Vector2(9, -24), p0 + Vector2(0, -14)]), base.darkened(0.05))
						mx0 += 34.0
				return
			draw_rect(r, base.darkened(0.08))
			var course := 22.0
			var y := r.position.y
			var row := 0
			while y < r.end.y:
				var off := 0.0 if row % 2 == 0 else 26.0
				var x := r.position.x - off
				while x < r.end.x:
					var w := 52.0
					var bx := maxf(x, r.position.x)
					var bw := minf(x + w, r.end.x) - bx
					if bw > 2:
						var shade := rng.randf_range(-0.06, 0.06)
						draw_rect(Rect2(bx + 1, y + 1, bw - 2, minf(course, r.end.y - y) - 2), base.lightened(shade) if shade > 0 else base.darkened(-shade))
					x += w
				y += course
				row += 1
			# top lip
			draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 6), base.lightened(0.15))
			# depth shading toward the bottom
			var depth := minf(r.size.y, 400.0)
			for i in 6:
				draw_rect(Rect2(r.position.x, r.position.y + depth * (0.4 + i * 0.1), r.size.x, depth * 0.1), Color(0.15, 0.08, 0.04, 0.06 + i * 0.03))
			if merlons:
				var mx := r.position.x + 6.0
				while mx + 18.0 <= r.end.x:
					var p := Vector2(mx, r.position.y)
					draw_colored_polygon(PackedVector2Array([p, p + Vector2(18, 0), p + Vector2(18, -14), p + Vector2(9, -24), p + Vector2(0, -14)]), base.darkened(0.05))
					mx += 34.0
		"plank":
			var wood := Color("7a5030")
			draw_rect(r, wood)
			draw_line(r.position + Vector2(0, r.size.y - 2), r.position + Vector2(r.size.x, r.size.y - 2), wood.darkened(0.35), 3.0)
			draw_line(r.position + Vector2(4, 4), r.position + Vector2(r.size.x - 4, 4), wood.lightened(0.15), 1.5)
			# support struts
			draw_line(r.position + Vector2(8, r.size.y), r.position + Vector2(-4, r.size.y + 40), wood.darkened(0.2), 4.0)
			draw_line(r.end - Vector2(8, 0), r.end + Vector2(4, 40), wood.darkened(0.2), 4.0)
		"rock":
			var rc := Color("b8904a")
			draw_rect(r, rc)
			draw_rect(Rect2(r.position, Vector2(r.size.x, 6)), rc.lightened(0.15))
			for i in int(r.size.x * r.size.y / 6000.0) + 2:
				var px := r.position.x + rng.randf_range(4, r.size.x - 4)
				var py := r.position.y + rng.randf_range(8, minf(r.size.y, 300))
				draw_line(Vector2(px, py), Vector2(px + rng.randf_range(-14, 14), py + rng.randf_range(6, 20)), rc.darkened(0.25), 2.0)
			draw_rect(Rect2(r.position.x, r.end.y - 8, r.size.x, 8), Color(0, 0, 0, 0.12))
		"deck":
			# war-boat deck: planking over a dark hull (the river is drawn over the lower hull)
			var hull := Color("4a2f1c")
			draw_rect(r, hull)
			draw_rect(Rect2(r.position, Vector2(r.size.x, 12)), Color("9a6a3a"))
			var px0 := r.position.x
			while px0 < r.end.x:
				draw_line(Vector2(px0, r.position.y), Vector2(px0, r.position.y + 12), Color("6b4428"), 1.5)
				px0 += 38.0
			draw_line(Vector2(r.position.x, r.position.y + 26), Vector2(r.end.x, r.position.y + 26), Color("c9a14a"), 2.0)
			for i in int(r.size.x / 120.0):
				draw_circle(Vector2(r.position.x + 60 + i * 120, r.position.y + 36), 7.0, Color("7a5030"))
		_:
			var cols: Array = {
				"ochre": [Color("cf9c3c"), Color("e2b552"), Color("a99a4a"), Color("c9b067")],
				"basalt": [Color("4e4a4c"), Color("5f8a4a"), Color("5a9a48"), Color("8fb860")],
				"grass": [Color("7a5a3a"), Color("5a9a48"), Color("4f9a44"), Color("9ad06a")],
			}.get(style, [Color("b8864e"), Color("c89a5c"), Color("a99a4a"), Color("c9b067")])
			var earth: Color = cols[0]
			draw_rect(r, earth)
			draw_rect(Rect2(r.position, Vector2(r.size.x, 10)), cols[1])
			for i in int(r.size.x / 40.0):
				var px := r.position.x + rng.randf_range(0, r.size.x)
				var py := r.position.y + rng.randf_range(18, minf(r.size.y, 200))
				draw_circle(Vector2(px, py), rng.randf_range(2, 6), earth.darkened(rng.randf_range(0.05, 0.2)))
			var gx := r.position.x
			while gx < r.end.x:
				var gh := rng.randf_range(5, 14)
				var gc: Color = (cols[2] as Color).lerp(cols[3], rng.randf())
				draw_line(Vector2(gx, r.position.y + 2), Vector2(gx - 3, r.position.y - gh), gc, 2.0)
				draw_line(Vector2(gx + 3, r.position.y + 2), Vector2(gx + 6, r.position.y - gh * 0.7), gc, 2.0)
				gx += rng.randf_range(14, 40)
			var depth2 := minf(r.size.y, 400.0)
			for i in 6:
				draw_rect(Rect2(r.position.x, r.position.y + depth2 * (0.4 + i * 0.1), r.size.x, depth2 * 0.1), Color(0.15, 0.08, 0.04, 0.06 + i * 0.03))
