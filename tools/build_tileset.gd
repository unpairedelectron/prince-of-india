extends SceneTree
## Builds res://assets/tilesets/mewar_fort_tileset.tres from the asset pack's
## 64x64 fort tileset. Run: godot --headless -s res://tools/build_tileset.gd
## Collision classes (project decision, not in the pack's manifest):
##   solid      full 64x64 square  - floors, walls, wall cap, sandbag wall
##   one_way    10px strip at the plank's drawn height, one-way - wood_platform, platform_edge, stone_ledge
##   hazard     no collision, custom data "hazard" - spikes_a..d
##   decor      no collision       - doors, gate, column, ladder, rope, plate, slope, boulder, rubble
## Physics layer 1 = world (same layer as TerrainBlock), so all controllers work unchanged.

const SOLID := ["stone_floor_a", "stone_floor_b", "sandstone_floor", "dark_stone", "sandstone_brick", "rough_stone",
	"pale_stone", "brown_stone", "brick_wall_a", "brick_wall_b", "sandstone_wall", "fort_masonry", "block_wall",
	"carved_wall", "weathered_brick", "old_wall", "wall_cap", "sandbag_wall"]
const ONE_WAY := ["wood_platform", "platform_edge", "stone_ledge"]
const HAZARD := ["spikes_a", "spikes_b", "spikes_c", "spikes_d"]
## Walkable surface inside the tile, measured from the art (px from tile top).
## These tiles draw their plank/ledge mid-cell, NOT at the top edge.
const ONE_WAY_TOP := {"wood_platform": 42, "platform_edge": 48, "stone_ledge": 52}


func _init() -> void:
	var tex: Texture2D = load(MewarAssets.ROOT + MewarAssets.TILESET_PATH)
	if tex == null:
		push_error("Tileset texture missing")
		quit(1)
		return
	var ts := TileSet.new()
	ts.tile_size = Vector2i(64, 64)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(0, "kind")
	ts.set_custom_data_layer_type(0, TYPE_STRING)
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(1, "tile_name")
	ts.set_custom_data_layer_type(1, TYPE_STRING)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(64, 64)
	ts.add_source(src, 0)
	var n := 0
	for name in MewarAssets.TILE:
		var c: Vector2i = MewarAssets.TILE[name]
		src.create_tile(c)
		var td := src.get_tile_data(c, 0)
		var kind := "decor"
		if name in SOLID:
			kind = "solid"
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-32, -32), Vector2(32, -32), Vector2(32, 32), Vector2(-32, 32)]))
		elif name in ONE_WAY:
			kind = "one_way"
			td.add_collision_polygon(0)
			var top: float = ONE_WAY_TOP[name] - 32.0
			td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-32, top), Vector2(32, top), Vector2(32, top + 10), Vector2(-32, top + 10)]))
			td.set_collision_polygon_one_way(0, 0, true)
		elif name in HAZARD:
			kind = "hazard"
		td.set_custom_data("kind", kind)
		td.set_custom_data("tile_name", name)
		n += 1
	DirAccess.make_dir_recursive_absolute("res://assets/tilesets")
	var err := ResourceSaver.save(ts, "res://assets/tilesets/mewar_fort_tileset.tres")
	print("tileset tiles: %d, save err: %d" % [n, err])
	quit(0 if err == OK else 1)
