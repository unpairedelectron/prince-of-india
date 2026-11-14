extends Area2D
## Interact point for the quiet farewell at the end of Mission 3.

signal done

var _used := false


func get_prompt() -> String:
	return "Stay a while"


func can_interact(_p: Node) -> bool:
	return not _used


func interact(_p: Node) -> void:
	if _used:
		return
	_used = true
	done.emit()
