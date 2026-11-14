class_name GogundaLayout
extends RefCounted
## Data for Mission 1. Ground surface is y = 0; negative y is up.
## Tune geometry here without touching mission logic.
## Jump reference (see Player/Horse exports): on-foot jump ~129px high,
## ~190px long at run speed; Chetak ~137px high, ~215px trot / ~390px gallop.

const LIMITS := Rect2i(-430, -1400, 11730, 1640)   # camera: x, y, w, h

# [x, y_top, width, height, style, merlons]
const BLOCKS := [
	[-560, -700, 140, 1300, "fort", false],      # west wall
	[-420, 0, 1920, 600, "paving", false],        # 1 Royal courtyard
	[650, -45, 200, 45, "fort", false],          #   dais
	[1500, 0, 2350, 600, "ground", false],        # 2 Training ground
	[3400, -60, 200, 660, "fort", false],         # 3 Fort walls: steps
	[3600, -130, 250, 730, "fort", false],
	[3800, -340, 50, 12, "plank", false],         #   ladder lip (one-way)
	[3850, -340, 300, 940, "fort", true],         #   rampart C
	[4420, -340, 280, 940, "fort", true],         #   rampart D
	[4780, -300, 60, 14, "plank", false],         #   narrow beams
	[4900, -260, 60, 14, "plank", false],
	[5000, -200, 250, 800, "fort", false],
	[5250, -100, 100, 700, "fort", false],
	[5350, 0, 2650, 600, "ground", false],        # 4 Stable + 5 ride course
	[8180, 0, 1420, 600, "ground", false],
	[9850, 0, 1450, 600, "ground", false],
	[11300, -700, 140, 1300, "fort", false],      # east wall
]

const LADDERS := [[3826, -235, 210]]           # [x, centre_y, height]
const CRUMBLING := [[4245, -340, 100]]         # [x, y, width]
const FALLING_STONES := [[4420, -340, [80, 200]]]

# [x, y, mounted]
const CHECKPOINTS := [
	[60, 0, false], [1560, 0, false], [3260, 0, false], [4470, -340, false],
	[5420, 0, false], [6380, 0, true], [8420, 0, true], [10300, 0, false],
]

const LEAVES := [[750, -110], [4000, -400], [4295, -470], [5800, -60], [9725, -110]]
const SUPPLIES := [[2400, -40], [4620, -380]]
const DUMMIES := [1850, 2050]
const HORSE_HOME := Vector2(5950, 0)
const HORSE_POST := Vector2(10220, 0)

# [x, size_x, size_y, style]
const HURDLES := [[6900, 20, 52, "fence"], [7500, 20, 52, "fence"], [8800, 70, 40, "log"], [9300, 20, 56, "fence"]]

# [id, x, y, width, once]
const TRIGGERS := [
	["move", 120, 0, 60], ["run", 420, 0, 60], ["jump", 560, 0, 60],
	["attack", 1700, 0, 60], ["spar", 2380, 0, 60], ["ladder", 3640, -130, 60],
	["crumble", 4120, -340, 60], ["stones", 4440, -340, 60], ["stable", 5520, 0, 60],
	["mount", 5800, 0, 60], ["gap", 7780, 0, 60], ["finish", 10200, 0, 200],
	["standard", 10980, 0, 120, false],
]

const DECOR := [
	{"type": "arcade", "pos": Vector2(-300, 0), "count": 5},
	{"type": "arcade", "pos": Vector2(920, 0), "count": 4},
	{"type": "torch", "pos": Vector2(300, 0)}, {"type": "torch", "pos": Vector2(880, -45)},
	{"type": "torch", "pos": Vector2(1420, 0)}, {"type": "torch", "pos": Vector2(3330, 0)},
	{"type": "torch", "pos": Vector2(4700 - 20, -340)}, {"type": "torch", "pos": Vector2(5380, 0)},
	{"type": "banner", "pos": Vector2(1480, 0)}, {"type": "banner", "pos": Vector2(3200, 0)},
	{"type": "banner", "pos": Vector2(6290, 0)}, {"type": "banner", "pos": Vector2(4100, -340)},
	{"type": "rack", "pos": Vector2(1620, 0)}, {"type": "rack", "pos": Vector2(2230, 0)},
	{"type": "stable", "pos": Vector2(5680, 0), "width": 440},
	{"type": "sign", "pos": Vector2(1590, 0), "text": "Training Ground"},
	{"type": "sign", "pos": Vector2(3290, 0), "text": "Fort Walls"},
	{"type": "sign", "pos": Vector2(5470, 0), "text": "Stables"},
	{"type": "sign", "pos": Vector2(6450, 0), "text": "Approach Course"},
	{"type": "sign", "pos": Vector2(10140, 0), "text": "Dismount Post"},
	{"type": "prop", "name": "crate", "pos": Vector2(1560, 0), "size": 0.5},
	{"type": "prop", "name": "barrel", "pos": Vector2(2300, 0), "size": 0.5},
	{"type": "prop", "name": "pot", "pos": Vector2(500, 0), "size": 0.4},
	{"type": "prop", "name": "pot", "pos": Vector2(540, 0), "size": 0.35},
	{"type": "prop", "name": "bush", "pos": Vector2(1450, 0), "size": 0.6},
	{"type": "prop", "name": "crate", "pos": Vector2(5640, 0), "size": 0.5},
	{"type": "prop", "name": "barrel", "pos": Vector2(6150, 0), "size": 0.5},
	{"type": "prop", "name": "bush", "pos": Vector2(7200, 0), "size": 0.7},
	{"type": "prop", "name": "tree", "pos": Vector2(8600, 0), "size": 1.4},
	{"type": "prop", "name": "bush", "pos": Vector2(9500, 0), "size": 0.6},
	{"type": "standard", "pos": Vector2(10980, 0), "raised": false, "id": "standard"},
]
