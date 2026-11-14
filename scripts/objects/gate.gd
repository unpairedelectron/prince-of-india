class_name Gate
extends StaticBody2D
## Wooden fort gate with iron studs. Rises when opened.

signal opened

var size := Vector2(36, 220)
var is_open := false
var layer_bits := 1
var _closed_y := 0.0


func _ready() -> void:
	collision_layer = layer_bits
	collision_mask = 0
	_closed_y = position.y
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	cs.position = Vector2(0, -size.y * 0.5)
	add_child(cs)


func set_open_instant() -> void:
	is_open = true
	position.y = _closed_y - size.y + 20.0
	collision_layer = 0


func close() -> void:
	if not is_open:
		return
	is_open = false
	collision_layer = layer_bits
	Audio.sfx("gate", 0.0, -4.0)
	var tw := create_tween()
	tw.tween_property(self, "position:y", _closed_y, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func open() -> void:
	if is_open:
		return
	is_open = true
	Audio.sfx("gate", 0.0, -2.0)
	CameraRig.shake_global(3.0)
	var tw := create_tween()
	tw.tween_property(self, "position:y", position.y - size.y + 20.0, 1.2).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(_after_open)
	opened.emit()


func _draw() -> void:
	var gt := MewarAssets.tile("gate_panel")
	if gt:
		var y := -size.y
		while y < 0.0:
			var hh := minf(64.0, -y)
			draw_texture_rect_region(gt.atlas, Rect2(-size.x * 0.5, y, size.x, hh), Rect2(gt.region.position + Vector2(14, 6), Vector2(36, hh * 58.0 / 64.0)))
			y += 58.0
		draw_rect(Rect2(-size.x * 0.5, -size.y, size.x, size.y), Color("3a2418"), false, 3.0)
		return
	var wood := Color("5a3820")
	draw_rect(Rect2(-size.x * 0.5, -size.y, size.x, size.y), wood)
	var y := -size.y + 18.0
	while y < -6.0:
		draw_line(Vector2(-size.x * 0.5, y), Vector2(size.x * 0.5, y), wood.darkened(0.3), 2.0)
		draw_circle(Vector2(-size.x * 0.25, y + 9), 2.5, Game.C_SILVER.darkened(0.3))
		draw_circle(Vector2(size.x * 0.25, y + 9), 2.5, Game.C_SILVER.darkened(0.3))
		y += 26.0
	draw_rect(Rect2(-size.x * 0.5, -size.y, size.x, size.y), wood.darkened(0.45), false, 3.0)


func _after_open() -> void:
	if is_open:
		collision_layer = 0
