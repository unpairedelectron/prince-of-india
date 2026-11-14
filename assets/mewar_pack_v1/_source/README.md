# Prince of India – Mewar 2D Asset Pack v1

An original starter art pack for the Maharana Pratap MVP. It contains transparent character atlases, modular 64×64 environment tiles, props, combat effects, UI icons and three regional background scenes. Assets are delivered as PNG files with optional source SVGs and JSON atlas metadata.

## What's included

- **Maharana Pratap:** 4×8 atlas, 128×160 frame size; idle, walk, run, jump, attack, block, hurt and victory (4 frames each). Individual 4-frame strips are included too.
- **Chetak:** 4×4 atlas, 192×128 frame size; idle, walk, gallop and jump. Individual strips included.
- **Imperial soldier:** 4×4 atlas, 128×160 frame size; idle, walk, attack and hurt.
- **Allies/NPCs:** Rajput ally, Bhil warrior and villager standees.
- **Fort tileset:** 8 columns × 6 rows, 64×64 pixels per tile (the final row has four unused cells). Includes stone, sandstone, walls, doors, platforms, ladders, spikes, ledges and rubble. Exact tile names and atlas rectangles are in `manifest.json`.
- **Props:** 4×4 atlas of torches, banner, crate, barrel, pot, rock, bush, tree, spikes, ladder, bridge, chest, potion, coin, key and checkpoint.
- **Effects:** slash, spark, dust and fire strips.
- **UI:** 16 transparent control/HUD icons.
- **Backgrounds:** Kumbhalgarh/Mewar, Haldighati and Aravalli forest (1600×600), plus reusable silhouettes.

## Godot 4 setup

1. Copy the `Characters`, `Environment`, `Effects` and `UI` folders into your Godot project's `res://` directory.
2. Select each PNG atlas in the FileSystem dock and set **Import → Filter** according to your preferred rendering style. For crisp pixel-style rendering use nearest filtering; for the supplied vector-raster style, linear filtering may look smoother. Reimport after changing settings.
3. For a character atlas, use `Sprite2D` with `hframes=4` and `vframes=8` for Maharana Pratap. The row order is listed in `manifest.json`. To animate with `AnimatedSprite2D`, create one animation per row using four `AtlasTexture` regions.
4. `Godot_Integration/mewar_asset_helper.gd` contains a small helper for building a `SpriteFrames` resource from a sheet. It is a starting utility; adjust looping and FPS to the desired feel.
5. The fort tileset is a regular 8×5 grid of 64×64 cells and can be configured in a `TileSetAtlasSource`. See tile coordinates in `manifest.json`.
6. Use the background PNGs as `Parallax2D` layers or `Sprite2D` nodes, scaling and repeating as needed.

## Important production notes

- These are **starter/prototype assets**, not finished hand-painted AAA assets. They are original stylized vector illustrations rasterized to PNG. Expect to tune animation timing, collision shapes, pivots, hitboxes and scale inside the game.
- The supplied character views are side-facing and use consistent atlas cells, but individual animation frames may need cleanup before a polished release.
- Backgrounds are single-layer illustrations; create additional parallax separation in the level by placing the supplied silhouettes and foreground props on separate nodes.
- No real historical person is being represented photorealistically. The hero is a stylized, historically inspired game interpretation.

## File format

- PNG: import-ready raster assets.
- SVG: editable vector source for selected characters, props and backgrounds.
- JSON: asset atlas manifest.
- GDScript: optional Godot helper.

## License / usage

These assets were created specifically for this project. You may use and modify them in your own Prince of India game project and related builds. Do not resell or redistribute this pack as a standalone asset collection, and do not claim the artwork is an official historical or government archive. Third-party fonts, engines and other dependencies are not included.
