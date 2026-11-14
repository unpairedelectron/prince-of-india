class_name Collectible
extends Area2D
## Chronicle Leaf (FICTIONAL game collectible, not a historical artefact)
## or a water pouch supply that restores health.

signal collected(c: Collectible)

var id := ""
var kind := "leaf"   # leaf | supply
var heal := 35.0
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 | 8
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 26.0 if kind == "leaf" else 22.0
	cs.shape = sh
	add_child(cs)
	body_entered.connect(_on_body)
	_t = randf() * 3.0


func _on_body(b: Node) -> void:
	var p: Player = null
	if b is Player:
		p = b
	elif b is Horse and (b as Horse).rider:
		p = (b as Horse).rider
	if p == null:
		return
	if kind == "supply":
		if p.health.current >= p.health.max_health:
			return
		p.health.heal(heal)
	Audio.sfx("collect" if kind == "leaf" else "supply", 0.05, -2.0)
	Fx.pickup(global_position)
	collected.emit(self)
	queue_free()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var y := sin(_t * 2.5) * 4.0
	if kind == "leaf":
		draw_circle(Vector2(0, y), 20.0, Color(1, 0.8, 0.3, 0.15 + 0.08 * sin(_t * 4.0)))
		# palm-leaf manuscript (pothi) shape
		draw_rect(Rect2(-16, y - 6, 32, 12), Color("e8d39a"))
		draw_rect(Rect2(-16, y - 6, 32, 12), Game.C_GOLD, false, 1.5)
		draw_line(Vector2(-12, y - 2), Vector2(12, y - 2), Color("7a4a2a"), 1.0)
		draw_line(Vector2(-12, y + 2), Vector2(8, y + 2), Color("7a4a2a"), 1.0)
		draw_circle(Vector2(0, y), 1.8, Color("7a2630"))
	elif MewarAssets.prop("pot"):
		# clay water pot (asset pack "pot"), restores health
		draw_circle(Vector2(0, y), 22.0, Color(0.6, 0.9, 1.0, 0.12 + 0.06 * sin(_t * 4.0)))
		draw_texture_rect(MewarAssets.prop("pot"), Rect2(-24, y - 30, 48, 48), false)
	else:
		# leather water pouch (mashak)
		draw_circle(Vector2(0, y + 3), 10.0, Color("6b4428"))
		draw_rect(Rect2(-4, y - 12, 8, 8), Color("6b4428").darkened(0.2))
		draw_line(Vector2(-8, y - 8), Vector2(8, y - 8), Game.C_SAFFRON, 2.0)
		draw_circle(Vector2(-3, y + 1), 2.5, Color(1, 1, 1, 0.3))
