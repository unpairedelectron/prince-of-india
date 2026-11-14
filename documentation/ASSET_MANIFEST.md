# Asset manifest

## Licensed asset pack (integrated 14 Nov 2026)
**Prince of India - Mewar 2D Asset Pack v1**: `res://assets/mewar_pack_v1/`. Original artwork created for this project;
licence `_source/LICENSE.txt` (use in the game and compiled builds; do not resell or redistribute the pack). Status: **starter /
prototype art** (per the pack README), not final. Details, mapping and known problems: `ASSET_INTEGRATION.md`.
In use: Pratap (8 anims), Chetak (4), imperial soldier (4), ally standees, fort tileset (TileSet resource), 3 backgrounds +
3 silhouettes, props, combat effects, UI icons.

## Procedural placeholders still in use

All current art and audio is **PLACEHOLDER** and original: drawn in code or synthesised by script. No third-party assets are used.

| Asset | Where | Status | Licence | Final replacement |
|---|---|---|---|---|
| Maharana Pratap figure + all 25 poses | scripts/systems/human_rig.gd | Placeholder (procedural vector) | Original | Hand-animated sprite sheets in the same 21+ states, Mewar painting-inspired |
| Practice opponents | human_rig.gd palette in soldier.gd | Placeholder | Original | Sprite sheets per enemy archetype |
| Imperial soldiers (sword, spear, archer, armoured) + Mewar allies + Bhil archer ally | soldier.gd palettes + human_rig.gd (spear/bow) | Placeholder | Original | Sprite sheets per archetype; respectful, period-appropriate dress researched with a costume reference |
| Arrows, arrow volleys | arrow.gd, falling_stones.gd | Placeholder | Original | Painted projectile + VFX |
| Chetak + 10 states (incl. calm "rest" pose) | scripts/companions/horse_rig.gd | Placeholder | Original | Hand-animated horse sheets (idle, walk, trot, gallop, jump, land, rear, turn, mount) |
| Terrain (sandstone, earth, planks) | scripts/environments/terrain_block.gd | Placeholder | Original | Painted tilesets |
| Haldighati backdrops (yellow rock outcrops, distant generic troop columns), Aravalli forest | backdrop.gd | Placeholder | Original | Painted parallax layers |
| Water stream, low branches, sloped terrain, rope bridge | water_zone.gd, low_branch.gd, terrain_poly.gd, crumbling_platform.gd | Placeholder | Original | Painted tiles/props |
| Memorial (generic chhatri platform, not a reconstruction) | gogunda_decor.gd `_memorial` | Placeholder | Original | Painted prop; keep generic or consult ASI imagery licence |
| Parallax (Aravalli ridges, hill-fort wall, Gogunda town, foreground) | backdrop.gd | Placeholder | Original | Painted parallax layers |
| Set dressing (arcades, torches, stable, racks, signs) | gogunda_decor.gd | Placeholder | Original | Painted props |
| Objects (lamp checkpoints, ladders, gates, hurdles, leaves) | scripts/objects/*.gd | Placeholder | Original | Painted props |
| UI theme, touch icons | ui_kit.gd, touch_button.gd | Placeholder | Original | Designed UI kit |
| App icon | assets/ui/icon.png | Placeholder | Original (script-generated) | Designed icon |
| 29 sound effects (+ bow, arrow volley, splash, branch) | assets/audio/sfx/*.wav | Placeholder (synthesised) | Original | Recorded/licensed foley |
| Music "gogunda_theme", "battle_theme", "ride_theme" (drone + percussion loops), "wind" | assets/audio/music/*.wav | Placeholder (synthesised) | Original | Composed score with Rajasthani instrumentation |

Generator script for audio/icon: tools/make_assets.py

## Added with the four-hero structure (all placeholder, all original)
| What | Where | How it is made |
|---|---|---|
| Shivaji Maharaj, Rani Lakshmibai, Lachit Borphukan (player figures) | `HumanRig` + `Campaigns.HEROES[..].look` | Code-drawn puppet: palette, headgear (jiretop / battle turban with plait / Ahom head-cloth), beard, twin swords. **Needs real character art; does not match the Mewar pack style.** |
| Faction soldiers (Bijapur, Mughal, Orchha, Company, Ahom / Maratha / Jhansi allies) | `Soldier` + `Campaigns.FACTIONS` | Same puppet recoloured, with helmet / shako / turban; musketeer weapon; gold-armoured boss with plume. No faith symbols. |
| Terrain styles basalt, grass, deck | `TerrainBlock` | Code-drawn |
| Backdrops ghats, river, fortline, fleet; rain; river water | `Backdrop`, `MissionCampaign` | Code-drawn |
| Spear trap, raft / boat / lift | `SpikeTrap`, `MovingPlatform` | Code-drawn |
| Music: sahyadri_theme, jhansi_theme, assam_theme, night_theme, boss_theme; ambience: rain | `assets/audio/music/` | `tools/make_audio_campaigns.py` (synthesised) |
| SFX: spike, musket, cannon | `assets/audio/sfx/` | same script |

Priority order for commissioned art: (1) the three new heroes, to the same standard as a re-drawn Pratap; (2) one enemy
sheet per faction with side-on attack frames; (3) a tileset and two backgrounds each for the Sahyadri, Jhansi and Assam.
