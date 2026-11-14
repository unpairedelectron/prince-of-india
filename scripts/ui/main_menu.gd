extends Control
## Main menu: title, Pratap + Chetak artwork (procedural placeholder),
## New Game, Continue, Settings, Historical Gallery, Credits.

const GALLERY := [
	["Maharana Pratap", "HISTORICAL RECORD", "Pratap Singh (1540-1597) of the Sisodia dynasty became Maharana of Mewar in 1572. He is remembered for resisting incorporation into the Mughal empire under Akbar for the rest of his life."],
	["Kumbhalgarh", "HISTORICAL RECORD", "A 15th-century hill fort of Mewar in the Aravalli range, built under Rana Kumbha. Part of the UNESCO World Heritage property 'Hill Forts of Rajasthan' (2013). Traditionally associated with Pratap's birth."],
	["Gogunda", "HISTORICAL RECORD", "A town in the hills west of Udaipur where Pratap's accession as Maharana took place in 1572."],
	["Haldighati", "HISTORICAL RECORD", "A mountain pass whose yellowish soil gives it its name. On 18 June 1576 Mewar's forces fought the Mughal army commanded by Raja Man Singh of Amber here. The battle did not end the conflict."],
	["Chetak", "TRADITIONAL ACCOUNT", "Pratap's horse. Tradition holds that the wounded Chetak carried him to safety after Haldighati and died soon after. The story is widely told; not every detail is documented."],
	["Dewair", "HISTORICAL RECORD", "Site of a 1582 campaign associated with the revival of Mewar's fortunes. It did not end the wider conflict."],
	["Chavand", "HISTORICAL RECORD", "A hill settlement that became an important centre of Pratap's rule in his later years. He died in 1597."],
]

var _menu: VBoxContainer
var _continue_btn: Button
var _overlay: Control


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var art := _MenuArt.new()
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	var title := VBoxContainer.new()
	title.position = Vector2(60, 40)
	add_child(title)
	title.add_child(UiKit.label("PRINCE OF INDIA", 58, Game.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	title.add_child(UiKit.label("MAHARANA PRATAP - THE DEFENDER OF MEWAR", 26, Color("f3e3c0"), HORIZONTAL_ALIGNMENT_LEFT))
	for l in title.get_children():
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
		l.add_theme_constant_override("shadow_offset_x", 3)
		l.add_theme_constant_override("shadow_offset_y", 3)
	_menu = VBoxContainer.new()
	_menu.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_menu.position = Vector2(-400, -230)
	_menu.add_theme_constant_override("separation", 12)
	add_child(_menu)
	_continue_btn = UiKit.button("Continue", Game.continue_game)
	_continue_btn.disabled = not Game.has_continue()
	_menu.add_child(_continue_btn)
	_menu.add_child(UiKit.button("New Game", _on_new_game))
	_menu.add_child(UiKit.button("Chapters", _on_chapters))
	_menu.add_child(UiKit.button("Settings", _on_settings))
	_menu.add_child(UiKit.button("Historical Gallery", _on_gallery))
	_menu.add_child(UiKit.button("Credits", _on_credits))
	(_menu.get_child(0 if Game.has_continue() else 1) as Button).grab_focus()
	var note := UiKit.label("Development build - placeholder art & audio", 14, Color(0.9, 0.85, 0.75, 0.7), HORIZONTAL_ALIGNMENT_LEFT)
	note.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	note.position = Vector2(20, -34)
	add_child(note)
	Audio.play_music("gogunda_theme")


func _modal(content: Control) -> void:
	_close_overlay()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(c)
	c.add_child(content)
	add_child(dim)
	_overlay = dim


func _close_overlay() -> void:
	if _overlay and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null


func _on_new_game() -> void:
	if not Game.has_continue():
		_start_new()
		return
	var p := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(UiKit.label("Start a new game?", 30, Game.C_GOLD))
	v.add_child(UiKit.label("Your current mission checkpoint will be replaced.", 20))
	v.add_child(UiKit.button("Start new game", _start_new))
	v.add_child(UiKit.button("Cancel", _close_overlay))
	_modal(p)


func _start_new() -> void:
	Audio.stop_all_loops()
	Game.new_game()


func _on_chapters() -> void:
	var p := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	p.add_child(v)
	v.add_child(UiKit.label("Chapters", 32, Game.C_GOLD))
	for m in Game.MISSION_ORDER:
		var unlocked: bool = m in Game.progress.missions_unlocked
		var done: bool = m in Game.progress.missions_completed
		var b := UiKit.button(Game.MISSION_TITLES[m] + ("   [done]" if done else ""), func():
			Audio.stop_all_loops()
			Game.play_chapter(m), 560)
		b.disabled = not unlocked
		v.add_child(b)
	v.add_child(UiKit.label("Chapters unlock as you complete missions.", 16, Color(0.85, 0.8, 0.7)))
	v.add_child(UiKit.button("Asset Test Room (development)", func():
		Audio.stop_all_loops()
		Game.progress.current_mission = ""
		Game.start_mission("asset_test"), 560))
	v.add_child(UiKit.button("Close", _close_overlay))
	_modal(p)


func _on_settings() -> void:
	var s := SettingsPanel.new()
	s.closed.connect(_close_overlay)
	_modal(s)


func _on_gallery() -> void:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(900, 560)
	var v := VBoxContainer.new()
	p.add_child(v)
	v.add_child(UiKit.label("Historical Gallery", 32, Game.C_GOLD))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(860, 420)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var list := VBoxContainer.new()
	list.custom_minimum_size.x = 830
	list.add_theme_constant_override("separation", 14)
	sc.add_child(list)
	for e in GALLERY:
		list.add_child(UiKit.label(e[0], 24, Game.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
		list.add_child(UiKit.label("[" + e[1] + "]", 14, Game.C_SAFFRON, HORIZONTAL_ALIGNMENT_LEFT))
		var b := UiKit.label(e[2], 19, Color("f3e3c0"), HORIZONTAL_ALIGNMENT_LEFT)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size.x = 820
		list.add_child(b)
	v.add_child(UiKit.label("Sources: documentation/HISTORICAL_REFERENCES.md", 14, Color(0.8, 0.75, 0.65)))
	v.add_child(UiKit.button("Close", _close_overlay))
	_modal(p)


func _on_credits() -> void:
	var p := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	p.add_child(v)
	v.add_child(UiKit.label("Credits", 32, Game.C_GOLD))
	for line in ["Design & development: Prince of India team", "Engine: Godot Engine 4 (MIT licence)",
			"Art & audio: original procedural placeholders", "Fictional training content is clearly labelled in-game.",
			"Historical framing: see Historical Gallery"]:
		v.add_child(UiKit.label(line, 20))
	v.add_child(UiKit.button("Close", _close_overlay))
	_modal(p)


class _MenuArt extends Control:
	var _t := 0.0
	var _pratap: HumanRig
	var _chetak: HorseRig
	var _bg: Texture2D

	func _ready() -> void:
		_bg = MewarAssets.background("kumbhalgarh_parallax")
		_chetak = HorseSprite.new()
		_chetak.scale = Vector2(2.2, 2.2)
		add_child(_chetak)
		_pratap = SpriteRig.new()
		_pratap.scale = Vector2(2.6, 2.6)
		add_child(_pratap)
		_pratap.play("idle")
		_chetak.play("idle")
		_chetak.head_look = 1.0
		resized.connect(_place)
		_place()

	func _place() -> void:
		var s := size if size.x > 0 else Vector2(1280, 720)
		_pratap.position = Vector2(s.x * 0.36, s.y * 0.86)
		_chetak.position = Vector2(s.x * 0.17, s.y * 0.86)

	func _process(d: float) -> void:
		_t += d
		queue_redraw()

	func _draw() -> void:
		var s := size
		if _bg:
			var k := maxf(s.x / _bg.get_width(), s.y / _bg.get_height())
			draw_texture_rect(_bg, Rect2(Vector2(s.x - _bg.get_width() * k, s.y - _bg.get_height() * k) * 0.5, Vector2(_bg.get_width(), _bg.get_height()) * k), false)
			draw_rect(Rect2(0, s.y * 0.86, s.x, s.y * 0.14), Color("8a6440"))
			draw_rect(Rect2(0, s.y * 0.86, s.x, 6), Color("c89a5c"))
			return
		draw_rect(Rect2(Vector2.ZERO, s), Color("e9b979"))
		for i in 12:
			var f := i / 12.0
			draw_rect(Rect2(0, s.y * f * 0.6, s.x, s.y * 0.06), Color("7fa9cf").lerp(Color("e9b979"), f))
		draw_circle(Vector2(s.x * 0.72, s.y * 0.42), 70, Color(1, 0.9, 0.7, 0.6))
		_ridge(s, s.y * 0.62, 70.0, Color("b49a86"), 0.004, 1.0)
		_ridge(s, s.y * 0.7, 50.0, Color("9a7a5a"), 0.008, 3.0)
		# hill fort on the ridge
		var fc := Color("b88a5a")
		var bx := s.x * 0.55
		var by := s.y * 0.6
		draw_rect(Rect2(bx, by - 60, 340, 60), fc)
		for k in 9:
			draw_colored_polygon(PackedVector2Array([Vector2(bx + k * 38, by - 60), Vector2(bx + k * 38 + 18, by - 60), Vector2(bx + k * 38 + 9, by - 76)]), fc)
		draw_rect(Rect2(bx + 120, by - 120, 90, 60), fc.lightened(0.05))
		draw_circle(Vector2(bx + 165, by - 120), 30, fc.lightened(0.1))
		draw_rect(Rect2(0, s.y * 0.86, s.x, s.y * 0.14), Color("8a6440"))
		draw_rect(Rect2(0, s.y * 0.86, s.x, 6), Color("c89a5c"))

	func _ridge(s: Vector2, base: float, h: float, col: Color, freq: float, ph: float) -> void:
		var pts := PackedVector2Array([Vector2(0, s.y)])
		var x := 0.0
		while x <= s.x + 20:
			pts.append(Vector2(x, base - h * (0.6 + 0.4 * sin(x * freq + ph))))
			x += 20.0
		pts.append(Vector2(s.x, s.y))
		draw_colored_polygon(pts, col)
