class_name Fx
extends RefCounted
## Small, cheap, non-graphic feedback effects (dust, sparks, hit-stop).


static func _root() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.current_scene if tree else null


static func _burst(pos: Vector2, amount: int, color: Color, speed: float, life: float, grav: float, spread: float, dir := Vector2.UP, size := 3.0) -> void:
	var root := _root()
	if root == null or amount <= 0:
		return
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.amount = amount
	p.lifetime = life
	p.explosiveness = 0.95
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, grav)
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	p.color = color
	var ramp := Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(color, 0.0))
	p.color_ramp = ramp
	p.global_position = pos
	p.z_index = 5
	root.add_child(p)
	p.emitting = true
	root.get_tree().create_timer(life + 0.2, false).timeout.connect(p.queue_free)


static func dust(pos: Vector2, amount := 8) -> void:
	effect("dust", pos + Vector2(0, -14), 0.45 + amount * 0.02)
	_burst(pos, amount, Color(0.85, 0.72, 0.52, 0.8), 90.0, 0.45, 120.0, 70.0, Vector2.UP, 4.0)


static func spark(pos: Vector2, color := Color(1, 0.9, 0.6), amount := 10) -> void:
	effect("spark", pos, 0.35 + amount * 0.02)
	_burst(pos, amount, color, 220.0, 0.25, 300.0, 180.0, Vector2.UP, 2.5)


static func pickup(pos: Vector2) -> void:
	_burst(pos, 16, Color(1.0, 0.85, 0.35), 140.0, 0.6, -40.0, 180.0, Vector2.UP, 3.0)


## Brief freeze-frame that sells impact. Uses a real-time timer.
static func hitstop(duration: float) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or Engine.time_scale < 1.0:
		return
	Engine.time_scale = 0.05
	tree.create_timer(duration, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)


## One-shot sprite effect from the asset pack's combat_effects atlas
## (slash / spark / dust / fire). Silently does nothing if the atlas is missing.
static func effect(name: String, pos: Vector2, k := 1.0, flip := false, rot := 0.0) -> void:
	var root := _root()
	var sf := MewarAssets.effect_frames()
	if root == null or sf == null or not sf.has_animation(name):
		return
	var s := AnimatedSprite2D.new()
	s.sprite_frames = sf
	s.global_position = pos
	s.scale = Vector2(-k if flip else k, k)
	s.rotation = rot
	s.z_index = 6
	s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	root.add_child(s)
	s.play(name)
	s.animation_finished.connect(s.queue_free)
