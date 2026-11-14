class_name HaldighatiLayout
extends RefCounted
## Mission 2 - The Yellow Pass. Ground y = 0. Sections:
## 1 mountain pass (0-2400) | 2 battlefield (2400-5200) | 3 chokepoint (5200-6700)
## 4 rear guard (6700-9500) | 5 escape on Chetak (9600-12900)
## Horse-obstacle spacing rule: >= ~600px between consecutive obstacles at gallop
## (a gallop leap covers ~390px; the rider needs room to land and re-time).

const LIMITS := Rect2i(-430, -1400, 13930, 1640)

const BLOCKS := [
	[-560, -700, 140, 1300, "rock"],
	[-420, 0, 7020, 600, "ochre"],                 # pass + battlefield + chokepoint (to 6600)
	[600, -50, 140, 50, "rock"], [1350, -80, 160, 80, "rock"], [1510, -40, 120, 40, "rock"],
	[3300, -70, 100, 70, "rock"], [3400, -150, 260, 150, "rock"],    # archer ledge
	[4520, -150, 200, 150, "rock"], [4440, -70, 80, 70, "rock"],     # allied archer ledge
	[5300, -900, 1300, 620, "rock"],               # gorge overhang (chokepoint)
	[5680, -80, 40, 80, "rock"], [6080, -80, 40, 80, "rock"],        # cover rocks
	[6600, 0, 1000, 600, "ochre"],                 # rear guard (ditches between)
	[7720, 0, 900, 600, "ochre"],
	[8760, 0, 1940, 600, "ochre"],                 # to 10700 (escape gap 10700-10920)
	[10920, 0, 2440, 600, "ochre"],
	[13360, -700, 140, 1300, "rock"],
]

# [x, y, mounted]
const CHECKPOINTS := [
	[60, 0, false], [2450, 0, false], [5150, 0, false], [6750, 0, false],
	[8800, 0, false], [9700, 0, true], [11300, 0, true],
]

# [x, size_x, size_y, style]
const HURDLES := [
	[7300, 60, 58, "cart"], [8200, 60, 58, "cart"], [9050, 60, 46, "rocks"],
	[10150, 60, 54, "cart"], [11500, 60, 48, "rocks"], [12050, 60, 54, "cart"], [12600, 60, 48, "rocks"],
]

const LEAVES := [[1430, -170], [3530, -260], [5880, -200], [8690, -140], [10810, -150]]
const SUPPLIES := [[3000, -30], [5180, -30], [7100, -30], [8850, -30]]
const HORSE_HOME := Vector2(9500, 0)

# [id, x, y, width, once]
const TRIGGERS := [
	["pass", 250, 0, 60], ["battlefield", 2450, 0, 60], ["spear", 2650, 0, 60],
	["archer", 3150, 0, 60], ["allies", 3800, 0, 60], ["armoured", 4150, 0, 60],
	["choke", 5480, 0, 60, false], ["rear", 6780, 0, 60], ["chetak", 9250, 0, 60],
	["escape_end", 12800, 0, 120],
]

const DECOR := [
	{"type": "banner", "pos": Vector2(40, 0)}, {"type": "boulder", "pos": Vector2(900, 0), "size": 1.4},
	{"type": "tree", "pos": Vector2(2150, 0), "size": 0.8}, {"type": "boulder", "pos": Vector2(2700, 0), "size": 1.0},
	{"type": "banner", "pos": Vector2(3880, 0)}, {"type": "tree", "pos": Vector2(4950, 0), "size": 0.7},
	{"type": "boulder", "pos": Vector2(7450, 0)}, {"type": "flag", "pos": Vector2(7740, 0)},
	{"type": "flag", "pos": Vector2(8780, 0)}, {"type": "tree", "pos": Vector2(9650, 0), "size": 1.0},
	{"type": "sign", "pos": Vector2(9380, 0), "text": "Chetak"}, {"type": "flag", "pos": Vector2(10940, 0)},
	{"type": "tree", "pos": Vector2(12600, 0), "size": 1.2},
	{"type": "prop", "name": "rock", "pos": Vector2(1800, 0), "size": 0.7},
	{"type": "prop", "name": "crate", "pos": Vector2(7350, 0), "size": 0.45},
	{"type": "prop", "name": "barrel", "pos": Vector2(8250, 0), "size": 0.45, "flip": true},
	{"type": "prop", "name": "bush", "pos": Vector2(4000, 0), "size": 0.6},
	{"type": "prop", "name": "rock", "pos": Vector2(10500, 0), "size": 0.6},
]
