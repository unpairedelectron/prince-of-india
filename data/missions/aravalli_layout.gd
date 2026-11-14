class_name AravalliLayout
extends RefCounted
## Mission 3 - Chetak: The Final Ride. Entirely on horseback. Ground y = 0.
## Obstacles: fallen trees, rocky gaps, uneven slopes, a collapsing rope bridge,
## low branches (never combined with a jump), a stream, a narrow passage with falling stones, a steep descent
## onto collapsing ground, and the final stream leap. Saffron flags = safe landings.

const LIMITS := Rect2i(-430, -1400, 11230, 1640)

const BLOCKS := [
	[-560, -700, 140, 1300, "rock"],
	[-420, 0, 1620, 600, "ground"],      # to 1200   (gap 1200-1360)
	[1360, 0, 440, 600, "ground"],       # to 1800   (hills 1800-2600)
	[2600, 0, 100, 600, "ground"],       # to 2700   (rope bridge 2700-3080)
	[3080, 0, 1120, 600, "ground"],      # to 4200   (stream 4200-4520)
	[4520, 0, 1500, 600, "ground"],      # to 6020   (descent 6020-7550)
	[5000, -900, 700, 730, "rock"],      # narrow passage ceiling (bottom at -170)
	[7550, 0, 550, 600, "ground"],       # to 8100   (gap 8100-8320)
	[8320, 0, 680, 600, "ground"],       # to 9000   (final stream 9000-9250)
	[9250, 0, 1950, 600, "ground"],
	[11200, -700, 140, 1300, "rock"],
]

const SLOPES := [
	[Vector2(1800, 0), Vector2(1950, -60), Vector2(2120, -100), Vector2(2300, -60), Vector2(2450, -20), Vector2(2600, 0)],
	[Vector2(4200, 0), Vector2(4260, 30), Vector2(4460, 30), Vector2(4520, 0)],
	[Vector2(6020, 0), Vector2(6200, 40), Vector2(6400, 120), Vector2(6550, 160), Vector2(6700, 160)],
	[Vector2(6980, 160), Vector2(7150, 160), Vector2(7400, 40), Vector2(7550, 0)],
]

# [x, y, width, style, delay]
const CRUMBLING := [
	[2700, 0, 70, "bridge", 0.35], [2770, 0, 70, "bridge", 0.35], [2840, 0, 70, "bridge", 0.35],
	[2990, 0, 90, "bridge", 0.35],
	[6700, 160, 95, "stone", 0.4], [6795, 160, 95, "stone", 0.4], [6890, 160, 90, "stone", 0.4],
]

const FALLING_STONES := [[5800, 0, [60, 190]]]
const WATER := [[4200, -10, 320, 50]]
# [trunk x, ground y, span]
const BRANCHES := [[3850, 0, 200], [8650, 0, 180]]
const HURDLES := [[600, 70, 40, "log"], [3500, 70, 40, "log"], [7720, 70, 40, "log"]]

const CHECKPOINTS := [
	[60, 0, true], [1450, 0, true], [4700, 0, true], [6050, 0, true], [7600, 0, true], [8350, 0, true],
]

const LEAVES := [[1280, -150], [2120, -230], [3500, -170], [6845, 40], [9150, -160]]
const HORSE_HOME := Vector2(60, 0)
const REST_SPOT := Vector2(10150, 0)

const TRIGGERS := [
	["ride", 200, 0, 60], ["gap", 1000, 0, 60], ["bridge", 2560, 0, 60], ["branch", 3300, 0, 60],
	["stream", 4080, 0, 60], ["passage", 4900, 0, 60], ["descent", 5980, 0, 60], ["final_leap", 8700, 0, 60],
	["final", 9450, 0, 80],
]

const DECOR := [
	{"type": "tree", "pos": Vector2(300, 0), "size": 1.1}, {"type": "flag", "pos": Vector2(1380, 0)},
	{"type": "tree", "pos": Vector2(2300, -60), "size": 0.8}, {"type": "flag", "pos": Vector2(3100, 0)},
	{"type": "tree", "pos": Vector2(3250, 0), "size": 1.3}, {"type": "flag", "pos": Vector2(4540, 0)},
	{"type": "boulder", "pos": Vector2(4800, 0), "size": 1.2}, {"type": "tree", "pos": Vector2(6150, 25), "size": 0.9},
	{"type": "flag", "pos": Vector2(7000, 160)}, {"type": "flag", "pos": Vector2(8340, 0)},
	{"type": "flag", "pos": Vector2(9280, 0)}, {"type": "tree", "pos": Vector2(9900, 0), "size": 1.4},
	{"type": "tree", "pos": Vector2(10500, 0), "size": 1.1},
	{"type": "prop", "name": "bush", "pos": Vector2(900, 0), "size": 0.6},
	{"type": "prop", "name": "rock", "pos": Vector2(4650, 0), "size": 0.6},
	{"type": "prop", "name": "bush", "pos": Vector2(7650, 0), "size": 0.6},
	{"type": "prop", "name": "tree", "pos": Vector2(9700, 0), "size": 1.6},
]
