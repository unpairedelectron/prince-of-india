class_name Checkpoint
extends Area2D
## Stone lamp-post (diya stambh). Lights up and saves when reached.
## PLACEHOLDER ART (procedural).

signal reached(cp: Checkpoint)

var index := 0
var mounted := false   ## respawn on Chetak
var active := false
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 | 8
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(80, 160)
	cs.shape = sh
	cs.position = Vector2(0, -80)
	add_child(cs)
	body_entered.connect(_on_body)


func _on_body(b: Node) -> void:
	if active:
		return
	if b is Player or (b is Horse and (b as Horse).rider != null):
		activate()
		reached.emit(self)


func activate(silent := false) -> void:
	active = true
	if not silent:
		Audio.sfx("checkpoint", 0.0, -3.0)
		Fx.pickup(global_position + Vector2(0, -86))


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var ft := MewarAssets.prop("checkpoint")
	if ft:
		var k := 0.85
		modulate = Color.WHITE if active else Color(0.7, 0.7, 0.7)
		draw_texture_rect(ft, Rect2(-64 * k, -122 * k, 128 * k, 128 * k), false)
		if active:
			var sf := MewarAssets.effect_frames()
			if sf:
				var f := int(_t * 10.0) % 4
				draw_circle(Vector2(-18, -16), 16.0, Color(1, 0.6, 0.2, 0.18))
				draw_texture_rect(sf.get_frame_texture("fire", f), Rect2(-36, -44, 36, 36), false)
		return
	var stone := Game.C_SANDSTONE_DARK
	draw_rect(Rect2(-14, -8, 28, 8), stone.darkened(0.2))
	draw_rect(Rect2(-7, -70, 14, 62), stone)
	draw_line(Vector2(-7, -40), Vector2(7, -40), stone.darkened(0.25), 1.0)
	draw_rect(Rect2(-13, -78, 26, 8), stone.lightened(0.1))
	# diya bowl
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -78), Vector2(10, -78), Vector2(6, -84), Vector2(-6, -84)]), Color("8a4b2a"))
	if active:
		var f := 1.0 + 0.15 * sin(_t * 17.0) + 0.1 * sin(_t * 23.0)
		draw_circle(Vector2(0, -92), 14.0 * f, Color(1, 0.6, 0.2, 0.18))
		draw_colored_polygon(PackedVector2Array([Vector2(-4, -84), Vector2(4, -84), Vector2(0, -84 - 13.0 * f)]), Color(1, 0.75, 0.25))
		draw_colored_polygon(PackedVector2Array([Vector2(-2, -84), Vector2(2, -84), Vector2(0, -84 - 7.0 * f)]), Color(1, 0.95, 0.7))
