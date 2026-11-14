extends Area2D
## Arrow projectile. Blockable with the shield (player block faces it), dodgeable,
## and stopped by rocks/walls - so terrain works as cover.

var team := "imperial"
var damage := 9.0
var velocity := Vector2(600, 0)
var shooter: Node2D
var style := "arrow"   ## arrow | ball (musket shot: flat and fast)
var _life := 3.0
var _stuck := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | ((2 | 64) if team == "imperial" else 4)
	monitoring = true
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = Vector2(26, 6)
	cs.shape = sh
	add_child(cs)
	body_entered.connect(_on_body)
	rotation = velocity.angle()
	z_index = 4


func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	if _stuck:
		modulate.a = minf(1.0, _life)
		return
	if style == "arrow":
		velocity.y += 380.0 * delta
	position += velocity * delta
	rotation = velocity.angle()


func _on_body(b: Node) -> void:
	if _stuck or b == shooter:
		return
	if b.has_method("take_hit"):
		if b is Soldier and (b as Soldier).team == team:
			return
		var dir := signf(velocity.x) if velocity.x != 0.0 else 1.0
		b.take_hit({"damage": damage, "dir": dir, "knockback": 90.0, "source": self, "stagger": 0.2})
		queue_free()
	elif b is StaticBody2D or b is AnimatableBody2D:
		_stuck = true
		_life = 1.2
		set_deferred("monitoring", false)


func _draw() -> void:
	if style == "ball":
		draw_line(Vector2(-22, 0), Vector2(0, 0), Color(1, 0.9, 0.6, 0.5), 2.0)
		draw_circle(Vector2.ZERO, 3.5, Color("2a2a2e"))
		return
	draw_line(Vector2(-13, 0), Vector2(11, 0), Color("6b4428"), 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(11, -3), Vector2(17, 0), Vector2(11, 3)]), Color("b8bec6"))
	draw_line(Vector2(-13, 0), Vector2(-17, -3), Color("e8e2d0"), 2.0)
	draw_line(Vector2(-13, 0), Vector2(-17, 3), Color("e8e2d0"), 2.0)
