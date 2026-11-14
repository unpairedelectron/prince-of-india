extends Control
## Narrative card sequence. Reads Game.pending_story, then goes to
## Game.pending_next_scene. Every card shows its label (history / tradition / fiction).

var _pages: Array = []
var _i := 0
var _tag: Label
var _title: Label
var _body: Label
var _hint: Label
var _box: VBoxContainer


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.09, 0.07, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var deco := _StoryBackdrop.new()
	deco.set_anchors_preset(Control.PRESET_FULL_RECT)
	deco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(deco)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_box = VBoxContainer.new()
	_box.custom_minimum_size = Vector2(820, 0)
	_box.add_theme_constant_override("separation", 18)
	center.add_child(_box)
	_tag = UiKit.label("", 18, Game.C_SAFFRON)
	_title = UiKit.label("", 40, Game.C_GOLD)
	_body = UiKit.label("", 26)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint = UiKit.label("Tap or press any key to continue", 16, Color(0.8, 0.75, 0.65))
	for n in [_tag, _title, _body, _hint]:
		_box.add_child(n)
	var skip := UiKit.button("Skip", _finish, 140)
	skip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip.position = Vector2(-170, 20)
	add_child(skip)
	_pages = Game.pending_story
	if _pages.is_empty():
		_finish()
		return
	_show()


func _show() -> void:
	var p: Dictionary = _pages[_i]
	_tag.text = "[ " + p.get("tag", "") + " ]"
	_title.text = p.get("title", "")
	_body.text = p.get("body", "")
	_box.modulate.a = 0.0
	create_tween().tween_property(_box, "modulate:a", 1.0, 0.5)


func _unhandled_input(e: InputEvent) -> void:
	var go: bool = (e is InputEventKey and e.pressed and not e.echo) or (e is InputEventMouseButton and e.pressed) or (e is InputEventJoypadButton and e.pressed)
	if not go:
		return
	get_viewport().set_input_as_handled()
	Audio.sfx("ui", 0.02, -8.0)
	_i += 1
	if _i >= _pages.size():
		_finish()
	else:
		_show()


func _finish() -> void:
	var next := Game.pending_next_scene
	Game.pending_story = []
	if next == "":
		next = Game.SCENE_MENU
	if next in Game.MISSIONS.values():
		Game.mission_start_msec = Time.get_ticks_msec()
	Game.goto(next)


class _StoryBackdrop extends Control:
	func _draw() -> void:
		var s := size
		var col := Color(0.25, 0.18, 0.2)
		var pts := PackedVector2Array([Vector2(0, s.y)])
		var x := 0.0
		while x <= s.x:
			pts.append(Vector2(x, s.y * 0.78 - sin(x * 0.006) * 40.0 - sin(x * 0.017) * 18.0))
			x += 20.0
		pts.append(Vector2(s.x, s.y))
		draw_colored_polygon(pts, col)
		draw_line(Vector2(s.x * 0.2, 70), Vector2(s.x * 0.8, 70), Color(Game.C_GOLD, 0.5), 2.0)
		draw_line(Vector2(s.x * 0.2, s.y - 60), Vector2(s.x * 0.8, s.y - 60), Color(Game.C_GOLD, 0.5), 2.0)
