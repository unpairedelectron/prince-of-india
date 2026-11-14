class_name TouchControls
extends CanvasLayer
## Landscape touch layout. Left: move (plus up/down only near ladders).
## Right: jump / attack / block / dodge, plus a contextual button
## (Mount, Climb, Interact). When mounted the right side becomes
## Jump / Gallop / Dismount. Positions respect safe areas and the
## size/opacity settings, and are rebuilt on resize.

var buttons := {}
var _mounted := false
var _context := ""
var _ladder := false


func _ready() -> void:
	layer = 50
	for spec in [
		["left", "left", "move_left", true], ["right", "right", "move_right", true],
		["up", "up", "move_up", true], ["down", "down", "move_down", true],
		["jump", "jump", "jump", false], ["attack", "attack", "attack", false],
		["block", "block", "block", false], ["dodge", "dodge", "dodge", false],
		["context", "context", "interact", false],
		["h_jump", "jump", "jump", false], ["gallop", "gallop", "gallop", false],
	]:
		var b := TouchButton.new()
		b.name = spec[0]
		add_child(b)
		b.configure(50, spec[1], spec[2], spec[3])
		buttons[spec[0]] = b
	get_viewport().size_changed.connect(layout)
	Game.settings_changed.connect(layout)
	layout()


func set_state(mounted: bool, context: String, ladder: bool) -> void:
	if mounted == _mounted and context == _context and ladder == _ladder:
		return
	_mounted = mounted
	_context = context
	_ladder = ladder
	layout()


func layout() -> void:
	visible = Game.touch_controls_enabled()
	var vs := get_viewport().get_visible_rect().size
	var m := UiKit.safe_margins(get_viewport())
	var k: float = Game.settings.button_scale
	var bl := Vector2(m.left + 24.0, vs.y - m.bottom - 16.0)
	var br := Vector2(vs.x - m.right - 24.0, vs.y - m.bottom - 16.0)
	var spec := {
		# name: [anchor, offset, radius, visible]
		"left": [bl, Vector2(90, -110), 62, true],
		"right": [bl, Vector2(250, -110), 62, true],
		"up": [bl, Vector2(90, -270), 46, _ladder and not _mounted],
		"down": [bl, Vector2(250, -270), 46, _ladder and not _mounted],
		"attack": [br, Vector2(-110, -130), 64, not _mounted],
		"jump": [br, Vector2(-270, -85), 58, not _mounted],
		"block": [br, Vector2(-90, -300), 50, not _mounted],
		"dodge": [br, Vector2(-250, -255), 46, not _mounted],
		"h_jump": [br, Vector2(-110, -130), 66, _mounted],
		"gallop": [br, Vector2(-270, -85), 60, _mounted],
		"context": [br, Vector2(-410, -100), 44, _context != ""],
	}
	for n in spec:
		var s: Array = spec[n]
		var b: TouchButton = buttons[n]
		b.position = s[0] + s[1] * k
		b.configure(s[2] * k, b.glyph, b.action, b.passby_press)
		b.visible = s[3]
	var ctx: TouchButton = buttons.context
	ctx.caption = _context.split(" ")[0].to_upper() if _context != "" else ""
	ctx.action = "mount" if _mounted or _context.begins_with("Mount") else "interact"
	ctx.queue_redraw()
