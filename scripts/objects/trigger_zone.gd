class_name TriggerZone
extends Area2D
## Invisible rectangle that fires once (or every time) the player enters.

signal triggered(zone: TriggerZone, body: Node)

var size := Vector2(60, 300)
var once := true
var id := ""
var _fired := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2 | 8
	var cs := CollisionShape2D.new()
	var sh := RectangleShape2D.new()
	sh.size = size
	cs.shape = sh
	cs.position = Vector2(0, -size.y * 0.5)
	add_child(cs)
	body_entered.connect(_on_body)


func _on_body(b: Node) -> void:
	if once and _fired:
		return
	if b is Player or b is Horse:
		_fired = true
		triggered.emit(self, b)
