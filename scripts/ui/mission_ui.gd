class_name MissionUI
extends CanvasLayer
## In-mission HUD + pause menu + mission-complete panel + fades + hints.
## Top-left: health/stamina (+ Chetak stamina when mounted).
## Top-centre: mission name + objective. Top-right: leaves count + pause.

signal restart_checkpoint
signal restart_mission
signal quit_to_menu
signal complete_continue

var player: Player
var horse: Horse
var touch: TouchControls

var _root: Control
var _hp: ProgressBar
var _st: ProgressBar
var _horse_box: HBoxContainer
var _horse_bar: ProgressBar
var _mission_label: Label
var _objective_label: Label
var _leaves_label: Label
var _hint_panel: PanelContainer
var _hint_label: Label
var _hint_timer := 0.0
var _toast: Label
var _toast_timer := 0.0
var _fade: ColorRect
var _pause_panel: Control
var _modal: Control
var _boss_box: VBoxContainer
var _boss_bar: ProgressBar
var _boss_name: Label


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = UiKit.theme()
	add_child(_root)

	# --- top-left vitals
	var tl := VBoxContainer.new()
	tl.name = "Vitals"
	tl.position = Vector2(24, 18)
	tl.add_theme_constant_override("separation", 6)
	_root.add_child(tl)
	_hp = UiKit.bar(Color("c0392b"), 240, 18)
	_st = UiKit.bar(Color("d9a441"), 200, 12)
	var hrow := _row("HEALTH", _hp)
	var heart := MewarAssets.icon("heart")
	if heart:
		var tr0 := TextureRect.new()
		tr0.texture = heart
		tr0.custom_minimum_size = Vector2(22, 22)
		tr0.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr0.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hrow.add_child(tr0)
		hrow.move_child(tr0, 0)
	tl.add_child(hrow)
	tl.add_child(_row("STAMINA", _st))
	_horse_bar = UiKit.bar(Color("9fb4c8"), 200, 12)
	_horse_box = _row("CHETAK", _horse_bar)
	_horse_box.visible = false
	tl.add_child(_horse_box)

	# --- top-centre
	var tc := VBoxContainer.new()
	tc.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tc.position = Vector2(-260, 12)
	tc.custom_minimum_size = Vector2(520, 0)
	tc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(tc)
	_mission_label = UiKit.label("", 20, Game.C_GOLD)
	_objective_label = UiKit.label("", 18, Color("f3e3c0"))
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_add_shadow(_mission_label)
	_add_shadow(_objective_label)
	tc.add_child(_mission_label)
	tc.add_child(_objective_label)

	# --- top-right
	var tr := HBoxContainer.new()
	tr.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tr.position = Vector2(-250, 14)
	tr.add_theme_constant_override("separation", 14)
	_root.add_child(tr)
	_leaves_label = UiKit.label("Leaves 0/0", 20, Color("f3e3c0"), HORIZONTAL_ALIGNMENT_RIGHT)
	_leaves_label.custom_minimum_size.x = 140
	_add_shadow(_leaves_label)
	tr.add_child(_leaves_label)
	var pb := UiKit.button("II", open_pause, 64)
	pb.custom_minimum_size = Vector2(64, 56)
	tr.add_child(pb)

	# --- hint panel (upper-middle: never under the thumbs)
	_hint_panel = PanelContainer.new()
	_hint_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_hint_panel.position = Vector2(-330, 120)
	_hint_panel.custom_minimum_size = Vector2(660, 0)
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_panel.modulate.a = 0.0
	_hint_label = UiKit.label("", 22)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_panel.add_child(_hint_label)
	_root.add_child(_hint_panel)

	_toast = UiKit.label("", 26, Game.C_GOLD)
	_toast.set_anchors_preset(Control.PRESET_CENTER)
	_toast.position = Vector2(-200, 40)
	_toast.custom_minimum_size = Vector2(400, 0)
	_toast.modulate.a = 0.0
	_add_shadow(_toast)
	_root.add_child(_toast)

	# --- boss bar (bottom centre, between the thumbs)
	_boss_box = VBoxContainer.new()
	_boss_box.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_boss_box.position = Vector2(-260, -84)
	_boss_box.custom_minimum_size = Vector2(520, 0)
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.visible = false
	_boss_name = UiKit.label("", 22, Game.C_GOLD)
	_add_shadow(_boss_name)
	_boss_bar = UiKit.bar(Color("b3261e"), 520, 16)
	_boss_box.add_child(_boss_name)
	_boss_box.add_child(_boss_bar)
	_root.add_child(_boss_box)

	touch = TouchControls.new()
	add_child(touch)

	_fade = ColorRect.new()
	_fade.color = Color(0.06, 0.04, 0.03, 1.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 90
	add_child(fade_layer)
	fade_layer.add_child(_fade)

	Game.app_focus_lost.connect(func():
		if _modal == null:
			open_pause())
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()


func _row(title: String, bar: ProgressBar) -> HBoxContainer:
	var h := HBoxContainer.new()
	var l := UiKit.label(title, 13, Color("f3e3c0"), HORIZONTAL_ALIGNMENT_LEFT)
	l.custom_minimum_size.x = 74
	_add_shadow(l)
	h.add_child(l)
	h.add_child(bar)
	return h


func _add_shadow(l: Label) -> void:
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)


func _apply_safe_area() -> void:
	var m := UiKit.safe_margins(get_viewport())
	_root.offset_left = m.left
	_root.offset_right = -m.right
	_root.offset_top = m.top


# ------------------------------------------------------------- binding

func bind_player(p: Player) -> void:
	player = p
	p.health_changed.connect(_on_health)
	p.stamina_changed.connect(_on_stamina)
	p.mounted_changed.connect(_on_mounted)
	_hp.max_value = p.health.max_health
	_hp.value = p.health.current
	_st.value = p.stamina


func _on_health(c: float, mx: float) -> void:
	_hp.max_value = mx
	_hp.value = c


func _on_stamina(c: float, mx: float) -> void:
	_st.max_value = mx
	_st.value = c


func _on_mounted(m: bool, h: Node) -> void:
	_horse_box.visible = m
	if m and h is Horse:
		horse = h
		for c in _horse_box.get_children():
			if c is Label:
				(c as Label).text = horse.horse_name.to_upper()
		if not horse.stamina_changed.is_connected(_on_horse_stamina):
			horse.stamina_changed.connect(_on_horse_stamina)
		_horse_bar.value = horse.stamina


func _on_horse_stamina(c: float, mx: float) -> void:
	_horse_bar.max_value = mx
	_horse_bar.value = c
	var fill := _horse_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill and horse:
		fill.bg_color = Color("c0392b") if horse.exhausted else Color("9fb4c8")


func set_mission(title: String, objective: String) -> void:
	_mission_label.text = title
	_objective_label.text = objective


func set_objective(text: String) -> void:
	_objective_label.text = text
	var tw := create_tween()
	_objective_label.modulate = Color(1.6, 1.4, 0.8)
	tw.tween_property(_objective_label, "modulate", Color.WHITE, 0.8)


func show_boss(boss_name: String, health: Health) -> void:
	_boss_name.text = boss_name
	_boss_bar.max_value = health.max_health
	_boss_bar.value = health.current
	_boss_box.visible = true
	_boss_box.modulate.a = 0.0
	create_tween().tween_property(_boss_box, "modulate:a", 1.0, 0.5)
	health.changed.connect(func(c, m):
		_boss_bar.max_value = m
		_boss_bar.value = c)


func hide_boss() -> void:
	_boss_box.visible = false


func set_collectibles(n: int, total: int) -> void:
	_leaves_label.text = "Leaves %d/%d" % [n, total]


func show_hint(text: String, duration := 6.0) -> void:
	_hint_label.text = text
	_hint_timer = duration
	var tw := create_tween()
	tw.tween_property(_hint_panel, "modulate:a", 1.0, 0.25)


func toast(text: String) -> void:
	_toast.text = text
	_toast_timer = 1.6
	_toast.modulate.a = 1.0


func fade_to(alpha: float, time := 0.5) -> Signal:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, time)
	return tw.finished


func _process(delta: float) -> void:
	if _hint_timer > 0.0:
		_hint_timer -= delta
		if _hint_timer <= 0.0:
			create_tween().tween_property(_hint_panel, "modulate:a", 0.0, 0.4)
	if _toast_timer > 0.0:
		_toast_timer -= delta
		_toast.modulate.a = clampf(_toast_timer / 0.5, 0.0, 1.0)
	if player:
		touch.set_state(player.is_mounted(), player.get_context_prompt(), player.near_ladder())
	if Input.is_action_just_pressed("pause"):
		if _modal == null:
			open_pause()
		elif _pause_panel and is_instance_valid(_pause_panel):
			close_pause()


# ------------------------------------------------------------- pause

func _make_modal(content: Control) -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	center.add_child(content)
	_root.add_child(dim)
	return dim


func open_pause() -> void:
	if _modal != null:
		return
	get_tree().paused = true
	touch.visible = false
	var panel := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	panel.add_child(v)
	v.add_child(UiKit.label("Paused", 34, Game.C_GOLD))
	v.add_child(UiKit.button("Resume", close_pause))
	v.add_child(UiKit.button("Restart checkpoint", func():
		close_pause()
		restart_checkpoint.emit()))
	v.add_child(UiKit.button("Restart mission", func():
		close_pause()
		restart_mission.emit()))
	v.add_child(UiKit.button("Settings", _open_settings))
	v.add_child(UiKit.button("Main menu", func():
		close_pause()
		quit_to_menu.emit()))
	_pause_panel = _make_modal(panel)
	_modal = _pause_panel
	(v.get_child(1) as Button).grab_focus()


func close_pause() -> void:
	if _modal and is_instance_valid(_modal):
		_modal.queue_free()
	_modal = null
	_pause_panel = null
	get_tree().paused = false
	touch.layout()


func _open_settings() -> void:
	var s := SettingsPanel.new()
	_pause_panel.visible = false
	var holder := _make_modal(s)
	s.closed.connect(func():
		holder.queue_free()
		if _pause_panel:
			_pause_panel.visible = true)


func is_paused_open() -> bool:
	return _modal != null


# ------------------------------------------------------------- mission complete

func show_complete(stats: Dictionary) -> void:
	get_tree().paused = true
	touch.visible = false
	var panel := PanelContainer.new()
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	v.add_child(UiKit.label("LEGEND COMPLETE" if stats.get("hero_done", false) else "LEVEL COMPLETE", 36, Game.C_GOLD))
	v.add_child(UiKit.label(stats.get("title", ""), 24))
	var stars: int = stats.get("stars", 0)
	if stars > 0:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 10)
		for i in 3:
			var st := UiKit.Star.new()
			st.filled = i < stars
			st.custom_minimum_size = Vector2(54, 54)
			row.add_child(st)
			if i < stars:
				st.scale = Vector2.ZERO
				st.pivot_offset = Vector2(27, 27)
				var tw := create_tween()
				tw.tween_interval(0.25 + i * 0.3)
				tw.tween_property(st, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		v.add_child(row)
		v.add_child(UiKit.label("Finish  /  2 or fewer falls  /  every Chronicle Leaf", 14, Color(0.85, 0.8, 0.7)))
	var secs := int(stats.get("time", 0.0))
	v.add_child(UiKit.label("Time  %d:%02d" % [secs / 60, secs % 60], 22))
	v.add_child(UiKit.label("Chronicle Leaves  %d / %d" % [stats.get("leaves", 0), stats.get("leaves_total", 0)], 22))
	v.add_child(UiKit.label("Falls / defeats  %d" % stats.get("retries", 0), 22))
	v.add_child(UiKit.label("(Chronicle Leaves are fictional game collectibles.)", 15, Color(0.85, 0.8, 0.7)))
	var b := UiKit.button("Continue", func():
		get_tree().paused = false
		complete_continue.emit())
	v.add_child(b)
	_modal = _make_modal(panel)
	b.grab_focus()
