class_name KillZone
extends Area2D
## Bottom-of-pit sensor. The mission decides how to respawn.

signal fell(body: Node)

var size := Vector2(1000, 100)


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 | 4 | 8
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	cs.position = size * 0.5
	add_child(cs)
	body_entered.connect(func(b): fell.emit(b))
