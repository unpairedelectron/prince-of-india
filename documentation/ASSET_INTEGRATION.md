# Mewar 2D Asset Pack v1: integration report
Integrated 14 Nov 2026. Pack copied unchanged to `res://assets/mewar_pack_v1/` (SHA-256 verified against the
original zip: `_source/ORIGINAL_SHA256.txt`). Vector sources, README, licence, manifest and the pack's helper script
are kept in `_source/` (ignored by Godot via `.gdignore`). Licence: project use allowed; do not resell the pack.

## How it is wired (gameplay architecture unchanged)
| Asset | Used by | Node / resource |
|---|---|---|
| Pratap 4x8 atlas (8 anims) | Player | `SpriteRig` (extends `HumanRig`) -> AnimatedSprite2D; same API, so `player.gd` logic and collision are unchanged |
| Chetak 4x4 atlas (4 anims) | Horse | `HorseSprite` (extends `HorseRig`); saddle anchor measured from the art |
| Imperial soldier 4x4 | Imperial sword / spear / armoured soldiers | `SpriteRig` sheet "imperial" (armoured = steel tint, 1.1x scale) |
| Rajput ally, Bhil warrior | Mewar allies / Bhil archer ally | `SpriteRig.use_standee()` (single image + bob/lean) |
| Fort tileset 64x64 | `res://assets/tilesets/mewar_fort_tileset.tres` (built by `tools/build_tileset.gd`); TileMapLayer in Asset Test Room; fort/paving terrain in all missions draws these tiles | |
| Backgrounds (Kumbhalgarh, Haldighati, Aravalli) + silhouettes | Missions 1/2/3 + test room + main menu | `ScreenBackdrop` (screen-space parallax, zoom-independent, graded per mission) |
| Props | torches, ladders, checkpoints (flag), supply (clay pot), rocks, crates, barrels, pots, bushes, trees, chest | decor `prop` items, `Ladder`, `Checkpoint`, `Collectible`, `Hurdle` |
| Effects | slash on every swing, spark on hits/blocks, dust on jumps/landings, fire on torches and lit checkpoints | `Fx.effect()` |
| UI icons | touch buttons (left, right, up/down, jump, sword, horse, pause, interact), HUD heart | `TouchButton.ICONS`, `MissionUI` |

All getters go through `MewarAssets`; a missing file logs a warning and the old procedural art is used instead.

## Animation mapping (pack -> game states)
| Game state | Pratap atlas | Notes |
|---|---|---|
| idle / walk / run / block / hurt / victory | same-named row | direct |
| sprint | run x1.45 speed | no sprint row |
| jump / fall | jump frame 1 / frame 3 (held) | jump row is grounded striding, see issues |
| land | idle f0 + squash | **missing** |
| attack1-3, heavy | attack row, frame chosen by attack progress (synced to hitbox timing) | heavy adds tilt |
| heavy wind-up | attack f0 held + shake | **missing** |
| parry | block f0 + tilt | **missing** |
| dodge | run x2 + low lean | **missing** |
| crouch / crouch-walk | idle/walk squashed to 70% height | **missing** |
| climb | block frames + bob | **missing** |
| defeated (kneel) | hurt f3, sunk + tilted | **missing** |
| interact | idle f1 + tilt | **missing** |
| mounted | idle f0 cropped to the upper body (head to waist), seated on the saddle | **missing riding pose** |
| mount / dismount | instant switch | **missing** |

| Chetak state | Atlas | Notes |
|---|---|---|
| idle / walk / gallop / jump | same-named row | direct |
| trot | walk x1.6 | **missing** |
| fall / land | jump, gallop | |
| rear (stumble) | idle pitched back 18 deg | **missing** |
| rest (Mission 3 ending) | idle at 0.35x speed: Chetak stands quietly | **missing lying pose**; the procedural lying pose was dropped to keep one art style |

| Imperial soldier | Atlas | Notes |
|---|---|---|
| idle / walk / attack / hurt | direct | |
| telegraph | attack f1 held + lean back | |
| block | idle f0 + lean | **missing** |
| defeated | hurt f3, kneel-sink, fade | **missing** |

## Problems found in the pack
1. **Imperial soldier is front-facing**, not side-on, and its "attack" row only spreads the arms with no visible strike.
   It reads poorly in a side-scroller; telegraph tint and "!" still carry readability. Needs side-view frames.
2. **Clipped frames**: Pratap's jump frames (all 4) and attack frames 3-4 touch the right cell edge (sword cut off);
   Chetak's walk/gallop/jump frames touch the top edge (ears/head clipped).
3. **Pratap "jump" row is not airborne** (striding legs). **Chetak "jump" row looks like walking** (no tucked legs).
4. **Style vs brief**: Pratap has chunky cartoon proportions (large head), while the project brief asks for realistic
   proportions. His shield is a **pointed, European-style shield**, not a round Rajput *dhal*.
5. **Cross emblems**: the UI "shield" icon carries a red cross (reads as a crusader/European symbol), and the banner prop has
   a circle-and-cross emblem. Neither is used; Block keeps the procedural round-shield glyph and pennants stay procedural.
6. **Tileset**: the file is named `..._8x5.png` but is 8x6 cells; row 4 has 4 tiles and **row 5 is empty**
   (README says "final row has four unused cells"; README step 5 says 8x5).
   **Platform tiles draw their plank mid-cell** (wood_platform 42 px, platform_edge 48 px, stone_ledge 52 px from the top),
   and platform, ladder and gate tiles have **opaque grey backgrounds**, so floating platforms look like grey boxes.
   Collision was matched to the drawn plank heights (verified by test).
7. **Backgrounds** include a dark half-ellipse at the bottom centre and only approximately match at the edges
   (mean edge difference 2-14/255), so there is a faint seam each time they repeat. The Aravalli scene is green daylight;
   Mission 3 tints it to evening.
8. Allies and villager are **single front-facing standees** (no animation). The Bhil warrior standee has no bow, while the game's
   Bhil ally is an archer.
9. **Not covered by the pack** (procedural art kept): Mewar training partners (Mission 1), imperial and allied archers (bow),
   rope bridge, low branches, water, memorial, Chronicle Leaf.
10. Unused: health_potion (fantasy look; the clay pot is used for health), coin, key, spikes prop/tiles (hazard data is defined
   in the TileSet but there is no spike-damage system yet), villager, map/home/settings/sound/play icons.

## Engine bugs found while integrating (fixed)
- Attack and dodge animations were overwritten by idle/walk in the same frame (affected the old procedural art too).
- Holding Up at a ladder's top re-grabbed the ladder in an endless loop; climbing up could stick under one-way lips.
- Painted backgrounds placed with Parallax2D sat too high because of the 1.28x camera zoom; they now use screen-space layers.
