class_name AssetTestLayout
extends RefCounted
## Asset Test Room: geometry comes from the fort TileMapLayer (see mission script);
## only boundaries and checkpoints are listed here.
const LIMITS := Rect2i(-700, -1200, 4600, 1440)
const BLOCKS := [[-760, -700, 100, 1300, "fort"], [3840, -700, 100, 1300, "fort"], [1238, -256, 44, 10, "plank"]]
const CHECKPOINTS := [[100, 0, false]]
const LEAVES := []
const SUPPLIES := [[700, -40]]
const LADDERS := [[1262, -128, 256]]
const TRIGGERS := []
const DECOR := [
	{"type": "torch", "pos": Vector2(40, 0)}, {"type": "torch", "pos": Vector2(1150, 0)},
	{"type": "prop", "name": "crate", "pos": Vector2(380, 0), "size": 0.5},
	{"type": "prop", "name": "barrel", "pos": Vector2(440, 0), "size": 0.5},
	{"type": "prop", "name": "pot", "pos": Vector2(500, 0), "size": 0.4},
	{"type": "prop", "name": "bush", "pos": Vector2(2000, 0), "size": 0.6},
	{"type": "prop", "name": "tree", "pos": Vector2(2300, 0), "size": 1.3},
	{"type": "prop", "name": "rock", "pos": Vector2(3600, 0), "size": 0.6},
	{"type": "prop", "name": "chest", "pos": Vector2(1500, -256), "size": 0.45},
]
