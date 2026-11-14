class_name Backdrop
extends Node2D
## PLACEHOLDER ART: procedural parallax layer content for Mewar landscapes.
## kinds: far_hills (Aravalli ridges), near_hills (ridges + hill-fort wall),
## town (Gogunda: havelis, chhatris, temple shikhara), foreground (grass, khejri).

var kind := "far_hills"
var width := 6000.0
var base_y := 0.0
var seed_value := 1
var tint := Color.WHITE
var _t := 0.0


func _process(delta: float) -> void:
	if kind in ["troops", "river", "fleet"]:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	match kind:
		"far_hills": _ridge(rng, 260.0, 120.0, Color("b9a08a"), 0.004)
		"mid_hills":
			_ridge(rng, 200.0, 90.0, Color("a08060"), 0.007)
		"near_hills":
			_ridge(rng, 150.0, 80.0, Color("8a6a48"), 0.01)
			_hill_fort_wall(rng)
		"town": _town(rng)
		"foreground": _foreground(rng)
		"troops": _troops(rng)
		"forest": _forest(rng)
		"rocks": _rocks(rng)
		"ghats": _ghats(rng)
		"river": _river(rng)
		"fortline": _fortline(rng)
		"fleet": _fleet(rng)


## Sahyadri: stepped, flat-topped basalt mesas, some crowned with a fort wall.
func _ghats(rng: RandomNumberGenerator) -> void:
	var col := Color("7f9a8e") * tint
	var pts := PackedVector2Array([Vector2(-200, base_y + 400)])
	var x := -200.0
	var forts: Array = []
	while x < width + 200.0:
		var h := rng.randf_range(120, 300)
		var w := rng.randf_range(160, 420)
		pts.append(Vector2(x, base_y - h * 0.45))
		pts.append(Vector2(x + 30, base_y - h * 0.5))
		pts.append(Vector2(x + 60, base_y - h))
		pts.append(Vector2(x + w, base_y - h))
		pts.append(Vector2(x + w + 40, base_y - h * 0.55))
		if rng.randf() < 0.3 and w > 240.0:
			forts.append(Rect2(x + 80, base_y - h - 14, w - 110, 14))
		x += w + rng.randf_range(60, 200)
	pts.append(Vector2(width + 200.0, base_y + 400))
	draw_colored_polygon(pts, col)
	for f in forts:
		draw_rect(f, col.darkened(0.18))
		draw_rect(Rect2(f.position.x + f.size.x * 0.4, f.position.y - 12, 26, 12), col.darkened(0.18))
	draw_rect(Rect2(-200, base_y - 60, width + 400, 460), Color(0.85, 0.95, 0.9, 0.2))


## A broad river: flat water band with slow glints.
func _river(rng: RandomNumberGenerator) -> void:
	var c := Color("4f8a9a") * tint
	draw_rect(Rect2(-200, base_y - 46, width + 400, 500), c)
	draw_rect(Rect2(-200, base_y - 50, width + 400, 6), c.lightened(0.25))
	for i in int(width / 90.0):
		var x := rng.randf_range(0, width)
		var y := base_y - 36.0 + rng.randf_range(0, 110)
		var w := rng.randf_range(20, 70)
		var a := 0.25 + 0.2 * sin(_t * 1.3 + i)
		draw_line(Vector2(x, y), Vector2(x + w, y), Color(1, 1, 1, a), 2.0)


## Long fortified ridge: curtain wall, round bastions, a palace block and domed kiosks.
func _fortline(rng: RandomNumberGenerator) -> void:
	var c := Color("b08a62") * tint
	draw_rect(Rect2(-200, base_y - 90, width + 400, 500), c.darkened(0.12))
	var x := -100.0
	while x < width + 100.0:
		var w := rng.randf_range(260, 520)
		draw_rect(Rect2(x, base_y - 150, w, 70), c)
		var mx := x
		while mx < x + w:
			draw_rect(Rect2(mx, base_y - 160, 12, 10), c)
			mx += 24.0
		draw_rect(Rect2(x + w - 40, base_y - 190, 70, 110), c.lightened(0.04))
		draw_circle(Vector2(x + w - 5, base_y - 190), 35, c.lightened(0.04))
		if rng.randf() < 0.45:
			var px := x + w * 0.35
			draw_rect(Rect2(px, base_y - 230, 120, 80), c.lightened(0.07))
			draw_circle(Vector2(px + 60, base_y - 230), 26, c.lightened(0.1))
			for k in 3:
				draw_rect(Rect2(px + 16 + k * 36, base_y - 205, 14, 26), c.darkened(0.3))
		x += w + 30.0


## Distant war boats on the river (no insignia), rocking gently.
func _fleet(rng: RandomNumberGenerator) -> void:
	var x := 100.0
	var i := 0
	while x < width:
		var y := base_y + rng.randf_range(-20, 30) + sin(_t * 1.2 + i) * 3.0
		var s := rng.randf_range(0.7, 1.3)
		var hull := Color("3a2a22") * tint
		draw_colored_polygon(PackedVector2Array([Vector2(x - 60 * s, y), Vector2(x + 60 * s, y), Vector2(x + 44 * s, y + 16 * s), Vector2(x - 44 * s, y + 16 * s)]), hull)
		draw_line(Vector2(x - 60 * s, y), Vector2(x - 74 * s, y - 14 * s), hull, 4.0)
		draw_line(Vector2(x, y), Vector2(x, y - 56 * s), hull, 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x + 2, y - 54 * s), Vector2(x + 40 * s, y - 34 * s), Vector2(x + 2, y - 14 * s)]), Color(0.9, 0.85, 0.75, 0.85) * tint)
		x += rng.randf_range(260, 620)
		i += 1


func _ridge(rng: RandomNumberGenerator, height: float, var_h: float, col: Color, freq: float) -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(-200, base_y + 400))
	var x := -200.0
	var ph := rng.randf() * 10.0
	while x <= width + 200.0:
		var h := height + sin(x * freq + ph) * var_h * 0.6 + sin(x * freq * 2.7 + ph * 2.0) * var_h * 0.3 + rng.randf_range(-6, 6)
		pts.append(Vector2(x, base_y - h))
		x += 40.0
	pts.append(Vector2(width + 200.0, base_y + 400))
	draw_colored_polygon(pts, col * tint)
	# atmospheric haze band near the base
	draw_rect(Rect2(-200, base_y - 40, width + 400, 440), Color(1, 0.9, 0.75, 0.18))


func _hill_fort_wall(rng: RandomNumberGenerator) -> void:
	# A Kumbhalgarh-style wall snaking over the ridge, with bastions.
	var c := Color("b08a62") * tint
	var x := 300.0
	var last := Vector2(x, base_y - 170)
	while x < width:
		var y := base_y - 150.0 - sin(x * 0.01) * 50.0 - 10.0
		var p := Vector2(x, y)
		draw_line(last, p, c, 6.0)
		if rng.randf() < 0.3:
			draw_rect(Rect2(p.x - 8, p.y - 16, 16, 18), c)
			draw_circle(p + Vector2(0, -16), 8.0, c)
		last = p
		x += 60.0


func _chhatri(p: Vector2, s: float, col: Color) -> void:
	draw_rect(Rect2(p.x - 26 * s, p.y - 8 * s, 52 * s, 8 * s), col.darkened(0.1))
	for i in 4:
		draw_rect(Rect2(p.x - 22 * s + i * 13 * s, p.y - 40 * s, 4 * s, 32 * s), col)
	draw_rect(Rect2(p.x - 28 * s, p.y - 46 * s, 56 * s, 6 * s), col.darkened(0.05))
	draw_circle(p + Vector2(0, -46 * s), 20 * s, col.lightened(0.05))
	draw_rect(Rect2(p.x - 22 * s, p.y - 46 * s, 44 * s, 8 * s), col.darkened(0.05))
	draw_line(p + Vector2(0, -66 * s), p + Vector2(0, -76 * s), col.darkened(0.3), 2.0 * s)
	draw_circle(p + Vector2(0, -77 * s), 2.5 * s, Game.C_GOLD)


func _haveli(p: Vector2, w: float, h: float, col: Color, rng: RandomNumberGenerator) -> void:
	draw_rect(Rect2(p.x, p.y - h, w, h), col)
	draw_rect(Rect2(p.x - 4, p.y - h - 6, w + 8, 6), col.lightened(0.08))
	# rows of arched windows
	var rows := int(h / 46.0)
	for ry in rows:
		var wy := p.y - h + 18 + ry * 46.0
		var wx := p.x + 12.0
		while wx + 16 < p.x + w:
			draw_rect(Rect2(wx, wy + 6, 14, 20), col.darkened(0.45))
			draw_circle(Vector2(wx + 7, wy + 7), 7.0, col.darkened(0.45))
			wx += 28.0
	# jharokha (projecting balcony)
	if w > 90:
		var jx := p.x + w * 0.5 - 22
		var jy := p.y - h * 0.55
		draw_rect(Rect2(jx, jy, 44, 30), col.lightened(0.1))
		draw_rect(Rect2(jx - 4, jy + 30, 52, 5), col.darkened(0.15))
		draw_circle(Vector2(jx + 22, jy), 22.0, col.lightened(0.12))
		draw_rect(Rect2(jx + 8, jy + 6, 28, 18), col.darkened(0.4))
	# kangura merlons
	var mx := p.x
	while mx < p.x + w - 8:
		draw_colored_polygon(PackedVector2Array([Vector2(mx, p.y - h - 6), Vector2(mx + 10, p.y - h - 6), Vector2(mx + 5, p.y - h - 16)]), col.lightened(0.05))
		mx += 16.0
	if rng.randf() < 0.6:
		_chhatri(Vector2(p.x + w * 0.5, p.y - h - 6), 0.6, col)


func _shikhara(p: Vector2, s: float, col: Color) -> void:
	draw_rect(Rect2(p.x - 50 * s, p.y - 50 * s, 100 * s, 50 * s), col)
	var pts := PackedVector2Array()
	for i in 13:
		var f := float(i) / 12.0
		var a := f * PI
		pts.append(Vector2(p.x - cos(a) * 40 * s * (1.0 - 0.15 * sin(a)), p.y - 50 * s - sin(a) * 130 * s * (0.6 + 0.4 * sin(a * 0.5))))
	draw_colored_polygon(pts, col.lightened(0.06))
	for i in 5:
		draw_line(Vector2(p.x - 36 * s + i * 4 * s, p.y - 60 * s - i * 22 * s), Vector2(p.x + 36 * s - i * 4 * s, p.y - 60 * s - i * 22 * s), col.darkened(0.12), 2.0 * s)
	draw_circle(p + Vector2(0, -182 * s), 8 * s, Game.C_GOLD)
	# saffron temple flag
	draw_line(p + Vector2(0, -190 * s), p + Vector2(0, -230 * s), Color("3a2418"), 2.0)
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -230 * s), p + Vector2(30 * s, -222 * s), p + Vector2(0, -212 * s)]), Game.C_SAFFRON)


func _town(rng: RandomNumberGenerator) -> void:
	var col := Color("c99a68") * tint
	var x := -100.0
	while x < width:
		var r := rng.randf()
		if r < 0.55:
			var w := rng.randf_range(80, 180)
			_haveli(Vector2(x, base_y), w, rng.randf_range(110, 220), col.darkened(rng.randf_range(0, 0.12)), rng)
			x += w + rng.randf_range(10, 60)
		elif r < 0.75:
			_chhatri(Vector2(x + 40, base_y), rng.randf_range(0.9, 1.3), col)
			x += 120
		elif r < 0.88:
			_shikhara(Vector2(x + 60, base_y), rng.randf_range(0.8, 1.1), col.lightened(0.05))
			x += 160
		else:
			# khejri / neem tree
			var tc := Color("7d8a4a") * tint
			draw_line(Vector2(x + 30, base_y), Vector2(x + 30, base_y - 70), Color("5a4030") * tint, 6.0)
			draw_circle(Vector2(x + 30, base_y - 80), 34, tc)
			draw_circle(Vector2(x + 6, base_y - 66), 22, tc.darkened(0.08))
			draw_circle(Vector2(x + 54, base_y - 68), 24, tc.darkened(0.04))
			x += 90
	draw_rect(Rect2(-200, base_y - 300, width + 400, 300), Color(1, 0.9, 0.78, 0.32))


func _foreground(rng: RandomNumberGenerator) -> void:
	var x := 0.0
	while x < width:
		var r := rng.randf()
		var c := Color("4a3a22") * tint
		if r < 0.6:
			for i in 7:
				var a := -1.2 + i * 0.4
				draw_line(Vector2(x, base_y), Vector2(x, base_y) + Vector2(sin(a), -cos(a)) * rng.randf_range(30, 60), c, 3.0)
		x += rng.randf_range(300, 700)


## Distant, generic troop columns (no insignia) marching along the valley floor.
func _troops(rng: RandomNumberGenerator) -> void:
	var col := Color(0.32, 0.24, 0.18, 0.55) * tint
	var x := 0.0
	while x < width:
		var n := rng.randi_range(8, 22)
		var dir := 1.0 if rng.randf() < 0.5 else -1.0
		var drift := fmod(_t * 14.0 * dir, 60.0)
		for i in n:
			var px := x + i * 9.0 + drift
			var py := base_y - (i % 3) * 3.0
			var bob := sin(_t * 6.0 + i) * 1.0
			draw_line(Vector2(px, py), Vector2(px, py - 10 + bob), col, 2.0)
			draw_circle(Vector2(px, py - 12 + bob), 2.0, col)
			if i % 4 == 0:
				draw_line(Vector2(px + 2, py - 4), Vector2(px + 2, py - 22), col, 1.0)
		if rng.randf() < 0.5:
			var fx := x + n * 4.0 + drift
			draw_line(Vector2(fx, base_y), Vector2(fx, base_y - 34), col, 1.5)
			draw_colored_polygon(PackedVector2Array([Vector2(fx, base_y - 34), Vector2(fx + 14, base_y - 30), Vector2(fx, base_y - 26)]), col)
		# dust raised by the column
		draw_circle(Vector2(x + n * 4.5 + drift, base_y - 6), n * 3.0, Color(0.9, 0.78, 0.5, 0.12))
		x += rng.randf_range(420, 900)


func _forest(rng: RandomNumberGenerator) -> void:
	var x := -100.0
	while x < width:
		var h := rng.randf_range(90, 180)
		var c := Color("5d6b3a").lerp(Color("7a7f45"), rng.randf()) * tint
		draw_line(Vector2(x, base_y), Vector2(x, base_y - h * 0.6), Color("4a3a2a") * tint, 6.0)
		draw_circle(Vector2(x, base_y - h * 0.7), h * 0.32, c)
		draw_circle(Vector2(x - h * 0.2, base_y - h * 0.55), h * 0.24, c.darkened(0.08))
		draw_circle(Vector2(x + h * 0.22, base_y - h * 0.58), h * 0.26, c.darkened(0.04))
		x += rng.randf_range(60, 160)
	draw_rect(Rect2(-200, base_y - 260, width + 400, 300), Color(1, 0.85, 0.6, 0.12))


func _rocks(rng: RandomNumberGenerator) -> void:
	var x := -100.0
	while x < width:
		var w := rng.randf_range(120, 300)
		var h := rng.randf_range(80, 220)
		var c := Color("c8a050").lerp(Color("a8803e"), rng.randf()) * tint
		draw_colored_polygon(PackedVector2Array([Vector2(x, base_y), Vector2(x + w * 0.15, base_y - h * 0.7), Vector2(x + w * 0.4, base_y - h),
			Vector2(x + w * 0.7, base_y - h * 0.8), Vector2(x + w, base_y)]), c)
		draw_line(Vector2(x + w * 0.4, base_y - h), Vector2(x + w * 0.5, base_y - h * 0.4), c.darkened(0.15), 3.0)
		x += w + rng.randf_range(40, 260)
	draw_rect(Rect2(-200, base_y - 260, width + 400, 300), Color(1, 0.9, 0.6, 0.2))
