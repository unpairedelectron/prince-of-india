class_name UiKit
extends RefCounted
## Shared look: subtle Mewar-inspired palette (indigo panels, gold trim, sandstone text).

static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font_size = 22
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.11, 0.1, 0.22, 0.92)
	panel.border_color = Game.C_GOLD
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(10)
	panel.set_content_margin_all(22)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	var b := StyleBoxFlat.new()
	b.bg_color = Color(0.24, 0.16, 0.12, 0.95)
	b.border_color = Game.C_GOLD.darkened(0.2)
	b.set_border_width_all(2)
	b.set_corner_radius_all(8)
	b.set_content_margin_all(12)
	b.content_margin_left = 26
	b.content_margin_right = 26
	var bh := b.duplicate()
	bh.bg_color = Color(0.45, 0.25, 0.1, 0.98)
	bh.border_color = Game.C_GOLD
	var bp := b.duplicate()
	bp.bg_color = Game.C_SAFFRON.darkened(0.3)
	var bd := b.duplicate()
	bd.bg_color = Color(0.2, 0.18, 0.18, 0.6)
	bd.border_color = Color(0.4, 0.35, 0.3)
	t.set_stylebox("normal", "Button", b)
	t.set_stylebox("hover", "Button", bh)
	t.set_stylebox("focus", "Button", bh)
	t.set_stylebox("pressed", "Button", bp)
	t.set_stylebox("disabled", "Button", bd)
	t.set_color("font_color", "Button", Color("f3e3c0"))
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(0.6, 0.55, 0.5))
	t.set_font_size("font_size", "Button", 24)
	t.set_color("font_color", "Label", Color("f3e3c0"))
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	bg.set_corner_radius_all(4)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("c0392b")
	fill.set_corner_radius_all(4)
	t.set_stylebox("background", "ProgressBar", bg)
	t.set_stylebox("fill", "ProgressBar", fill)
	var grab := StyleBoxFlat.new()
	grab.bg_color = Game.C_GOLD
	grab.set_corner_radius_all(6)
	grab.set_content_margin_all(6)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0.5)
	track.set_content_margin_all(4)
	t.set_stylebox("slider", "HSlider", track)
	t.set_stylebox("grabber_area", "HSlider", grab)
	t.set_stylebox("grabber_area_highlight", "HSlider", grab)
	_theme = t
	return t


static func button(text: String, cb: Callable, min_w := 300.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, 60)
	b.pressed.connect(func():
		Audio.sfx("ui", 0.02, -6.0)
		cb.call())
	return b


static func label(text: String, size := 22, color := Color("f3e3c0"), align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	return l


static func bar(color: Color, w := 220.0, h := 16.0) -> ProgressBar:
	var p := ProgressBar.new()
	p.show_percentage = false
	p.custom_minimum_size = Vector2(w, h)
	p.max_value = 100
	p.value = 100
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(4)
	p.add_theme_stylebox_override("fill", fill)
	return p


## Safe-area margins in viewport units (notches / rounded corners on Android).
static func safe_margins(vp: Viewport) -> Dictionary:
	var win := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	var vs := vp.get_visible_rect().size
	if win.x <= 0 or win.y <= 0 or safe.size.x <= 0:
		return {"left": 0.0, "right": 0.0, "top": 0.0, "bottom": 0.0}
	var sx := vs.x / float(win.x)
	var sy := vs.y / float(win.y)
	var wpos := DisplayServer.window_get_position()
	return {
		"left": maxf(0.0, (safe.position.x - wpos.x) * sx),
		"top": maxf(0.0, (safe.position.y - wpos.y) * sy),
		"right": maxf(0.0, (wpos.x + win.x - safe.end.x) * sx),
		"bottom": maxf(0.0, (wpos.y + win.y - safe.end.y) * sy),
	}
