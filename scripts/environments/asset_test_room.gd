class_name AssetTestRoom
extends MissionBase
## Playable test room for the Mewar 2D Asset Pack v1 integration.
## Floor, tower and platforms are a real TileMapLayer using
## res://assets/tilesets/mewar_fort_tileset.tres (collision from the TileSet).

const L = preload("res://data/missions/asset_test_layout.gd")
const TILESET := "res://assets/tilesets/mewar_fort_tileset.tres"

var tilemap: TileMapLayer
var soldier: Soldier
var ally: Soldier


func _init() -> void:
	mission_id = "asset_test"
	title = "Asset Test Room (development)"
	layout = L
	parallax = [
		[Vector2(0.05, 0.08), "bg:kumbhalgarh_parallax", 82.0, 85, -55],
		[Vector2(0.15, 0.15), "bg:fort_silhouette", 84.0, 30, -50, Color(1, 1, 1, 0.5)],
	]
	horse_home = Vector2(2600, 0)
	start_objective = "Try every move. Mount Chetak (F). Spar with the soldier."
	music = ""
	ambience = ""


func _build_terrain() -> void:
	super._build_terrain()
	tilemap = TileMapLayer.new()
	tilemap.tile_set = load(TILESET)
	tilemap.name = "FortTiles"
	add_child(tilemap)
	var T := MewarAssets.TILE
	# floor: walkable top row + masonry below (cells are 64px; row 0 top = y 0)
	for x in range(-10, 60):
		tilemap.set_cell(Vector2i(x, 0), 0, T["sandstone_floor"])
		for y in range(1, 4):
			tilemap.set_cell(Vector2i(x, y), 0, T["sandstone_wall"] if (x + y) % 3 else T["fort_masonry"])
	# tower with wall cap (solid) reached by the ladder at x~1262
	for x in range(20, 24):
		tilemap.set_cell(Vector2i(x, -4), 0, T["wall_cap"])
		for y in range(-3, 0):
			tilemap.set_cell(Vector2i(x, y), 0, T["fort_masonry"])
	# one-way platforms (walkable surface measured from the art)
	for x in range(8, 11):
		tilemap.set_cell(Vector2i(x, -2), 0, T["wood_platform"])    # surface y = -86
	for x in range(13, 15):
		tilemap.set_cell(Vector2i(x, -3), 0, T["platform_edge"])    # surface y = -144
	tilemap.set_cell(Vector2i(16, -4), 0, T["stone_ledge"])          # surface y = -204
	# decor tiles (no collision)
	tilemap.set_cell(Vector2i(3, -1), 0, T["arched_door"])
	tilemap.set_cell(Vector2i(5, -1), 0, T["column_base"])
	tilemap.set_cell(Vector2i(30, -1), 0, T["spikes_a"])   # hazard data only (no damage system yet)
	tilemap.set_cell(Vector2i(31, -1), 0, T["rubble"])


## Test room never touches the player's saved progress.
func _apply_save() -> void:
	checkpoints[0].activate(true)
	ui.fade_to(0.0, 0.4)


func _build_mission() -> void:
	soldier = spawn_soldier(Vector2(3300, 0), "sword", "imperial", {"patrol_distance": 120.0})
	ally = spawn_soldier(Vector2(250, 0), "sword", "mewar", {"detect_range": 0.0})
