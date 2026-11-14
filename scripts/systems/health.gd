class_name Health
extends Node
## Reusable health component. Emits signals; owners decide how to react.

signal changed(current: float, maximum: float)
signal damaged(amount: float)
signal died

@export var max_health := 100.0
var current := 100.0
var invulnerable := false


func _ready() -> void:
	current = max_health


func is_dead() -> bool:
	return current <= 0.0


func damage(amount: float) -> bool:
	if invulnerable or is_dead() or amount <= 0.0:
		return false
	current = maxf(0.0, current - amount)
	damaged.emit(amount)
	changed.emit(current, max_health)
	if current <= 0.0:
		died.emit()
	return true


func heal(amount: float) -> void:
	if is_dead():
		return
	current = minf(max_health, current + amount)
	changed.emit(current, max_health)


func restore_full() -> void:
	current = max_health
	changed.emit(current, max_health)
