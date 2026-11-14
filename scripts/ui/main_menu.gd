extends Control
## Main menu: title, hero artwork, Continue / Play (hero select -> level
## select) / Settings / Historical Gallery / Credits.

const GALLERY := [
	["Maharana Pratap", "HISTORICAL RECORD", "Pratap Singh (1540-1597) of the Sisodia dynasty became Maharana of Mewar in 1572. He is remembered for resisting incorporation into the Mughal empire under Akbar for the rest of his life."],
	["Kumbhalgarh", "HISTORICAL RECORD", "A 15th-century hill fort of Mewar in the Aravalli range, built under Rana Kumbha. Part of the UNESCO World Heritage property 'Hill Forts of Rajasthan' (2013). Traditionally associated with Pratap's birth."],
	["Haldighati", "HISTORICAL RECORD", "A mountain pass whose yellowish soil gives it its name. On 18 June 1576 Mewar's forces fought the Mughal army commanded by Raja Man Singh of Amber here. The battle did not end the conflict."],
	["Chetak", "TRADITIONAL ACCOUNT", "Pratap's horse. Tradition holds that the wounded Chetak carried him to safety after Haldighati and died soon after. The story is widely told; not every detail is documented."],
	["Dewair", "HISTORICAL RECORD", "Site of a 1582 campaign associated with the revival of Mewar's fortunes. Pratap later ruled from Chavand and died in 1597."],
	["Chhatrapati Shivaji Maharaj", "HISTORICAL RECORD", "Shivaji Bhonsle (1630-1680) built an independent Maratha kingdom in the Sahyadri mountains from a chain of hill forts, and was crowned Chhatrapati at Raigad in 1674. He is remembered for his forts, his navy and his administration."],
	["Ganimi Kava", "HISTORICAL RECORD", "The Maratha way of war: speed, surprise, knowledge of the hills, and refusing battle on the enemy's terms."],
	["Pavan Khind", "HISTORICAL RECORD", "The pass where Baji Prabhu Deshpande's rear guard held off the pursuit in July 1660 so that Shivaji could reach Vishalgad."],
	["Rani Lakshmibai", "HISTORICAL RECORD", "Queen of Jhansi (c. 1828-1858). After the East India Company annexed her kingdom she led its defence in the uprising of 1857-58 and died fighting near Gwalior on 17 June 1858."],
	["The Doctrine of Lapse", "HISTORICAL RECORD", "A Company policy under which a princely state was annexed if its ruler died without a natural heir. Adopted heirs, like Jhansi's Damodar Rao, were not recognised."],
	["Lachit Borphukan", "HISTORICAL RECORD", "Commander of the Ahom kingdom of Assam (1622-1672). He recovered Guwahati in 1667 and defeated a much larger Mughal force on the Brahmaputra at Saraighat in 1671."],
	["The Ahom kingdom", "HISTORICAL RECORD", "A kingdom in the Brahmaputra valley that lasted nearly six hundred years (1228-1826) and repeatedly turned back invasions from the west."],
	["About this game", "GAMEPLAY - FICTIONAL", "Level layouts, traps, ordinary soldiers and every boss are invented. These were wars between kingdoms and empires, with people of many communities on every side; no opponent in the game stands for a faith or a people."],
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
	title.position = Vector2(60, 34)
	title.add_theme_constant_override("separation", -4)
	add_child(title)
	title.add_child(UiKit.label(Campaigns.GAME_TITLE, 96, Game.C_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	title.add_child(UiKit.label(Campaigns.GAME_SUBTITLE, 30, Color("f3e3c0"), HORIZONTAL_ALIGNMENT_LEFT))
	title.add_child(UiKit.label(Campaigns.GAME_TAGLINE, 20, Game.C_SAFFRON, HORIZONTAL_ALIGNMENT_LEFT))
	for l in title.get_children():
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
		l.add_theme_constant_override("shadow_offset_x", 3)
		l.add_theme_constant_override("shadow_offset_y", 3)
	_menu = VBoxContainer.new()
	_menu.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_menu.position = Vector2(-400, -190)
	_menu.add_theme_constant_override("separation", 12)
	add_child(_menu)
	_continue_btn = UiKit.button("Continue", Game.continue_game)
	_continue_btn.disabled = not Game.has_continue()
	_menu.add_child(_continue_btn)
	_menu.add_child(UiKit.button("Play", _on_heroes))
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
	dim.color = Color(0, 0, 0, 0.72)
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


# ------------------------------------------------------------- hero select

func _on_heroes() -> void:
	var p := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)
	v.add_child(UiKit.label("CHOOSE YOUR LEGEND", 34, Game.C_GOLD))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	v.add_child(row)
	var first: Button = null
	for h in Campaigns.HERO_ORDER:
		var card := _hero_card(h)
		row.add_child(card)
		if first == null:
			first = card.get_meta("button")
	v.add_child(UiKit.button("Back", _close_overlay))
	_modal(p)
	if first:
		first.grab_focus()


func _hero_card(h: String) -> Control:
	var cfg: Dictionary = Campaigns.HEROES[h]
	var unlocked := Game.is_hero_unlocked(h)
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(262, 0)
	card.add_theme_constant_override("separation", 6)
	var portrait := HeroPortrait.new()
	portrait.hero = h
	portrait.custom_minimum_size = Vector2(262, 200)
	portrait.locked = not unlocked
	card.add_child(portrait)
	var name_l := UiKit.label(cfg.name, 21, Game.C_GOLD)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.custom_minimum_size = Vector2(262, 56)
	name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(name_l)
	card.add_child(UiKit.label(cfg.epithet, 17, Game.C_SAFFRON))
	card.add_child(UiKit.label(cfg.region, 15, Color(0.85, 0.8, 0.7)))
	var b: Button
	if unlocked:
		card.add_child(UiKit.label("Stars  %d / 15" % Game.hero_stars(h), 17))
		b = UiKit.button("Select", _on_levels.bind(h), 262)
	else:
		var prev: String = Campaigns.HERO_ORDER[Campaigns.HERO_ORDER.find(h) - 1]
		var lock := UiKit.label("Locked", 17, Color(0.8, 0.6, 0.5))
		card.add_child(lock)
		b = UiKit.button("Clear %s: Level 1" % Campaigns.HEROES[prev].name.split(" ")[-1], func(): pass, 262)
		b.disabled = true
		b.add_theme_font_size_override("font_size", 16)
	card.add_child(b)
	card.set_meta("button", b)
	return card


func _on_levels(h: String) -> void:
	var cfg: Dictionary = Campaigns.HEROES[h]
	var p := PanelContainer.new()
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 26)
	p.add_child(hb)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(330, 0)
	left.add_theme_constant_override("separation", 8)
	hb.add_child(left)
	var portrait := HeroPortrait.new()
	portrait.hero = h
	portrait.custom_minimum_size = Vector2(330, 230)
	left.add_child(portrait)
	left.add_child(UiKit.label(cfg.name, 24, Game.C_GOLD))
	left.add_child(UiKit.label("%s  -  %s" % [cfg.epithet, cfg.years], 16, Game.C_SAFFRON))
	for t in [cfg.pitch, "%s: %s" % [cfg.ability.to_upper(), cfg.ability_text]]:
		var l := UiKit.label(t, 17)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 330
		left.add_child(l)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	hb.add_child(v)
	v.add_child(UiKit.label("LEVELS", 28, Game.C_GOLD))
	var first: Button = null
	for id in cfg.levels:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var b := UiKit.button(Campaigns.label(id), func():
			Audio.stop_all_loops()
			Game.play_chapter(id), 560)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 19)
		b.disabled = not Game.is_level_unlocked(id)
		row.add_child(b)
		for i in 3:
			var st := UiKit.Star.new()
			st.filled = i < Game.stars_for(id)
			st.custom_minimum_size = Vector2(30, 30)
			st.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(st)
		v.add_child(row)
		if first == null or (not b.disabled and Game.stars_for(id) == 0 and first.get_meta("done", true)):
			first = b
			b.set_meta("done", Game.stars_for(id) > 0)
	v.add_child(UiKit.label("Each level is harder than the last. Clear one to open the next.", 15, Color(0.85, 0.8, 0.7)))
	v.add_child(UiKit.button("Back", _on_heroes))
	_modal(p)
	if first:
		first.grab_focus()


# ------------------------------------------------------------- other panels

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
	for line in ["Design & development: the %s team" % Campaigns.GAME_TITLE, "Engine: Godot Engine 4 (MIT licence)",
			"Art & audio: Mewar 2D asset pack + original procedural placeholders", "Levels, traps, soldiers and bosses are fictional and labelled in-game.",
			"Historical framing: see Historical Gallery"]:
		v.add_child(UiKit.label(line, 20))
	v.add_child(UiKit.button("Close", _close_overlay))
	_modal(p)


class _MenuArt extends Control:
	var _bg: Texture2D
	var _figures: Array = []

	func _ready() -> void:
		_bg = MewarAssets.background("kumbhalgarh_parallax")
		var chetak := HorseSprite.new()
		chetak.scale = Vector2(2.0, 2.0)
		add_child(chetak)
		chetak.play("idle")
		chetak.head_look = 1.0
		_figures.append([chetak, 0.1])
		var i := 0
		for h in Campaigns.HERO_ORDER:
			var rig := HeroPortrait.make_rig(h)
			rig.scale = Vector2(2.3, 2.3)
			add_child(rig)
			rig.play("idle")
			if not Game.is_hero_unlocked(h):
				rig.modulate = Color(0.08, 0.07, 0.1, 0.9)
			_figures.append([rig, 0.24 + i * 0.105])
			i += 1
		resized.connect(_place)
		_place()

	func _place() -> void:
		var s := size if size.x > 0 else Vector2(1280, 720)
		for f in _figures:
			(f[0] as Node2D).position = Vector2(s.x * f[1], s.y * 0.86)

	func _draw() -> void:
		var s := size
		if _bg:
			var k := maxf(s.x / _bg.get_width(), s.y / _bg.get_height())
			draw_texture_rect(_bg, Rect2(Vector2(s.x - _bg.get_width() * k, s.y - _bg.get_height() * k) * 0.5, Vector2(_bg.get_width(), _bg.get_height()) * k), false)
		else:
			draw_rect(Rect2(Vector2.ZERO, s), Color("e9b979"))
		draw_rect(Rect2(Vector2.ZERO, s), Color(0.1, 0.05, 0.12, 0.28))
		draw_rect(Rect2(0, s.y * 0.86, s.x, s.y * 0.14), Color("8a6440"))
		draw_rect(Rect2(0, s.y * 0.86, s.x, 6), Color("c89a5c"))
