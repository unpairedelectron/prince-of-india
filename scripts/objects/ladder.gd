class_name Ladder
extends Area2D
## Wooden ladder. Position = centre. Player climbs with up/down.

var height := 200.0


func _ready() -> void:
	add_to_group("ladder")
	set_meta("height", height)
	collision_layer = 32
	collision_mask = 0
	monitorable = true
	monitoring = false
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(34, height + 20.0)
	cs.shape = sh
	add_child(cs)


func _draw() -> void:
	var lt := MewarAssets.prop("ladder")
	if lt:
		# prop cell 128x128 with rails ~x38-90; stack 64px-high slices
		var h0 := height * 0.5
		var y := -h0 - 14.0
		while y < h0:
			var hh := minf(64.0, h0 - y)
			draw_texture_rect_region((lt as AtlasTexture).atlas, Rect2(-26, y, 52, hh), Rect2((lt as AtlasTexture).region.position + Vector2(38, 24), Vector2(52, hh * 80.0 / 64.0)))
			y += 64.0
		return
	var wood := Color("7a5030")
	var h := height * 0.5
	draw_line(Vector2(-13, -h - 10), Vector2(-13, h), wood, 4.0)
	draw_line(Vector2(13, -h - 10), Vector2(13, h), wood, 4.0)
	var y := h - 14.0
	while y > -h - 6.0:
		draw_line(Vector2(-13, y), Vector2(13, y), wood.lightened(0.1), 3.0)
		y -= 24.0
	# rope lashings
	draw_circle(Vector2(-13, -h - 6), 3.0, Color("c9a86a"))
	draw_circle(Vector2(13, -h - 6), 3.0, Color("c9a86a"))
