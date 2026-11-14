class_name MewarAssets
extends RefCounted
## Central access to "Prince of India - Mewar 2D Asset Pack v1" (assets/mewar_pack_v1).
## Atlas layout data is copied from the pack's manifest.json (kept in _source/).
## Builds and caches SpriteFrames / AtlasTextures so every scene shares them.
## If a file is missing, getters return null and callers fall back to the
## procedural placeholder art, so the game never breaks on a missing asset.

const ROOT := "res://assets/mewar_pack_v1/"

## name: [path, frame_size, {anim: [row, fps, loop]}]
const SHEETS := {
	"pratap": ["Characters/Maharana_Pratap/maharana_pratap_4x8_spritesheet.png", Vector2i(128, 160), {
		"idle": [0, 8, true], "walk": [1, 10, true], "run": [2, 10, true], "jump": [3, 10, false],
		"attack": [4, 10, false], "block": [5, 8, true], "hurt": [6, 10, false], "victory": [7, 10, false]}],
	"chetak": ["Characters/Chetak/chetak_4x4_spritesheet.png", Vector2i(192, 128), {
		"idle": [0, 7, true], "walk": [1, 10, true], "gallop": [2, 10, true], "jump": [3, 10, true]}],
	"imperial": ["Characters/Enemies/imperial_soldier_4x4_spritesheet.png", Vector2i(128, 160), {
		"idle": [0, 8, true], "walk": [1, 8, true], "attack": [2, 8, false], "hurt": [3, 8, false]}],
}

const PROPS := ["torch", "banner", "crate", "barrel", "pot", "rock", "bush", "tree",
	"spikes", "ladder", "bridge", "chest", "health_potion", "coin", "key", "checkpoint"]
const UI_ICONS := ["heart", "sword", "shield", "jump", "left", "right", "pause", "play",
	"horse", "coin", "key", "map", "home", "settings", "sound", "interact"]
const EFFECT_ROWS := ["slash", "spark", "dust", "fire"]

## Fort tileset cells (from manifest.json). Collision classes are a project decision.
const TILE := {
	"stone_floor_a": Vector2i(0, 0), "stone_floor_b": Vector2i(1, 0), "sandstone_floor": Vector2i(2, 0),
	"dark_stone": Vector2i(3, 0), "sandstone_brick": Vector2i(4, 0), "rough_stone": Vector2i(5, 0),
	"pale_stone": Vector2i(6, 0), "brown_stone": Vector2i(7, 0),
	"brick_wall_a": Vector2i(0, 1), "brick_wall_b": Vector2i(1, 1), "sandstone_wall": Vector2i(2, 1),
	"fort_masonry": Vector2i(3, 1), "block_wall": Vector2i(4, 1), "carved_wall": Vector2i(5, 1),
	"weathered_brick": Vector2i(6, 1), "old_wall": Vector2i(7, 1),
	"wall_cap": Vector2i(0, 2), "wood_door": Vector2i(1, 2), "arched_door": Vector2i(2, 2),
	"fort_gate": Vector2i(3, 2), "column_base": Vector2i(4, 2), "stone_ledge": Vector2i(5, 2),
	"ladder_tile": Vector2i(6, 2), "rope_detail": Vector2i(7, 2),
	"spikes_a": Vector2i(0, 3), "spikes_b": Vector2i(1, 3), "spikes_c": Vector2i(2, 3), "spikes_d": Vector2i(3, 3),
	"pressure_plate": Vector2i(4, 3), "wood_platform": Vector2i(5, 3), "gate_panel": Vector2i(6, 3),
	"platform_edge": Vector2i(7, 3),
	"rock_slope": Vector2i(0, 4), "boulder": Vector2i(1, 4), "sandbag_wall": Vector2i(2, 4), "rubble": Vector2i(3, 4),
}
const TILESET_PATH := "Environment/Tilesets/mewar_fort_tileset_8x5.png"
const TILE_SIZE := 64

static var _cache := {}
static var enabled := true   ## set false to force procedural placeholders (A/B testing)


static func tex(rel: String) -> Texture2D:
	if not enabled:
		return null
	var key := "tex:" + rel
	if _cache.has(key):
		return _cache[key]
	var path := ROOT + rel
	var t: Texture2D = null
	if ResourceLoader.exists(path):
		t = load(path)
	else:
		push_warning("Mewar asset missing: " + path)
	_cache[key] = t
	return t


static func frames(sheet: String) -> SpriteFrames:
	var key := "frames:" + sheet
	if _cache.has(key):
		return _cache[key]
	var spec: Array = SHEETS[sheet]
	var t := tex(spec[0])
	if t == null:
		return null
	var fs: Vector2i = spec[1]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var anims: Dictionary = spec[2]
	for a in anims:
		sf.add_animation(a)
		sf.set_animation_speed(a, anims[a][1])
		sf.set_animation_loop(a, anims[a][2])
		for c in 4:
			var at := AtlasTexture.new()
			at.atlas = t
			at.region = Rect2(c * fs.x, anims[a][0] * fs.y, fs.x, fs.y)
			sf.add_frame(a, at)
	_cache[key] = sf
	return sf


## A sub-rectangle of one frame (e.g. the rider's upper body for mounted poses).
static func frame_region(sheet: String, anim: String, col: int, sub: Rect2) -> AtlasTexture:
	var spec: Array = SHEETS[sheet]
	var t := tex(spec[0])
	if t == null:
		return null
	var fs: Vector2i = spec[1]
	var row: int = spec[2][anim][0]
	var at := AtlasTexture.new()
	at.atlas = t
	at.region = Rect2(col * fs.x + sub.position.x, row * fs.y + sub.position.y, sub.size.x, sub.size.y)
	return at


static func _cell(rel: String, idx: int, cell: int, cols: int) -> AtlasTexture:
	var key := "cell:%s:%d" % [rel, idx]
	if _cache.has(key):
		return _cache[key]
	var t := tex(rel)
	if t == null or idx < 0:
		return null
	var at := AtlasTexture.new()
	at.atlas = t
	at.region = Rect2((idx % cols) * cell, (idx / cols) * cell, cell, cell)
	_cache[key] = at
	return at


static func prop(name: String) -> Texture2D:
	return _cell("Environment/Props/mewar_props_4x4.png", PROPS.find(name), 128, 4)


static func icon(name: String) -> Texture2D:
	return _cell("UI/mewar_ui_icons_4x4.png", UI_ICONS.find(name), 96, 4)


static func tile(name: String) -> AtlasTexture:
	var key := "tile:" + name
	if _cache.has(key):
		return _cache[key]
	var t := tex(TILESET_PATH)
	if t == null or not TILE.has(name):
		return null
	var c: Vector2i = TILE[name]
	var at := AtlasTexture.new()
	at.atlas = t
	at.region = Rect2(c.x * TILE_SIZE, c.y * TILE_SIZE, TILE_SIZE, TILE_SIZE)
	_cache[key] = at
	return at


static func effect_frames() -> SpriteFrames:
	if _cache.has("fx"):
		return _cache["fx"]
	var t := tex("Effects/combat_effects_4x4.png")
	if t == null:
		return null
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for r in EFFECT_ROWS.size():
		var n: String = EFFECT_ROWS[r]
		sf.add_animation(n)
		sf.set_animation_speed(n, 18 if n != "fire" else 10)
		sf.set_animation_loop(n, n == "fire")
		for c in 4:
			var at := AtlasTexture.new()
			at.atlas = t
			at.region = Rect2(c * 96, r * 96, 96, 96)
			sf.add_frame(n, at)
	_cache["fx"] = sf
	return sf


static func background(name: String) -> Texture2D:
	return tex("Environment/Backgrounds/%s.png" % name)
