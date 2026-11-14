class_name SpikeTrap
extends Node2D
## Timed spear trap set into the floor. Cycle: rest (safe) -> warn (the tips
## show and rattle) -> up (hurts) -> rest. Position = floor level, centre.
## Fully readable: the warning always lasts long enough to step back or cross.

var period := 2.4
var phase := 0.0
var damage := 12.0
var width := 70.0
var warn_frac := 0.3
var up_frac := 0.28
var _t := 0.0
var _hit_cooldown := 0.0


func _ready() -> void:
	add_to_group("spike")
	_t = phase * period
	z_index = -1


func cycle() -> float:
	return fposmod(_t, period) / period


func is_up() -> bool:
	var c := cycle()
	return c >= warn_frac and c < warn_frac + up_frac


## Seconds until the spears next come up (0 while they are up).
func time_until_up() -> float:
	var c := cycle()
	if is_up():
		return 0.0
	return (warn_frac - c if c < warn_frac else 1.0 - c + warn_frac) * period


func _physics_process(delta: float) -> void:
	var was := is_up()
	_t += delta
	_hit_cooldown = maxf(0.0, _hit_cooldown - delta)
	if is_up() and not was:
		Audio.sfx("spike", 0.1, -10.0 if not _near_player() else -3.0)
	if is_up() and _hit_cooldown <= 0.0:
		for p in get_tree().get_nodes_in_group("player"):
			if p is Player and not p.is_mounted() and absf(p.global_position.x - global_position.x) < width * 0.5 + 8.0 \
					and p.global_position.y > global_position.y - 30.0 and p.global_position.y < global_position.y + 12.0:
				var d := signf(p.global_position.x - global_position.x)
				p.take_hit({"damage": damage, "dir": d if d != 0.0 else 1.0, "knockback": 220.0, "unblockable": true, "source": self})
				_hit_cooldown = 0.6
	queue_redraw()


func _near_player() -> bool:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	return p != null and absf(p.global_position.x - global_position.x) < 700.0


func _draw() -> void:
	var c := cycle()
	var h := 0.0
	if c < warn_frac:
		h = 9.0 * smoothstep(0.0, 0.25, c / warn_frac) + (randf_range(-1.5, 1.5) if c > warn_frac * 0.4 else 0.0)
	elif c < warn_frac + up_frac:
		h = 46.0
	else:
		h = 46.0 * (1.0 - smoothstep(0.0, 0.2, (c - warn_frac - up_frac) / (1.0 - warn_frac - up_frac)))
	# stone slot
	draw_rect(Rect2(-width * 0.5 - 4, -3, width + 8, 9), Color(0.12, 0.09, 0.08))
	draw_rect(Rect2(-width * 0.5 - 4, -3, width + 8, 9), Color(0.5, 0.4, 0.3), false, 1.5)
	if h <= 0.5:
		return
	var n := 5
	for i in n:
		var x := -width * 0.5 + (i + 0.5) * width / n
		draw_line(Vector2(x, 2), Vector2(x, -h + 10), Color("6b4428"), 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 4, -h + 12), Vector2(x + 4, -h + 12), Vector2(x, -h)]), Color("c9ced4"))
	if c < warn_frac:
		draw_arc(Vector2(0, -6), width * 0.55, PI, TAU, 14, Color(1, 0.35, 0.2, 0.35 + 0.4 * c / warn_frac), 2.0)
