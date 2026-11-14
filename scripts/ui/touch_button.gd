class_name TouchButton
extends TouchScreenButton
## Round on-screen button. Uses Godot's TouchScreenButton, which tracks its own
## finger index, so several buttons can be held at once (true multi-touch).

var radius := 56.0
var glyph := "attack"
var caption := ""
var _was_pressed := false
## Asset-pack icon per glyph: [icon name, rotation]. "block" and "dodge" keep
## procedural glyphs: the pack's shield icon carries a cross emblem that does not
## fit a Mewar dhal, and there is no dodge icon.
const ICONS := {"left": ["left", 0.0], "right": ["right", 0.0], "up": ["left", PI * 0.5],
	"down": ["left", -PI * 0.5], "jump": ["jump", 0.0], "attack": ["sword", 0.0],
	"gallop": ["horse", 0.0], "pause": ["pause", 0.0], "context": ["interact", 0.0]}


func configure(r: float, g: String, act: String, passby := false) -> void:
	radius = r
	glyph = g
	action = act
	passby_press = passby
	var sh := CircleShape2D.new()
	sh.radius = r
	shape = sh
	shape_centered = true
	shape_visible = false
	visibility_mode = TouchScreenButton.VISIBILITY_ALWAYS
	queue_redraw()


func _process(_d: float) -> void:
	if is_pressed() != _was_pressed:
		_was_pressed = is_pressed()
		queue_redraw()


func _draw() -> void:
	var on := is_pressed()
	var a: float = Game.settings.button_opacity
	draw_circle(Vector2.ZERO, radius, Color(0.1, 0.08, 0.18, 0.55 * a + (0.2 if on else 0.0)))
	draw_arc(Vector2.ZERO, radius - 2, 0, TAU, 40, Color(Game.C_GOLD, 0.9 * a + (0.1 if on else 0.0)), 3.0)
	var c := Color(1, 0.93, 0.8, minf(1.0, a + 0.25 + (0.2 if on else 0.0)))
	var s := radius * 0.42
	if ICONS.has(glyph):
		var ic := MewarAssets.icon(ICONS[glyph][0])
		if ic:
			var sz := radius * (1.05 if glyph != "context" else 0.8)
			draw_set_transform(Vector2(0, -radius * 0.12 if glyph == "context" else 0.0), ICONS[glyph][1], Vector2.ONE)
			draw_texture_rect(ic, Rect2(-sz * 0.5, -sz * 0.5, sz, sz), false, Color(1, 1, 1, c.a))
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			if caption != "":
				var f0 := ThemeDB.fallback_font
				var fs0 := int(radius * 0.26)
				var w0 := f0.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, fs0).x
				draw_string(f0, Vector2(-w0 * 0.5, radius * 0.62), caption, HORIZONTAL_ALIGNMENT_CENTER, -1, fs0, c)
			return
	match glyph:
		"left":
			draw_colored_polygon(PackedVector2Array([Vector2(-s, 0), Vector2(s * 0.6, -s), Vector2(s * 0.6, s)]), c)
		"right":
			draw_colored_polygon(PackedVector2Array([Vector2(s, 0), Vector2(-s * 0.6, -s), Vector2(-s * 0.6, s)]), c)
		"up":
			draw_colored_polygon(PackedVector2Array([Vector2(0, -s), Vector2(-s, s * 0.6), Vector2(s, s * 0.6)]), c)
		"down":
			draw_colored_polygon(PackedVector2Array([Vector2(0, s), Vector2(-s, -s * 0.6), Vector2(s, -s * 0.6)]), c)
		"jump":
			draw_polyline(PackedVector2Array([Vector2(-s, s * 0.2), Vector2(0, -s * 0.6), Vector2(s, s * 0.2)]), c, 6.0)
			draw_polyline(PackedVector2Array([Vector2(-s, s * 0.9), Vector2(0, s * 0.1), Vector2(s, s * 0.9)]), c, 6.0)
		"attack":
			var pts := PackedVector2Array()
			for i in 9:
				var f := i / 8.0
				pts.append(Vector2(-s * 0.7 + f * s * 1.6, s * 0.7 - f * s * 1.6) + Vector2(-1, -1) * f * f * 6.0)
			draw_polyline(pts, c, 5.0)
			draw_line(Vector2(-s * 0.95, s * 0.35), Vector2(-s * 0.35, s * 0.95), c, 5.0)
		"block":
			draw_circle(Vector2.ZERO, s, c)
			draw_circle(Vector2.ZERO, s * 0.25, Color(0.3, 0.2, 0.1, a + 0.3))
		"dodge":
			for k in 2:
				var o := -s * 0.45 + k * s * 0.8
				draw_polyline(PackedVector2Array([Vector2(o - s * 0.35, -s * 0.7), Vector2(o + s * 0.3, 0), Vector2(o - s * 0.35, s * 0.7)]), c, 5.0)
		"gallop":
			for k in 3:
				var o := -s * 0.75 + k * s * 0.65
				draw_polyline(PackedVector2Array([Vector2(o - s * 0.3, -s * 0.6), Vector2(o + s * 0.25, 0), Vector2(o - s * 0.3, s * 0.6)]), c, 4.5)
		"pause":
			draw_rect(Rect2(-s * 0.55, -s * 0.7, s * 0.4, s * 1.4), c)
			draw_rect(Rect2(s * 0.15, -s * 0.7, s * 0.4, s * 1.4), c)
	if caption != "":
		var f := ThemeDB.fallback_font
		var fs := int(radius * 0.32)
		var w := f.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		draw_string(f, Vector2(-w * 0.5, fs * 0.35), caption, HORIZONTAL_ALIGNMENT_CENTER, -1, fs, c)
