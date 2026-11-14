class_name SpriteRig
extends HumanRig
## Drives a human character with the Mewar asset-pack sprite atlas while keeping
## HumanRig's API (play / set_progress / speed_ratio / swoosh / weapon...), so the
## Player and Soldier controllers are unchanged.
## The atlas has 8 animations (Pratap) or 4 (imperial soldier). Every other game
## state is mapped onto the nearest frames plus a small transform - see MAPPING
## and documentation/ASSET_INTEGRATION.md. If the atlas is missing, falls back to
## the procedural HumanRig drawing automatically.

@export var sheet := "pratap"
@export var sprite_scale := 0.66
## pixel in the 128x160 frame that sits on the character's feet origin
@export var foot_pivot := Vector2(60, 152)

var sprite: AnimatedSprite2D
var rider_crop: Sprite2D
var _use_sprite := false
var _cur := ""
var _fx_tilt := 0.0
var _squash := Vector2.ONE
var _offset_y := 0.0
var _last_anim := ""
var _standee := false


func _ready() -> void:
	super._ready()
	var sf := MewarAssets.frames(sheet)
	if sf == null:
		return   # fallback: procedural HumanRig
	_use_sprite = true
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = sf
	sprite.centered = false
	sprite.offset = -foot_pivot
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)
	sprite.play("idle")
	if sheet == "pratap":
		# Mounted pose: the atlas has no riding frames, so show the upper body
		# (head to waist) of the idle frame seated in Chetak's saddle.
		rider_crop = Sprite2D.new()
		rider_crop.texture = MewarAssets.frame_region("pratap", "idle", 0, Rect2(0, 0, 128, 100))
		rider_crop.centered = false
		rider_crop.offset = Vector2(-foot_pivot.x, -100)
		rider_crop.scale = Vector2.ONE * sprite_scale
		rider_crop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		rider_crop.visible = false
		add_child(rider_crop)


## Revert to procedural drawing (for characters the pack has no art for).
func disable_sprite() -> void:
	if sprite:
		sprite.queue_free()
		sprite = null
	if rider_crop:
		rider_crop.queue_free()
		rider_crop = null
	_use_sprite = false


## Use a single standee image (allies). Frames are reused for every state and
## motion comes from transforms (bob, lean, squash). Pack provides no ally animation.
func use_standee(t: Texture2D, pivot := Vector2(64, 152)) -> void:
	if t == null:
		disable_sprite()
		return
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for a in ["idle", "walk", "attack", "hurt"]:
		sf.add_animation(a)
		sf.add_frame(a, t)
	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.centered = false
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(sprite)
	sprite.sprite_frames = sf
	sprite.offset = -pivot
	_cur = ""
	_standee = true
	_use_sprite = true


func uses_sprite() -> bool:
	return _use_sprite


func _process(delta: float) -> void:
	if not _use_sprite:
		super._process(delta)
		return
	anim_time += delta
	swoosh = maxf(0.0, swoosh - delta * 4.0)
	_apply_state(delta)
	queue_redraw()


func _show(a: String, speed := 1.0) -> void:
	if not sprite.sprite_frames.has_animation(a):
		a = "idle"
	if _cur != a:
		_cur = a
		sprite.play(a)
	sprite.speed_scale = speed


func _hold(a: String, frame: int) -> void:
	if not sprite.sprite_frames.has_animation(a):
		a = "idle"
	_cur = a + "#hold"
	sprite.animation = a
	sprite.frame = clampi(frame, 0, sprite.sprite_frames.get_frame_count(a) - 1)
	sprite.pause()


func _by_progress(a: String) -> void:
	_hold(a, int(clampf(progress, 0.0, 0.999) * 4.0))


## MAPPING game state -> atlas frames (+ transform for states the pack lacks).
func _apply_state(delta: float) -> void:
	var tilt := 0.0
	var sq := Vector2.ONE
	var oy := 0.0
	var mounted := anim == "mounted"
	sprite.visible = not mounted
	if rider_crop:
		rider_crop.visible = mounted
	match anim:
		"idle": _show("idle")
		"walk": _show("walk")
		"run": _show("run")
		"sprint": _show("run", 1.45)
		"jump": _hold("jump", 1)
		"fall": _hold("jump", 3)
		"land":
			_hold("idle", 0)
			sq = Vector2(1.08, 0.9)
		"crouch", "crouch_walk":       # MISSING in pack: squashed idle/walk
			_show("walk" if anim == "crouch_walk" else "idle", 0.7)
			sq = Vector2(1.06, 0.7)
		"climb":                        # MISSING in pack: block frames, gentle bob
			_hold("block", int(anim_time * 6.0) % 4 if speed_ratio > 0.05 else 0)
			oy = sin(anim_time * 10.0) * 2.0 * speed_ratio
		"attack1", "attack2", "attack3":
			_by_progress("attack" if sheet == "pratap" else "attack")
			if anim == "attack3":
				tilt = 0.08
		"heavy_windup", "telegraph":
			_hold("attack", 0 if sheet == "pratap" else 1)
			tilt = -0.08
			oy = sin(anim_time * 40.0) * 1.0
		"heavy":
			_by_progress("attack")
			tilt = 0.14 * sin(minf(progress * 2.0, 1.0) * PI)
		"block":
			if sprite.sprite_frames.has_animation("block"):
				_show("block")
			else:                       # MISSING for soldier: braced idle
				_hold("idle", 0)
				tilt = -0.06
		"parry":
			_hold("block" if sprite.sprite_frames.has_animation("block") else "idle", 0)
			tilt = 0.06
		"dodge":                        # MISSING in pack: fast run frames + low lean
			_show("run" if sprite.sprite_frames.has_animation("run") else "walk", 2.0)
			tilt = 0.45
			sq = Vector2(1.05, 0.82)
		"hurt": _show("hurt")
		"defeated", "yield":            # MISSING in pack: last hurt frame, kneeling sink
			_hold("hurt", 3)
			oy = 18.0
			tilt = 0.18
			sq = Vector2(1.0, 0.82)
		"victory":
			if sprite.sprite_frames.has_animation("victory"):
				_show("victory")
			else:
				_hold("idle", 0)
		"interact":                     # MISSING in pack
			_hold("idle", 1)
			tilt = 0.06
		"mounted":
			if rider_crop:
				rider_crop.position.y = -bob_for_mount()
		"aim": _hold("attack", 1)
		_: _show("idle")
	if _standee:
		# no frames: suggest motion with bob and lean
		if anim in ["walk", "run"]:
			oy = -absf(sin(anim_time * 9.0)) * 3.0
			tilt += 0.04
		elif anim.begins_with("attack") or anim == "heavy":
			tilt += 0.18 * sin(clampf(progress, 0.0, 1.0) * PI)
		elif anim in ["telegraph", "aim"]:
			tilt -= 0.1
	var w := 1.0 - exp(-18.0 * delta)
	_fx_tilt = lerpf(_fx_tilt, tilt, w)
	_squash = _squash.lerp(sq, w)
	_offset_y = lerpf(_offset_y, oy, w)
	sprite.rotation = _fx_tilt
	sprite.scale = Vector2.ONE * sprite_scale * _squash
	sprite.position.y = _offset_y


func bob_for_mount() -> float:
	return sin(anim_time * (6.0 + speed_ratio * 10.0)) * speed_ratio * 2.0


func _draw() -> void:
	if not _use_sprite:
		super._draw()
		return
	# soft contact shadow is part of the atlas frames; only draw the sword trail
	if swoosh > 0.0 and not show_sword == false:
		var c := Color(1, 0.95, 0.8, swoosh * 0.5)
		draw_arc(Vector2(10, -70), 62.0, -PI * 0.55, PI * 0.35, 18, c, 5.0 * swoosh)
