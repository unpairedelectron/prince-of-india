class_name HorseRig
extends Node2D
## PLACEHOLDER ART: procedural Chetak - light blue-grey coat, indigo saddle
## with gold trim, saffron saddle-cloth and plume. Origin = ground under hooves.
## Animations: idle, settled, walk, trot, gallop, jump, land, rear, turn.

var anim := "idle"
var anim_time := 0.0
var speed_ratio := 0.0
var head_look := 0.0   ## -1..1, turns head toward rider when idle

var coat := Color("b9bcc4")
var coat_dark := Color("8f939d")
var mane := Color("e9e6df")
var saddle := Game.C_INDIGO
var cloth := Game.C_SAFFRON
var gold := Game.C_GOLD
var leather := Color("3a2418")

var _phase := 0.0
var _pitch := 0.0
var _bob := 0.0
var _rear := 0.0
var _tuck := 0.0
var _rest := 0.0


func play(a: String) -> void:
	if a != anim:
		anim = a
		anim_time = 0.0


func _process(delta: float) -> void:
	anim_time += delta
	var rate := 0.0
	var tgt_pitch := 0.0
	var tgt_rear := 0.0
	var tgt_tuck := 0.0
	match anim:
		"walk": rate = 6.0
		"trot": rate = 10.0
		"gallop": rate = 14.0
		"jump":
			tgt_pitch = -0.12
			tgt_tuck = 1.0
		"fall":
			tgt_pitch = 0.1
			tgt_tuck = 0.5
		"land": tgt_pitch = 0.05
		"rear": tgt_rear = 1.0
		"rest": pass
	_phase += rate * delta
	var w := 1.0 - exp(-10.0 * delta)
	_pitch = lerpf(_pitch, tgt_pitch, w)
	_rear = lerpf(_rear, tgt_rear, 1.0 - exp(-6.0 * delta))
	_tuck = lerpf(_tuck, tgt_tuck, w)
	_rest = lerpf(_rest, 1.0 if anim == "rest" else 0.0, 1.0 - exp(-1.2 * delta))
	match anim:
		"gallop": _bob = sin(_phase) * 4.0
		"trot": _bob = absf(sin(_phase)) * -3.0
		"walk": _bob = sin(_phase * 2.0) * 1.0
		_: _bob = lerpf(_bob, sin(anim_time * 1.8) * 0.8, w)
	queue_redraw()


## Vertical distance from the saddle point down to the rider node's origin.
func rider_drop() -> float:
	return 46.0


## Saddle position for the rider, in local coords (unflipped).
func saddle_point() -> Vector2:
	return Vector2(-4, -86 + _bob)


func _leg(top: Vector2, a1: float, a2: float, front: bool, col: Color) -> void:
	var u := top + HumanRig.dir(a1) * 24.0
	var b := u + HumanRig.dir(a1 + a2) * 25.0
	draw_line(top, u, col, 7.0 if front else 8.0)
	draw_circle(u, 3.5, col)
	draw_line(u, b, col, 4.5)
	draw_rect(Rect2(b + Vector2(-3.5, -3), Vector2(8, 5)), Color("2a2522"))


func _leg_angles(offset: float, hind: bool) -> Vector2:
	if _rest > 0.05:
		# lying down, legs folded beneath (calm resting pose, no injury shown)
		return Vector2((1.45 if not hind else -1.45) * _rest, (-2.75 if not hind else 2.75) * _rest)
	if _tuck > 0.05:
		return Vector2((-0.9 if not hind else 0.6) * _tuck, (1.4 if not hind else -1.0) * _tuck)
	var amp := 0.0
	match anim:
		"walk": amp = 0.3
		"trot": amp = 0.55
		"gallop": amp = 0.85
	var p := _phase + offset * TAU
	var a := sin(p) * amp
	var k := maxf(0.0, cos(p)) * amp * (1.2 if not hind else -1.0)
	return Vector2(a, k)


func _draw() -> void:
	# shadow
	draw_set_transform(Vector2(0, 2), 0, Vector2(1, 0.22))
	draw_circle(Vector2.ZERO, 52.0, Color(0, 0, 0, 0.22))
	var rot := _pitch - _rear * 0.55
	var pivot := Vector2(-34, -40)
	draw_set_transform(pivot + Vector2(0, _bob + _rest * 30.0), rot, Vector2.ONE)
	var o := -pivot   # draw relative to pivot so rearing rotates on hind legs

	# far legs
	var fl := _leg_angles(0.1, false)
	var hl := _leg_angles(0.6, true)
	if _rest < 0.5:
		_leg(o + Vector2(30, -48), fl.x, fl.y, false, coat_dark)
		_leg(o + Vector2(-34, -50), hl.x, hl.y, false, coat_dark)

	# tail
	var sway := sin(anim_time * 2.4) * 4.0 + speed_ratio * -8.0
	draw_polyline(PackedVector2Array([o + Vector2(-46, -70), o + Vector2(-58, -64 + sway * 0.3), o + Vector2(-64 + sway, -46), o + Vector2(-62 + sway * 1.5, -30)]), mane, 7.0)

	# body
	var body := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		body.append(o + Vector2(cos(a) * 48.0, -60.0 + sin(a) * 18.0))
	draw_colored_polygon(body, coat)
	# dapples
	for d in [Vector2(-28, -64), Vector2(-14, -54), Vector2(4, -66), Vector2(18, -55), Vector2(-36, -52)]:
		draw_circle(o + d, 4.0, coat_dark.lerp(coat, 0.5))
	# neck + head
	var look := head_look * 0.15 if anim in ["idle", "settled"] else 0.0
	var nod := sin(anim_time * (2.0 if anim == "idle" else _phase_rate())) * 2.0 * (1.0 - _rest) + _rest * 4.0
	var neck_base := o + Vector2(34, -68)
	var head_pos := o + Vector2(62, -108 + nod) + Vector2(look * 30.0, absf(look) * 8.0)
	draw_colored_polygon(PackedVector2Array([neck_base + Vector2(-12, 6), neck_base + Vector2(10, 10), head_pos + Vector2(4, 8), head_pos + Vector2(-8, -2)]), coat)
	# mane along neck
	draw_line(neck_base + Vector2(-12, 4), head_pos + Vector2(-8, -4), mane, 5.0)
	# head
	draw_colored_polygon(PackedVector2Array([head_pos + Vector2(-8, -6), head_pos + Vector2(4, -10), head_pos + Vector2(24, 6), head_pos + Vector2(22, 13), head_pos + Vector2(6, 12), head_pos + Vector2(-6, 6)]), coat)
	draw_colored_polygon(PackedVector2Array([head_pos + Vector2(-2, -8), head_pos + Vector2(2, -18), head_pos + Vector2(5, -8)]), coat_dark)  # ear
	draw_circle(head_pos + Vector2(8, -2), 1.8, Color(0.08, 0.06, 0.05))
	# bridle + plume (kalangi)
	draw_line(head_pos + Vector2(-4, -6), head_pos + Vector2(20, 9), leather, 2.0)
	draw_line(head_pos + Vector2(4, -8), head_pos + Vector2(6, 11), leather, 2.0)
	draw_circle(head_pos + Vector2(5, 1), 2.0, gold)
	draw_line(head_pos + Vector2(0, -10), head_pos + Vector2(-6, -24), cloth, 3.0)
	draw_circle(head_pos + Vector2(-6, -25), 3.0, cloth)
	# reins
	draw_line(head_pos + Vector2(16, 8), o + Vector2(6, -84), leather, 1.5)

	# saddle-cloth + saddle
	draw_colored_polygon(PackedVector2Array([o + Vector2(-26, -76), o + Vector2(18, -76), o + Vector2(22, -46), o + Vector2(-30, -46)]), cloth)
	for i in 6:
		draw_line(o + Vector2(-28 + i * 10, -46), o + Vector2(-28 + i * 10, -40), gold, 2.0)
	draw_line(o + Vector2(-30, -48), o + Vector2(22, -48), gold, 2.0)
	draw_colored_polygon(PackedVector2Array([o + Vector2(-20, -80), o + Vector2(12, -80), o + Vector2(16, -70), o + Vector2(-22, -70)]), saddle)
	draw_line(o + Vector2(-22, -71), o + Vector2(16, -71), gold, 1.5)
	# breast collar
	draw_line(o + Vector2(28, -74), o + Vector2(44, -56), leather, 3.0)
	draw_circle(o + Vector2(38, -64), 2.5, gold)

	# near legs
	var fl2 := _leg_angles(0.0, false)
	var hl2 := _leg_angles(0.5, true)
	_leg(o + Vector2(34, -50), fl2.x, fl2.y, true, coat)
	_leg(o + Vector2(-30, -52), hl2.x, hl2.y, true, coat)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _phase_rate() -> float:
	match anim:
		"gallop": return 14.0
		"trot": return 10.0
		"walk": return 6.0
	return 2.0
