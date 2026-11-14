class_name GogundaDecor
extends Node2D
## Non-colliding set dressing on the gameplay plane (PLACEHOLDER ART):
## courtyard arcade, torches, Mewar standards, weapon racks, the stable.

var items: Array = []   # [{type, pos, ...}]
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	for it in items:
		var p: Vector2 = it.pos
		match it.type:
			"arcade": _arcade(p, it.get("count", 4))
			"torch": _torch(p)
			"banner": _banner(p)
			"rack": _rack(p)
			"stable": _stable(p, it.get("width", 380.0))
			"sign": _sign(p, it.get("text", ""))
			"standard": _standard(p, it.get("raised", true))
			"flag": _flag(p)
			"tree": _tree(p, it.get("size", 1.0))
			"memorial": _memorial(p)
			"boulder": _boulder(p, it.get("size", 1.0))
			"prop": _prop(p, it.get("name", "crate"), it.get("size", 0.6), it.get("flip", false))


func _arcade(p: Vector2, n: int) -> void:
	var c := Game.C_SANDSTONE.lightened(0.05)
	var w := 110.0
	draw_rect(Rect2(p.x, p.y - 210, w * n + 20, 26), c.darkened(0.05))
	for i in n + 1:
		draw_rect(Rect2(p.x + i * w, p.y - 184, 20, 184), c)
		draw_rect(Rect2(p.x + i * w - 4, p.y - 184, 28, 10), c.lightened(0.08))
	for i in n:
		# multifoil arch outline
		var ax := p.x + i * w + 20 + (w - 20) * 0.5
		draw_arc(Vector2(ax, p.y - 140), (w - 20) * 0.5, PI, TAU, 14, c.darkened(0.15), 6.0)
		for k in 3:
			draw_circle(Vector2(ax - 22 + k * 22, p.y - 176), 9, c)
	draw_rect(Rect2(p.x - 10, p.y - 220, w * n + 40, 10), c.lightened(0.1))


## Asset-pack prop, bottom-centre at p. 128x128 source cell; size scales it.
func _prop(p: Vector2, name: String, k: float, flip := false) -> bool:
	var t := MewarAssets.prop(name)
	if t == null:
		return false
	var s := 128.0 * k
	draw_set_transform(p, 0, Vector2(-1 if flip else 1, 1))
	draw_texture_rect(t, Rect2(-s * 0.5, -s + 6.0 * k, s, s), false)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	return true


func _fire_frame(p: Vector2, k: float) -> void:
	var sf := MewarAssets.effect_frames()
	if sf == null:
		return
	var f := int(_t * 10.0 + p.x * 0.01) % 4
	var t := sf.get_frame_texture("fire", f)
	draw_circle(p + Vector2(0, -20 * k), 34.0 * k, Color(1, 0.6, 0.2, 0.12))
	draw_texture_rect(t, Rect2(p.x - 48 * k, p.y - 80 * k, 96 * k, 96 * k), false)


func _torch(p: Vector2) -> void:
	# Asset-pack torch with the animated fire strip from combat_effects.
	if _prop(p, "torch", 0.75):
		_fire_frame(p + Vector2(0, -62), 0.4)
		return
	draw_line(p, p + Vector2(0, -70), Color("4a2e1d"), 5.0)
	draw_rect(Rect2(p.x - 6, p.y - 80, 12, 10), Color("6b4428"))
	var f := 1.0 + 0.2 * sin(_t * 15.0 + p.x) + 0.1 * sin(_t * 27.0)
	draw_circle(p + Vector2(0, -92), 26.0 * f, Color(1, 0.6, 0.2, 0.12))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-7, -80), p + Vector2(7, -80), p + Vector2(sin(_t * 9.0) * 3.0, -80 - 22.0 * f)]), Color(1, 0.6, 0.15))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-3, -80), p + Vector2(3, -80), p + Vector2(0, -80 - 11.0 * f)]), Color(1, 0.9, 0.5))


func _banner(p: Vector2) -> void:
	# Generic saffron pennant on a pole (decorative; not a reconstruction of a specific historical flag).
	draw_line(p, p + Vector2(0, -170), Color("3a2418"), 4.0)
	var wave := sin(_t * 3.0 + p.x * 0.01) * 6.0
	draw_colored_polygon(PackedVector2Array([p + Vector2(2, -168), p + Vector2(70, -158 + wave), p + Vector2(60, -146 + wave), p + Vector2(72, -134 + wave), p + Vector2(2, -124)]), Game.C_SAFFRON)
	draw_circle(p + Vector2(0, -172), 4.0, Game.C_GOLD)


func _standard(p: Vector2, raised: bool) -> void:
	if not raised:
		draw_line(p, p + Vector2(0, -30), Color("3a2418"), 5.0)
		return
	_banner(p + Vector2(0, 0))
	draw_rect(Rect2(p.x - 18, p.y - 10, 36, 10), Game.C_SANDSTONE_DARK)


func _rack(p: Vector2) -> void:
	var wood := Color("6b4428")
	draw_rect(Rect2(p.x, p.y - 60, 6, 60), wood)
	draw_rect(Rect2(p.x + 74, p.y - 60, 6, 60), wood)
	draw_line(p + Vector2(0, -50), p + Vector2(80, -50), wood, 4.0)
	for i in 4:
		var x := p.x + 14 + i * 16
		draw_line(Vector2(x, p.y - 2), Vector2(x + 4, p.y - 80), Color("8a5a32") if i % 2 == 0 else Game.C_SILVER, 3.0)
	draw_circle(p + Vector2(40, -24), 14, Color("3b2416"))
	draw_circle(p + Vector2(40, -24), 3, Game.C_GOLD)


func _stable(p: Vector2, w: float) -> void:
	var wood := Color("6b4428")
	var c := Game.C_SANDSTONE
	draw_rect(Rect2(p.x, p.y - 150, w, 150), c.darkened(0.25))
	var x := p.x
	while x <= p.x + w:
		draw_rect(Rect2(x - 6, p.y - 160, 12, 160), wood)
		x += w / 3.0
	draw_colored_polygon(PackedVector2Array([p + Vector2(-30, -160), p + Vector2(w + 30, -160), p + Vector2(w + 10, -200), p + Vector2(-10, -200)]), Color("8a5a32"))
	for i in int(w / 30.0):
		draw_line(p + Vector2(-20 + i * 30, -162), p + Vector2(-4 + i * 30, -198), Color("6b4428"), 2.0)
	# hay and trough
	draw_colored_polygon(PackedVector2Array([p + Vector2(20, 0), p + Vector2(110, 0), p + Vector2(90, -30), p + Vector2(40, -34)]), Color("d8b56a"))
	draw_rect(Rect2(p.x + w - 120, p.y - 30, 90, 30), wood.darkened(0.1))


func _sign(p: Vector2, text: String) -> void:
	draw_line(p, p + Vector2(0, -60), Color("4a2e1d"), 5.0)
	draw_rect(Rect2(p.x - 56, p.y - 92, 112, 34), Color("8a5a32"))
	draw_rect(Rect2(p.x - 56, p.y - 92, 112, 34), Color("4a2e1d"), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(p.x - 52, p.y - 69), text, HORIZONTAL_ALIGNMENT_CENTER, 104, 14, Color("f3e3c0"))


## Small saffron marker flag: shows a safe landing zone.
func _flag(p: Vector2) -> void:
	draw_line(p, p + Vector2(0, -46), Color("3a2418"), 2.0)
	var wave := sin(_t * 5.0 + p.x) * 3.0
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -46), p + Vector2(22, -40 + wave), p + Vector2(0, -32)]), Game.C_SAFFRON)


func _tree(p: Vector2, k: float) -> void:
	draw_line(p, p + Vector2(0, -120 * k), Color("4e3624"), 10.0 * k)
	var c := Color("6f7f3e")
	draw_circle(p + Vector2(0, -140 * k), 50 * k, c)
	draw_circle(p + Vector2(-34 * k, -118 * k), 36 * k, c.darkened(0.08))
	draw_circle(p + Vector2(36 * k, -122 * k), 38 * k, c.darkened(0.04))


func _boulder(p: Vector2, k: float) -> void:
	draw_colored_polygon(PackedVector2Array([p + Vector2(-40, 0) * k, p + Vector2(-30, -40) * k, p + Vector2(10, -56) * k, p + Vector2(40, -30) * k, p + Vector2(46, 0) * k]), Color("b08848"))


## Simple stone platform with a small chhatri, as a quiet place of remembrance.
## Generic design; NOT a reconstruction of the actual Chetak Samadhi.
func _memorial(p: Vector2) -> void:
	var c := Color("cdb38a")
	draw_rect(Rect2(p.x - 60, p.y - 24, 120, 24), c.darkened(0.1))
	draw_rect(Rect2(p.x - 48, p.y - 34, 96, 10), c)
	for i in 4:
		draw_rect(Rect2(p.x - 40 + i * 26, p.y - 84, 6, 50), c)
	draw_rect(Rect2(p.x - 50, p.y - 92, 100, 8), c.lightened(0.05))
	draw_circle(p + Vector2(0, -92), 30, c.lightened(0.08))
	draw_rect(Rect2(p.x - 32, p.y - 92, 64, 8), c)
	draw_circle(p + Vector2(0, -124), 3, Game.C_GOLD)
	# marigold garland
	for i in 9:
		draw_circle(p + Vector2(-40 + i * 10, -30 + absf(i - 4) * -1.0), 3.5, Game.C_SAFFRON)
