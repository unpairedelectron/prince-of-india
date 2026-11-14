class_name SettingsPanel
extends PanelContainer
## Shared settings: touch button opacity & size, touch controls mode, volumes.

signal closed


func _ready() -> void:
	theme = UiKit.theme()
	process_mode = Node.PROCESS_MODE_ALWAYS
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	add_child(v)
	v.add_child(UiKit.label("Settings", 34, Game.C_GOLD))
	v.add_child(_slider("Button opacity", "button_opacity", 0.15, 1.0))
	v.add_child(_slider("Button size", "button_scale", 0.75, 1.3))
	v.add_child(_slider("Music volume", "music_volume", 0.0, 1.0))
	v.add_child(_slider("Effects volume", "sfx_volume", 0.0, 1.0))
	var h := HBoxContainer.new()
	h.add_child(UiKit.label("Touch controls", 22, Color("f3e3c0"), HORIZONTAL_ALIGNMENT_LEFT))
	var opt := OptionButton.new()
	for o in ["auto", "on", "off"]:
		opt.add_item(o.capitalize())
	opt.selected = ["auto", "on", "off"].find(Game.settings.touch_controls)
	opt.item_selected.connect(func(i): Game.set_setting("touch_controls", ["auto", "on", "off"][i]))
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(opt)
	v.add_child(h)
	v.add_child(UiKit.button("Close", _close))


func _slider(text: String, key: String, lo: float, hi: float) -> Control:
	var h := HBoxContainer.new()
	var l := UiKit.label(text, 22, Color("f3e3c0"), HORIZONTAL_ALIGNMENT_LEFT)
	l.custom_minimum_size.x = 220
	h.add_child(l)
	var s := HSlider.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 0.05
	s.value = Game.settings[key]
	s.custom_minimum_size = Vector2(260, 40)
	s.value_changed.connect(func(val): Game.set_setting(key, val))
	h.add_child(s)
	return h


func _close() -> void:
	closed.emit()
	queue_free()
