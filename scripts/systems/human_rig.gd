class_name HumanRig
extends Node2D
## PLACEHOLDER ART: procedural 2D "puppet" for human characters.
## Draws a Mewar-inspired figure (turban, jama, kamarband, talwar, dhal) with
## vector shapes and animates it through named poses. Origin = between the feet.
## Facing is handled by the parent flipping scale.x.
## Replace with hand-animated sprite sheets later (see ASSET_MANIFEST.md); the
## controller only calls play()/set_progress(), so the swap is local to this node.

var palette := {
	"turban": Game.C_SAFFRON, "turban_band": Game.C_GOLD,
	"jama": Game.C_INDIGO, "jama_trim": Game.C_GOLD,
	"sash": Game.C_SAFFRON, "pants": Color("e9dcc0"), "shoes": Game.C_BROWN,
	"skin": Game.C_SKIN, "hair": Color("1c1410"), "armour": Game.C_SILVER,
	"blade": Color("d9dde2"), "hilt": Game.C_GOLD,
	"shield": Color("3b2416"), "shield_boss": Game.C_GOLD,
}
@export var has_shield := true
@export var has_armour := true
@export var has_moustache := true
@export var blade_length := 44.0
@export var wooden_sword := false
var weapon := "sword"   ## sword | spear | bow | musket
var headgear := "turban"   ## turban | jiretop | pagdi_f | ahom | helmet | shako
var beard := false
var female := false
var dual := false          ## second sword in the near hand instead of a shield
var plume := false

var anim := "idle"
var anim_time := 0.0
var progress := 0.0          ## 0..1 progress for one-shot moves (attacks)
var speed_ratio := 0.0       ## 0..1 locomotion speed for cycle rate
var swoosh := 0.0            ## >0 draws a sword trail
var show_sword := true

const THIGH := 21.0
const SHIN := 21.0
const UPPER := 15.0
const FORE := 14.0
const TORSO := 30.0

var _p := {}
var _keys := ["hip_y", "lean", "lf", "kf", "lb", "kb", "af", "ef", "ab", "eb", "sw", "head", "bob", "shield_up", "skirt"]


func _ready() -> void:
	for k in _keys:
		_p[k] = 0.0
	_p.merge(_pose_idle(0.0), true)


## Hero / faction look: palette colours plus headgear and build flags.
func apply_look(look: Dictionary) -> void:
	palette = palette.duplicate()
	for k in look:
		if palette.has(k):
			palette[k] = look[k]
	headgear = look.get("headgear", "turban")
	beard = look.get("beard", false)
	female = look.get("female", false)
	dual = look.get("dual", false)
	has_shield = not dual
	has_armour = look.get("armour", true)
	blade_length = look.get("blade_length", blade_length)


func play(new_anim: String, reset := false) -> void:
	if new_anim != anim or reset:
		anim = new_anim
		anim_time = 0.0
		progress = 0.0


func set_progress(v: float) -> void:
	progress = clampf(v, 0.0, 1.0)


func _process(delta: float) -> void:
	anim_time += delta
	var target := _target_pose()
	var rate := 30.0 if anim.begins_with("attack") or anim.begins_with("heavy") or anim == "parry" else 16.0
	var w := 1.0 - exp(-rate * delta)
	for k in target:
		_p[k] = lerpf(_p[k], target[k], w)
	swoosh = maxf(0.0, swoosh - delta * 4.0)
	queue_redraw()


# ------------------------------------------------------------------ poses

func _pose_idle(t: float) -> Dictionary:
	var br := sin(t * 2.2)
	return {"hip_y": 0.0, "lean": 0.02, "lf": 0.12, "kf": -0.12, "lb": -0.14, "kb": -0.06,
		"af": 0.18 + br * 0.02, "ef": 0.6, "ab": 0.35, "eb": 0.9, "sw": 0.55,
		"head": 0.0, "bob": br * 1.1, "shield_up": 0.0, "skirt": 0.0}


func _cycle(t: float, amp: float, knee: float, lean: float, bob: float, rate: float) -> Dictionary:
	var p := t * rate
	var d := _pose_idle(0.0)
	d.lf = sin(p) * amp
	d.lb = sin(p + PI) * amp
	d.kf = -0.1 - maxf(0.0, -cos(p)) * knee
	d.kb = -0.1 - maxf(0.0, cos(p)) * knee
	d.lean = lean
	d.bob = -absf(sin(p)) * bob
	d.af = 0.25 - sin(p) * amp * 0.5
	d.ab = 0.4 + sin(p) * amp * 0.3
	d.skirt = sin(p) * 2.0
	return d


func _target_pose() -> Dictionary:
	var t := anim_time
	var u := progress
	match anim:
		"idle":
			return _pose_idle(t)
		"walk":
			return _cycle(t, 0.42, 0.55, 0.06, 2.0, 9.0)
		"run":
			return _cycle(t, 0.72, 1.0, 0.18, 3.0, 12.5)
		"sprint":
			return _cycle(t, 0.92, 1.25, 0.3, 3.5, 15.0)
		"jump":
			return {"hip_y": 0.0, "lean": 0.05, "lf": 0.7, "kf": -1.0, "lb": -0.2, "kb": -0.5,
				"af": 1.3, "ef": 0.3, "ab": 0.9, "eb": 0.6, "sw": 0.5, "head": -0.1, "bob": 0.0, "shield_up": 0.0, "skirt": -3.0}
		"fall":
			return {"hip_y": 0.0, "lean": 0.0, "lf": 0.35, "kf": -0.5, "lb": -0.1, "kb": -0.7,
				"af": 1.7, "ef": 0.2, "ab": 1.5, "eb": 0.3, "sw": 0.4, "head": 0.1, "bob": 0.0, "shield_up": 0.0, "skirt": 4.0}
		"land":
			return {"hip_y": 9.0, "lean": 0.18, "lf": 0.6, "kf": -1.1, "lb": -0.35, "kb": -0.7,
				"af": 0.5, "ef": 0.6, "ab": 0.6, "eb": 0.8, "sw": 0.5, "head": 0.1, "bob": 0.0, "shield_up": 0.0, "skirt": 2.0}
		"crouch", "crouch_walk":
			var c := sin(t * 8.0) * (0.15 if anim == "crouch_walk" else 0.0)
			return {"hip_y": 16.0, "lean": 0.25, "lf": 1.05 + c, "kf": -1.7, "lb": 0.45 - c, "kb": -1.6,
				"af": 0.5, "ef": 0.8, "ab": 0.95, "eb": 0.5, "sw": 0.5, "head": -0.1, "bob": 0.0, "shield_up": 0.4, "skirt": 0.0}
		"climb":
			var s := sin(t * 7.0) * (1.0 if speed_ratio > 0.05 else 0.0)
			return {"hip_y": 0.0, "lean": -0.05, "lf": 0.7 + s * 0.4, "kf": -1.3, "lb": 0.7 - s * 0.4, "kb": -1.3,
				"af": 2.75 + s * 0.3, "ef": 0.2, "ab": 2.75 - s * 0.3, "eb": 0.2, "sw": 3.0, "head": -0.2, "bob": 0.0, "shield_up": 0.0, "skirt": 0.0}
		"attack1":
			return _blend3(_pose_idle(0), {"af": 2.7, "ef": 0.4, "sw": 0.3, "lean": -0.08, "lf": 0.3, "lb": -0.3},
				{"af": 0.95, "ef": 0.05, "sw": 0.55, "lean": 0.22, "lf": 0.55, "lb": -0.45, "hip_y": 4.0}, u)
		"attack2":
			return _blend3(_pose_idle(0), {"af": 0.3, "ef": 0.3, "sw": -0.5, "lean": 0.15, "lf": 0.45, "lb": -0.3, "hip_y": 4.0},
				{"af": 2.5, "ef": 0.1, "sw": 0.25, "lean": -0.05, "lf": 0.4, "lb": -0.4}, u)
		"attack3":
			return _blend3(_pose_idle(0), {"af": 1.0, "ef": -1.3, "sw": 1.3, "lean": -0.12, "lf": 0.2, "lb": -0.2},
				{"af": 1.55, "ef": 0.0, "sw": 0.0, "lean": 0.3, "lf": 0.75, "kf": -0.4, "lb": -0.6, "hip_y": 6.0}, u)
		"heavy_windup", "telegraph":
			var q := sin(t * 30.0) * 0.03
			return _merge(_pose_idle(0), {"af": 3.0 + q, "ef": 0.35, "sw": 0.35, "lean": -0.16, "lf": 0.35, "lb": -0.35, "hip_y": 3.0})
		"heavy":
			return _blend3(_pose_idle(0), {"af": 3.0, "ef": 0.35, "sw": 0.35, "lean": -0.16},
				{"af": 0.55, "ef": 0.15, "sw": 0.85, "lean": 0.38, "lf": 0.8, "kf": -0.6, "lb": -0.55, "hip_y": 8.0}, minf(1.0, u * 1.4))
		"block":
			return _merge(_pose_idle(t), {"ab": 1.45, "eb": 0.15, "shield_up": 1.0, "af": 0.35, "ef": 0.9, "sw": 1.5, "hip_y": 5.0, "lean": 0.08, "lf": 0.4, "lb": -0.35, "bob": 0.0})
		"parry":
			return _merge(_pose_idle(0), {"ab": 1.7, "eb": 0.0, "shield_up": 1.0, "af": 0.35, "ef": 0.9, "sw": 1.5, "hip_y": 4.0, "lean": 0.2, "lf": 0.55, "lb": -0.4})
		"dodge":
			return {"hip_y": 18.0, "lean": 0.65, "lf": 1.0, "kf": -1.2, "lb": -0.9, "kb": -0.5,
				"af": 0.6, "ef": 0.9, "ab": 1.2, "eb": 0.6, "sw": 0.6, "head": 0.2, "bob": 0.0, "shield_up": 0.0, "skirt": -4.0}
		"hurt":
			return _merge(_pose_idle(0), {"lean": -0.35, "af": 0.9, "ab": 0.9, "head": -0.35, "lf": 0.3, "lb": -0.4, "hip_y": 2.0})
		"defeated", "yield":
			return {"hip_y": 19.0, "lean": 0.45, "lf": 1.35, "kf": -2.0, "lb": -0.15, "kb": -1.75,
				"af": 0.15, "ef": 0.1, "ab": 0.4, "eb": 0.4, "sw": -0.3, "head": 0.45, "bob": 0.0, "shield_up": 0.0, "skirt": 0.0}
		"victory":
			return _merge(_pose_idle(t), {"af": 2.95, "ef": 0.0, "sw": 0.05, "ab": 0.5, "eb": 0.8, "lean": -0.05, "head": -0.15})
		"aim":
			# bow drawn: bow arm forward, string hand pulled back by progress
			return _merge(_pose_idle(0), {"ab": 1.57, "eb": 0.0, "af": 1.45, "ef": -1.2 - progress * 0.9, "sw": 0.0, "lean": -0.05, "lf": 0.35, "lb": -0.3})
		"interact":
			return _merge(_pose_idle(t), {"af": 1.35, "ef": -0.2, "sw": 1.6, "lean": 0.08})
		"mounted":
			var g := sin(t * (6.0 + speed_ratio * 10.0)) * speed_ratio
			return {"hip_y": 0.0, "lean": 0.08 + speed_ratio * 0.25, "lf": 0.95, "kf": -1.35, "lb": 0.8, "kb": -1.3,
				"af": 1.0 + g * 0.1, "ef": -0.3, "ab": 1.1 + g * 0.1, "eb": -0.2, "sw": 2.2, "head": -0.05,
				"bob": g * 2.0, "shield_up": 0.0, "skirt": -2.0}
	return _pose_idle(t)


func _merge(base: Dictionary, over: Dictionary) -> Dictionary:
	var d := base.duplicate()
	d.merge(over, true)
	return d


## Neutral -> windup (first 30%) -> strike (fast) -> hold.
func _blend3(base: Dictionary, windup: Dictionary, strike: Dictionary, u: float) -> Dictionary:
	var a := _merge(base, windup)
	var b := _merge(base, strike)
	var d := {}
	if u < 0.3:
		var w := smoothstep(0.0, 1.0, u / 0.3)
		for k in a:
			d[k] = lerpf(base[k], a[k], w)
	else:
		var w2 := smoothstep(0.0, 1.0, clampf((u - 0.3) / 0.22, 0.0, 1.0))
		for k in a:
			d[k] = lerpf(a[k], b[k], w2)
	return d


# ------------------------------------------------------------------ drawing

static func dir(a: float) -> Vector2:
	return Vector2(sin(a), cos(a))


func _seg(a: Vector2, b: Vector2, w: float, c: Color) -> void:
	draw_line(a, b, c, w)
	draw_circle(a, w * 0.5, c)
	draw_circle(b, w * 0.5, c)


func _draw() -> void:
	var p := _p
	var hip := Vector2(0, -(THIGH + SHIN) + p.hip_y + p.bob)
	var up := Vector2(sin(p.lean), -cos(p.lean))
	var shoulder := hip + up * TORSO
	var neck := shoulder + up * 3.0
	var head_c := neck + up * 9.0 + Vector2(1.5, 0)
	var dark := Color(0, 0, 0, 0.18)

	# shadow
	draw_set_transform(Vector2(0, 1), 0, Vector2(1, 0.25))
	draw_circle(Vector2.ZERO, 16.0, Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

	# far leg
	_leg(hip + Vector2(-2, 0), p.lb, p.kb, palette.pants.darkened(0.18), palette.shoes.darkened(0.2))
	# far (sword) arm + sword
	var sh_f := shoulder + Vector2(-2, 2)
	var elbow_f := sh_f + dir(p.af) * UPPER
	var hand_f := elbow_f + dir(p.af + p.ef) * FORE
	_seg(sh_f, elbow_f, 5.5, palette.jama.darkened(0.25))
	_seg(elbow_f, hand_f, 4.5, palette.skin.darkened(0.15))
	if show_sword and weapon == "sword":
		_sword(hand_f, p.af + p.ef + p.sw)
	elif show_sword and weapon == "spear":
		_spear(hand_f, p.af + p.ef + p.sw)
	elif weapon == "musket":
		_musket(hand_f)

	# torso (jama)
	var side := Vector2(cos(p.lean), sin(p.lean))
	var waist := hip + up * 4.0
	var torso_pts := PackedVector2Array([
		shoulder - side * 8.5, shoulder + side * 9.0, waist + side * 7.5, waist - side * 7.0])
	draw_colored_polygon(torso_pts, palette.jama)
	# skirt (flared lower jama)
	var sk: float = p.skirt
	var skirt_pts := PackedVector2Array([
		waist - side * 7.0, waist + side * 7.5,
		hip + Vector2(13 + sk, 15), hip + Vector2(-12 + sk, 15)])
	draw_colored_polygon(skirt_pts, palette.jama.darkened(0.08))
	draw_line(hip + Vector2(-12 + sk, 15), hip + Vector2(13 + sk, 15), palette.jama_trim, 2.0)
	if has_armour:
		var chest := shoulder.lerp(waist, 0.4) + side * 2.0
		draw_colored_polygon(PackedVector2Array([chest + Vector2(-5, -6), chest + Vector2(6, -6), chest + Vector2(6, 6), chest + Vector2(-5, 6)]), palette.armour)
		draw_circle(chest + Vector2(0.5, 0), 2.2, palette.jama_trim)
	# kamarband (waist sash)
	draw_line(waist - side * 7.5, waist + side * 8.0, palette.sash, 4.0)
	draw_line(waist + side * 2.0, waist + side * 2.0 + Vector2(-1, 9), palette.sash.darkened(0.1), 3.0)

	# near leg
	_leg(hip + Vector2(2, 0), p.lf, p.kf, palette.pants, palette.shoes)

	# head
	draw_line(shoulder, neck, palette.skin.darkened(0.1), 5.0)
	draw_circle(head_c, 8.0, palette.skin)
	var hu := Vector2(sin(p.lean + p.head), -cos(p.lean + p.head))
	var hs := Vector2(cos(p.lean + p.head), sin(p.lean + p.head))
	var tb := head_c + hu * 3.0
	_headgear(tb, hu, hs)
	# face details
	var eye := head_c + hs * 4.0 - hu * 0.5
	draw_circle(eye, 1.1, Color(0.08, 0.05, 0.04))
	draw_line(head_c - hs * 4.0 - hu * 1.0, head_c - hs * 4.0 - hu * 6.0, palette.hair, 2.5)  # sideburn
	if has_moustache and not female:
		var m := head_c + hs * 5.5 - hu * 4.0
		draw_line(m - hs * 4.5 + hu * 1.5, m + hs * 2.5, palette.hair, 2.5)
		draw_line(m + hs * 2.5, m + hs * 4.0 + hu * 2.0, palette.hair, 2.0)
	if beard:
		draw_colored_polygon(PackedVector2Array([head_c - hs * 3.0 - hu * 4.0, head_c + hs * 7.0 - hu * 4.5, head_c + hs * 5.0 - hu * 11.0, head_c - hs * 1.0 - hu * 8.5]), palette.hair)
	if female:
		# pearl necklace, earring and a long plait down the back
		draw_arc(neck + up * 1.0, 6.0, 0.2, PI - 0.2, 8, Color("f3ecd8"), 2.0)
		draw_circle(head_c - hs * 2.5 - hu * 3.5, 1.8, Game.C_GOLD)
		draw_line(head_c - hs * 7.0 + hu * 2.0, shoulder - side * 10.0 - up * 6.0, palette.hair, 4.0)
		draw_line(shoulder - side * 10.0 - up * 6.0, waist - side * 11.0, palette.hair, 3.0)

	# near (shield) arm
	var sh_b := shoulder + Vector2(2, 2)
	var elbow_b := sh_b + dir(p.ab) * UPPER
	var hand_b := elbow_b + dir(p.ab + p.eb) * FORE
	_seg(sh_b, elbow_b, 6.0, palette.jama)
	_seg(elbow_b, hand_b, 5.0, palette.skin)
	if dual:
		_sword(hand_b, p.ab + p.eb + (0.5 if p.shield_up < 0.5 else -1.1))
	elif has_shield:
		var sc := hand_b + Vector2(3.0 + p.shield_up * 2.0, 0)
		var r: float = 12.0 + p.shield_up * 1.5
		draw_circle(sc, r, palette.shield)
		draw_arc(sc, r, 0, TAU, 24, palette.shield_boss.darkened(0.2), 1.5)
		for i in 4:
			var a := PI * 0.25 + i * PI * 0.5
			draw_circle(sc + Vector2(cos(a), sin(a)) * r * 0.45, 1.8, palette.shield_boss)
		draw_circle(sc, 2.6, palette.shield_boss)

	if weapon == "bow":
		_bow(hand_b, hand_f)

	if swoosh > 0.0:
		var c := Color(1, 0.95, 0.8, swoosh * 0.55)
		draw_arc(shoulder, blade_length + UPPER + 4.0, -PI * 0.55, PI * 0.35, 18, c, 6.0 * swoosh)


func _leg(h: Vector2, a: float, k: float, col: Color, shoe: Color) -> void:
	var knee := h + dir(a) * THIGH
	var foot := knee + dir(a + k) * SHIN
	_seg(h, knee, 7.0, col)
	_seg(knee, foot, 5.5, col)
	# mojari with curled toe
	var fwd := Vector2(1, 0)
	draw_colored_polygon(PackedVector2Array([foot + Vector2(-3, -2), foot + fwd * 7 + Vector2(0, -1), foot + fwd * 9 + Vector2(0, -4), foot + fwd * 8 + Vector2(0, 2), foot + Vector2(-3, 2)]), shoe)


func _sword(hand: Vector2, a: float) -> void:
	var d := dir(a)
	var n := Vector2(-d.y, d.x)
	# hilt + guard
	draw_line(hand - d * 5.0, hand + d * 2.0, palette.hilt, 3.0)
	draw_line(hand + d * 2.0 - n * 4.0, hand + d * 2.0 + n * 4.0, palette.hilt, 2.0)
	# curved talwar blade (or wooden practice stick)
	var pts := PackedVector2Array()
	var segs := 8
	for i in segs + 1:
		var f := float(i) / segs
		var curve := (f * f) * (0.0 if wooden_sword else 7.0)
		pts.append(hand + d * (3.0 + f * blade_length) - n * curve)
	var col: Color = Color("8a5a32") if wooden_sword else palette.blade
	draw_polyline(pts, col, 3.0 if wooden_sword else 2.6)
	if not wooden_sword:
		draw_polyline(pts, Color(1, 1, 1, 0.35), 1.0)


## Headgear variants, drawn relative to the top of the head (tb), head up (hu)
## and head forward (hs) vectors.
func _headgear(tb: Vector2, hu: Vector2, hs: Vector2) -> void:
	var c: Color = palette.turban
	var band: Color = palette.turban_band
	match headgear:
		"jiretop":
			# Maratha jiretop: tall crest swept forward and up, with a jewelled band
			draw_colored_polygon(PackedVector2Array([tb - hs * 9.5, tb + hs * 8.5, tb + hs * 8.5 + hu * 5.0, tb + hs * 4.0 + hu * 9.0, tb + hs * 3.0 + hu * 18.0, tb - hs * 3.0 + hu * 12.0, tb - hs * 9.0 + hu * 7.0]), c)
			draw_line(tb - hs * 9.5 + hu * 1.0, tb + hs * 8.5 + hu * 1.0, band, 2.5)
			draw_line(tb + hs * 3.0 + hu * 17.0, tb - hs * 1.0 + hu * 8.0, c.darkened(0.18), 1.5)
			draw_circle(tb + hs * 6.0 + hu * 4.0, 2.0, Color("f3ecd8"))
		"pagdi_f":
			# the Rani's battle turban with a trailing end and a jewelled sarpech
			draw_colored_polygon(PackedVector2Array([tb - hs * 9.5, tb + hs * 8.5, tb + hs * 7.0 + hu * 7.0, tb + hs * 1.0 + hu * 10.0, tb - hs * 8.0 + hu * 8.0]), c)
			draw_line(tb - hs * 9.5 + hu * 1.0, tb + hs * 8.5 + hu * 1.0, band, 2.0)
			draw_line(tb - hs * 8.0 + hu * 5.0, tb - hs * 17.0 - hu * 2.0 + Vector2(0, sin(anim_time * 6.0) * 2.0), c.darkened(0.08), 4.0)
			draw_line(tb + hs * 5.0 + hu * 3.0, tb + hs * 6.0 + hu * 12.0, band, 2.0)
			draw_circle(tb + hs * 5.0 + hu * 4.0, 2.2, Color("e8443a"))
		"ahom":
			# Ahom commander: tied head-cloth with a knot and falling ends, hair gathered behind
			draw_circle(tb - hs * 7.0 + hu * 1.0, 5.0, palette.hair)
			draw_colored_polygon(PackedVector2Array([tb - hs * 9.0 - hu * 1.0, tb + hs * 8.5 - hu * 1.0, tb + hs * 7.5 + hu * 5.0, tb - hs * 1.0 + hu * 7.5, tb - hs * 8.5 + hu * 5.0]), c)
			draw_line(tb - hs * 9.0 + hu * 0.5, tb + hs * 8.5 + hu * 0.5, band, 2.5)
			draw_line(tb - hs * 9.0 + hu * 1.0, tb - hs * 14.0 - hu * 7.0, c, 3.0)
			draw_line(tb - hs * 9.0 + hu * 1.0, tb - hs * 11.0 - hu * 10.0, band, 2.0)
		"helmet":
			# kulah khud: steel bowl, spike and mail curtain
			var st := Color("aab0b8")
			draw_colored_polygon(PackedVector2Array([tb - hs * 9.0, tb + hs * 8.5, tb + hs * 6.5 + hu * 6.0, tb + hu * 9.0, tb - hs * 7.0 + hu * 6.0]), st)
			draw_line(tb + hu * 9.0, tb + hu * 16.0, st.darkened(0.2), 2.0)
			draw_line(tb - hs * 9.0, tb + hs * 8.5, band, 2.0)
			draw_colored_polygon(PackedVector2Array([tb - hs * 9.0, tb - hs * 3.0, tb - hs * 4.0 - hu * 11.0, tb - hs * 10.0 - hu * 10.0]), st.darkened(0.25))
			draw_line(tb + hs * 7.5, tb + hs * 7.5 - hu * 5.0, st.darkened(0.2), 2.0)
		"shako":
			# Company infantry cap with a peak and a badge
			draw_colored_polygon(PackedVector2Array([tb - hs * 8.0, tb + hs * 8.0, tb + hs * 7.0 + hu * 12.0, tb - hs * 7.0 + hu * 12.0]), c)
			draw_line(tb - hs * 8.0, tb + hs * 12.0, c.darkened(0.2), 2.5)
			draw_line(tb - hs * 7.5 + hu * 11.0, tb + hs * 7.5 + hu * 11.0, band, 2.0)
			draw_circle(tb + hs * 4.0 + hu * 6.0, 2.0, band)
		_:
			# turban (pagri): layered dome leaning back, band and tail
			draw_colored_polygon(PackedVector2Array([
				tb - hs * 9.5, tb + hs * 8.5, tb + hs * 7.0 + hu * 7.0, tb + hs * 1.0 + hu * 10.5, tb - hs * 8.0 + hu * 8.0]), c)
			draw_line(tb - hs * 9.5 + hu * 1.0, tb + hs * 8.5 + hu * 1.0, band, 2.0)
			draw_line(tb - hs * 6.0 + hu * 5.0, tb + hs * 6.0 + hu * 7.5, c.darkened(0.15), 1.5)
			draw_line(tb - hs * 9.0, tb - hs * 13.0 - hu * 6.0, c.darkened(0.1), 3.0)
	if plume:
		draw_line(tb + hu * 9.0, tb - hs * 6.0 + hu * 22.0, Color("b3261e"), 4.0)
		draw_line(tb + hu * 9.0, tb - hs * 2.0 + hu * 24.0, Color("e0b84a"), 2.0)


func _musket(hand: Vector2) -> void:
	var a := 1.57 if anim == "aim" else 0.5
	var d := dir(a)
	draw_line(hand - d * 16.0, hand + d * 8.0, Color("5a3820"), 5.0)
	draw_line(hand - d * 10.0, hand + d * 44.0, Color("4a4f57"), 2.5)
	draw_line(hand + d * 44.0, hand + d * 56.0, Color("c9ced4"), 1.5)


func _spear(hand: Vector2, a: float) -> void:
	var d := dir(a)
	var n := Vector2(-d.y, d.x)
	draw_line(hand - d * 24.0, hand + d * 64.0, Color("7a5030"), 3.0)
	var tip := hand + d * 64.0
	draw_colored_polygon(PackedVector2Array([tip + n * 3.5, tip + d * 14.0, tip - n * 3.5]), palette.blade)
	draw_circle(tip, 2.0, palette.hilt)


func _bow(grip: Vector2, string_hand: Vector2) -> void:
	var col := Color("6b4428")
	var top := grip + Vector2(-6, -24)
	var bot := grip + Vector2(-6, 24)
	var pts := PackedVector2Array()
	for i in 9:
		var f := i / 8.0
		pts.append(top.lerp(bot, f) + Vector2(sin(f * PI) * 10.0, 0))
	draw_polyline(pts, col, 3.0)
	var pull := string_hand if anim == "aim" else grip + Vector2(-8, 0)
	draw_line(top, pull, Color(0.9, 0.88, 0.8, 0.9), 1.0)
	draw_line(bot, pull, Color(0.9, 0.88, 0.8, 0.9), 1.0)
	if anim == "aim":
		draw_line(pull, grip + Vector2(14, 0), Color("6b4428"), 2.0)
