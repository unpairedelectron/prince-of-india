class_name ScreenBackdrop
extends Node2D
## Screen-space painted background (asset-pack 1600x600 scenes and silhouettes).
## Drawn in a CanvasLayer so its placement is independent of camera zoom:
## the image bottom sits at `bottom_frac` of the screen height, it repeats
## horizontally and scrolls at `scroll` x the camera movement (parallax).

var texture: Texture2D
var scroll := Vector2(0.06, 0.1)
var bottom_frac := 0.8      ## image bottom as a fraction of viewport height
var height_frac := 0.85     ## image height as a fraction of viewport height
var tint := Color.WHITE
var _ref := Vector2.INF


func _process(_d: float) -> void:
	queue_redraw()


func _draw() -> void:
	if texture == null:
		return
	var vs := get_viewport_rect().size
	var cam := CameraRig.current
	var cpos := cam.global_position if cam else Vector2.ZERO
	if _ref == Vector2.INF:
		_ref = cpos
	var k := vs.y * height_frac / texture.get_height()
	var w := texture.get_width() * k
	var h := texture.get_height() * k
	var ox := fposmod(-cpos.x * scroll.x * k, w)
	var oy := clampf(-(cpos.y - _ref.y) * scroll.y, -vs.y * 0.15, vs.y * 0.25)
	var y := vs.y * bottom_frac - h + oy
	var x := ox - w
	while x < vs.x:
		draw_texture_rect(texture, Rect2(x, y, w + 1.0, h), false, tint)
		x += w
