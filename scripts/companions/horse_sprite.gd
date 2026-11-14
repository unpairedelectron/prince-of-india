class_name HorseSprite
extends HorseRig
## Chetak driven by the asset-pack atlas (idle, walk, gallop, jump). Keeps the
## HorseRig API so the Horse controller is unchanged. States the pack lacks
## (trot, rear, land, rest) are mapped onto existing frames - see ASSET_INTEGRATION.md.

@export var sprite_scale := 0.72
## frame pixel under the hooves (centre of body); feet baseline ~y124 in 192x128 frames
@export var foot_pivot := Vector2(98, 124)
## saddle top in frame pixels (orange saddle-cloth)
@export var saddle_px := Vector2(94, 40)

var sprite: AnimatedSprite2D
var _use_sprite := false
var _tilt := 0.0


func _ready() -> void:
	var sf := MewarAssets.frames("chetak")
	if sf == null:
		return
	_use_sprite = true
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = sf
	sprite.centered = false
	sprite.offset = -foot_pivot
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)
	sprite.play("idle")


func rider_drop() -> float:
	return 6.0 if _use_sprite else 46.0


func saddle_point() -> Vector2:
	if not _use_sprite:
		return super.saddle_point()
	var p := (saddle_px - foot_pivot) * sprite_scale
	return Vector2(p.x, p.y + sprite.position.y)


func _process(delta: float) -> void:
	if not _use_sprite:
		super._process(delta)
		return
	anim_time += delta
	var tilt := 0.0
	var a := "idle"
	var spd := 1.0
	match anim:
		"walk": a = "walk"
		"trot":                     # MISSING in pack: walk cycle played faster
			a = "walk"
			spd = 1.6
		"gallop":
			a = "gallop"
			spd = 1.0 + speed_ratio * 0.6
		"jump":
			a = "jump"
			tilt = -0.1
		"fall":
			a = "jump"
			tilt = 0.08
		"land": a = "gallop"
		"rear":                     # MISSING in pack: idle frame pitched back on hind legs
			a = "idle"
			tilt = -0.32
		"rest", "settled":          # MISSING lying pose: Chetak stands quietly, slow breathing
			a = "idle"
			spd = 0.35
		_: a = "idle"
	if sprite.animation != a:
		sprite.play(a)
	sprite.speed_scale = spd
	_tilt = lerpf(_tilt, tilt, 1.0 - exp(-10.0 * delta))
	sprite.rotation = _tilt
	queue_redraw()


func _draw() -> void:
	if not _use_sprite:
		super._draw()
