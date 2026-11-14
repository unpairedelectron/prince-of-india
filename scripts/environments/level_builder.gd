class_name LevelBuilder
extends RefCounted
## Turns a short list of level "segments" (see data/campaigns.gd) into the same
## layout dictionary the hand-made missions use (BLOCKS, CHECKPOINTS, ...), plus
## the spawn lists MissionCampaign needs. Levels read left to right; ground top
## starts at y = 0 and may only climb (y <= 0) so the pit kill-zone stays valid.
##
## Fairness rules baked in (on-foot jump: ~129 px high, ~195 px long at a run):
##   pits <= 150 px, steps up <= 90 px, anything taller gets a ladder.
##   Horse gaps are 260 px (needs a gallop; cannot be crossed on foot).

const DEPTH := 600.0
const LANDING := 180.0   ## flat ground guaranteed after every pit, before any step or wall

var C := {}
var foes: Array = []       ## {type, pos}
var allies: Array = []     ## {type, pos}
var arenas: Array = []     ## {id, x0, x1, y, waves, boss}
var spikes: Array = []     ## {pos, phase}
var movers: Array = []     ## {pos, travel, phase, style}
var volleys: Array = []    ## {x0, x1, y, style}
var hints := {}            ## trigger id -> text
var objectives := {}       ## trigger id -> text
var horse_home := Vector2.INF
var ride_from := INF       ## x where the mounted section begins
var ride_hurdles: Array = []
var ride_gaps: Array = []
var end_x := 0.0
var ground_runs: Array = []   ## [x0, x1, y]
var pits: Array = []          ## [x0, x1, y] (drawn as water / chasm by the mission)

var _x := 0.0
var _gy := 0.0
var _gx0 := -420.0
var _style := "ground"
var _tier := 1
var _n := 0
var _riding := false
var _min_y := 0.0


func build(segments: Array, theme: Dictionary, tier: int, seed_value: int) -> LevelBuilder:
	_style = theme.get("terrain", "ground")
	_tier = tier
	for k in ["BLOCKS", "CHECKPOINTS", "LADDERS", "CRUMBLING", "FALLING_STONES", "HURDLES", "LEAVES", "SUPPLIES", "TRIGGERS", "DECOR", "WATER"]:
		C[k] = []
	C.BLOCKS.append([-560, -900, 140, 1500, _wall_style()])
	C.CHECKPOINTS.append([60, 0, false])
	_x = 420.0
	for s in segments:
		_segment(s)
	end_x = _x
	_trigger("end", _x + 40.0, 160.0)
	_x += 700.0
	_flush()
	C.BLOCKS.append([_x, _gy - 900.0, 140, 1500, _wall_style()])
	C["LIMITS"] = Rect2i(-430, int(_min_y) - 1400, int(_x) + 430, int(-_min_y) + 1640)
	_scatter_decor(theme.get("decor", []), seed_value)
	return self


func _wall_style() -> String:
	return "rock" if not _style in ["fort", "paving"] else "fort"


func _flush() -> void:
	if _x > _gx0:
		C.BLOCKS.append([_gx0, _gy, _x - _gx0, DEPTH - _gy, _style])
		ground_runs.append([_gx0, _x, _gy])
	_gx0 = _x


func _trigger(id: String, x: float, width := 60.0, once := true) -> void:
	C.TRIGGERS.append([id, x, _gy, width, once])


func _uid(prefix: String) -> String:
	_n += 1
	return "%s_%d" % [prefix, _n]


func _segment(s: Array) -> void:
	match s[0]:
		"run":
			_x += s[1]
		"gap":
			_flush()
			_x += minf(s[1], 150.0)
			pits.append([_gx0, _x, _gy])
			_gx0 = _x
			_x += LANDING
		"step":
			_flush()
			_gy += clampf(s[1], -90.0, 400.0)
			_gy = minf(_gy, 0.0)
			_min_y = minf(_min_y, _gy)
		"stairs":   # [_, count, dy, width]
			for i in s[1]:
				_segment(["step", s[2]])
				_x += s[3]
		"tower":    # [_, height] - ladder up a wall face
			var h: float = s[1]
			_x += 120.0
			_flush()
			C.LADDERS.append([_x - 30.0, _gy - h * 0.5, h])
			C.BLOCKS.append([_x - 64.0, _gy - h, 64.0, 16.0, "plank"])
			_gy -= h
			_min_y = minf(_min_y, _gy)
			_x += 160.0
		"foes":     # [_, [[type, offset], ...], width]
			for f in s[1]:
				foes.append({"type": f[0], "pos": Vector2(_x + f[1], _gy)})
			_x += s[2]
		"allies":   # [_, [[type, offset], ...]]
			for f in s[1]:
				allies.append({"type": f[0], "pos": Vector2(_x + f[1], _gy)})
		"arena", "boss":   # [_, waves | boss config, width]
			var id := _uid("arena")
			var w: float = s[2]
			_x += 200.0
			arenas.append({"id": id, "x0": _x, "x1": _x + w, "y": _gy,
				"waves": s[1] if s[0] == "arena" else [], "boss": s[1] if s[0] == "boss" else {}})
			_trigger(id, _x + 170.0, 60.0, false)
			_x += w + 160.0
		"spikes":   # [_, count]
			_x += 130.0
			for i in s[1]:
				spikes.append({"pos": Vector2(_x, _gy), "phase": i * 0.55})
				_x += 170.0
			_x += 40.0
		"crumble":  # [_, count] - a failing bridge: slabs drop away behind you
			_flush()
			for i in s[1] + 1:
				C.CRUMBLING.append([_x + i * 120.0, _gy, 120.0, "stone" if _style in ["fort", "paving"] else "bridge", maxf(0.34, 0.58 - 0.04 * _tier)])
			_x += (s[1] + 1) * 120.0
			pits.append([_gx0, _x, _gy])
			_gx0 = _x
			_x += LANDING
		"pillars":  # [_, count, gap]
			_flush()
			var g: float = minf(s[2], 140.0)
			for i in s[1]:
				_x += g
				C.BLOCKS.append([_x, _gy, 200.0, DEPTH - _gy, _wall_style()])
				_x += 200.0
			_x += g
			pits.append([_gx0, _x, _gy])
			_gx0 = _x
			_x += LANDING
		"movers":   # [_, count, style] - rafts / boats / lifts over a pit
			_flush()
			for i in s[1]:
				movers.append({"pos": Vector2(_x + 60.0 + i * 330.0, _gy), "travel": Vector2(150, 0),
					"phase": 0.0 if i % 2 == 0 else 0.5, "style": s[2] if s.size() > 2 else "raft"})
			_x += s[1] * 330.0 + 60.0
			pits.append([_gx0, _x, _gy])
			_gx0 = _x
			_x += LANDING
		"stones":   # [_, width]
			var pts: Array = []
			var px := 140.0
			while px < s[1] - 80.0:
				pts.append(px)
				px += 190.0
			C.FALLING_STONES.append([_x, _gy, pts])
			_x += s[1]
		"volley":   # [_, width, style]
			volleys.append({"x0": _x, "x1": _x + s[1], "y": _gy, "style": s[2] if s.size() > 2 else "arrows"})
			_x += s[1]
		"cp":
			C.CHECKPOINTS.append([_x, _gy, _riding])
			_x += 120.0
		"supply":
			C.SUPPLIES.append([_x, _gy - 30.0])
		"leaf":
			C.LEAVES.append([_x, _gy + (s[1] if s.size() > 1 else -150.0)])
		"hint":
			var id2 := _uid("hint")
			hints[id2] = s[1]
			_trigger(id2, _x)
		"obj":
			var id3 := _uid("obj")
			objectives[id3] = s[1]
			_trigger(id3, _x)
		"ride":     # [_, obstacle count] - mounted finale: hurdles and gallop gaps
			C.CHECKPOINTS.append([_x, _gy, false])
			_x += 260.0
			horse_home = Vector2(_x, _gy)
			_trigger("horse", _x - 200.0)
			_x += 520.0
			ride_from = _x
			_riding = true
			for i in s[1]:
				_x += 680.0
				if i % 3 == 2:
					_flush()
					ride_gaps.append(_x)
					_x += 260.0
					pits.append([_gx0, _x, _gy])
					_gx0 = _x
				else:
					var st: String = ["rocks", "cart", "log"][i % 3]
					C.HURDLES.append([_x, 60, 46 + (_tier % 3) * 4, st, _gy])
					ride_hurdles.append(_x)
				if i % 4 == 3:
					_x += 420.0
					C.CHECKPOINTS.append([_x, _gy, true])
			_x += 900.0
		_:
			push_warning("LevelBuilder: unknown segment %s" % str(s[0]))


func _scatter_decor(kinds: Array, seed_value: int) -> void:
	if kinds.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for r in ground_runs:
		var x: float = r[0] + rng.randf_range(120, 380)
		while x < r[1] - 100.0:
			var k: Dictionary = kinds[rng.randi() % kinds.size()].duplicate()
			k["pos"] = Vector2(x, r[2])
			if k.has("size"):
				k["size"] = k.size * rng.randf_range(0.8, 1.2)
			C.DECOR.append(k)
			x += rng.randf_range(420, 900)
