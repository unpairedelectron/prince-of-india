# Test results
Engine: Godot 4.3-stable (Linux), gl_compatibility renderer. Tests run under Xvfb with an OpenGL window (Mesa llvmpipe), 1280x720.

## Milestone 3: Mewar 2D Asset Pack v1 integration (14 Nov 2026)
| Suite | Result |
|---|---|
| `godot --headless --import` (pack + project) | no errors |
| `tools/build_tileset.gd` | TileSet saved: 36 tiles, 18 solid, 3 one-way, 4 hazard-tagged |
| `tests/asset_test.tscn` (new: Asset Test Room) | **35/35 passed** |
| `tests/playtest.tscn` (Mission 1) | 50/50 in 3 of 4 runs; **1 run failed "multi-touch moves and jumps"** (jump touch not registered; intermittent, not yet diagnosed) |
| `tests/playtest_m2.tscn` / `playtest_m3.tscn` | 21/21, 15/15 |
| Screenshots `tests/screens3.tscn` | reviewed: feet on tiles, plank landing, rider in saddle, backgrounds placed correctly after fix |

Asset test covers: 8 Pratap animations configured (4 frames each); idle/walk/run/jump/attack (frames 0-3 step with the hit timing)/
block/hurt/victory triggered by real input; standing on TileMapLayer floor; landing on all 3 one-way tiles at the drawn plank height
(-86/-144/-204 px); jumping up through a one-way tile; solid tile tower; ladder onto the tower; Chetak's 4 animations while ridden;
rider upper-body crop anchored to the saddle; dismount; imperial soldier sheet walk/attack/hurt in a real fight; ally standee;
slash and spark effects spawned; asset icons on touch buttons; painted background layers present.

Fixed during this milestone: attack/dodge animation overwritten in the same frame; ladder top re-grab loop; climbing stuck under one-way lips;
painted backgrounds misplaced under camera zoom.

## Milestone 2: Missions 2 and 3 (14 Nov 2026)
| Suite | Result |
|---|---|
| `tests/playtest.tscn`: Mission 1 regression after refactor to MissionBase | **50/50 passed** |
| `tests/playtest_m2.tscn`: Mission 2 Haldighati | **21/21 passed** (bot: 0 falls, ~95 s) |
| `tests/playtest_m3.tscn`: Mission 3 Chetak's ride | **15/15 passed** (bot: 0 falls) |
| `godot --headless --import` | no parse errors |
| Engine error output during all suites | none (after fix below) |
| Screenshots `tests/screens2.tscn` (12 views) | reviewed manually |

### Mission 2 checks (all pass)
4 enemy archetypes present; allies present; shield blocks a frontal arrow; bot fights through the pass and battlefield;
archers fire; **allies damage enemies on their own**; chokepoint locks, all 3 waves cleared, exit opens; rear guard
with carts, ditches and arrow volleys crossed; mount Chetak; dismount locked during escape; escape ride reaches the hills;
mission completes as survival; Mission 3 unlocks; outro states the imperial army held the field.

### Mission 3 checks (all pass)
Starts mounted, mounted touch layout; **jumping into a low branch makes Chetak balk**; **a falling stone striking Chetak
makes him balk**; full course ridden (gaps, rope bridge, slopes, stream, passage, descent, crumbling ground, final leap);
stream slows Chetak; final sequence: rider dismounts, Chetak rests (calm pose), control returns, "Stay a while" prompt,
farewell, memorial shown, mission completes; outro labelled as traditional account.

### Bugs found and fixed by testing
- **Unfair horse obstacle spacing**: landing from one obstacle put Chetak straight into the next gap (Mission 2 escape),
  rocks sat under a low branch, and the final stream was wider than a full-gallop leap plus the horse's length (Mission 3).
  Fixed with a spacing rule of at least ~600 px at gallop.
- Soldiers spawned inside a physics callback caused engine errors; the chokepoint now starts deferred.
- Chetak's rest pose read as collapsed; it now shows legs folded and head up.

## Milestone 1 (Mission 1) - still covered by the regression suite above
Movement, jump/buffer, combo/heavy/block/parry/dodge, AI, ladder, crumbling slab, respawn, mount, gallop,
full horse course, dismount, multi-touch (move + jump together), mission complete, save/load.

## Not verified
- **Android APK: not built.** Google's Android SDK download is blocked here. export_presets.cfg is included.
- On a real phone: feel, performance, notches, pause on app switch. Audio playback (no sound device; files load).
- Difficulty with human players: bots heal themselves in fights and read obstacle positions from the level data.
- Mission 3 runs ~25 s for a perfect bot; a human will take longer, but it is probably still short.

## Known issues
- All art and audio are placeholders (see ASSET_MANIFEST.md). Mounted enemy soldiers are not implemented (scope).
- Godot prints harmless "resources still in use at exit" warnings.
