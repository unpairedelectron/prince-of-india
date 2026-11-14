# AJEYA: Legends Who Never Bowed
*4 legends. 20 battles. Zero surrender.*

A 2D side-scrolling action-platformer set across India's history. Godot 4.3+ / GDScript, Android-first, landscape.
("Ajeya" = unconquered. Working title; the repository is still named `prince-of-india`.)

**Status: all 20 levels are playable end to end.** Art and audio are still prototype placeholders (one asset pack for Mewar,
code-drawn figures and synthesised sound for everything else). See "What is not done" below.

## The four legends
| Hero | Where and when | Plays differently because | Levels |
|---|---|---|---|
| **Maharana Pratap** - The Lion of Mewar | Rajasthan, 1572-1582 | *Dhal Mastery*: cheap blocking, parries restore stamina. Rides Chetak. | The Oath of Mewar, The Yellow Pass, Chetak - The Final Ride, Shadows of the Aravalli, The Return of Mewar |
| **Chhatrapati Shivaji Maharaj** - Founder of Swarajya | The Sahyadri, 1646-1674 | *Ganimi Kava*: fast, cheap dodge; the strike after a dodge hits double. | The First Fort, The Tiger's Claw, The Night of Rain, Midnight at Lal Mahal, Road to Raigad |
| **Rani Lakshmibai** - The Queen of Jhansi | Bundelkhand, 1857-1858 | *Twin Blades*: much faster combos, wide parry window, costly blocking. Rides Badal. | Manikarnika, The Rani Takes Command, Jhansi Will Not Fall, The Leap, The Last Charge |
| **Lachit Borphukan** - Guardian of the Brahmaputra | Assam, 1667-1671 | *Hengdang*: more health, quick and crushing heavy blow, slightly slower. | The Hengdang, Night at Itakhuli, The Field of Alaboi, Not Greater Than My Country, Saraighat |

Each hero's five levels get harder (enemy health, damage and tempo scale with the level; traps and drifting platforms speed
up; later levels add musketeers, cannon fire and bosses). A hero opens when the previous hero's Level 1 is cleared. Every
level awards up to three stars: finish / two or fewer falls / every Chronicle Leaf.

## Run
Open the folder in Godot 4.3 or newer and press F5. Desktop keys: A/D move, W/S climb, Space jump, J attack (hold for heavy),
K block (tap just before a hit lands to parry), L dodge, E/F interact/mount, Shift (or J) gallop, Esc pause.
To try the touch buttons on desktop, set Settings > Touch controls > On. Mouse clicks act as touches.

## How levels are made
- Pratap's first three missions are hand-built scenes (`scripts/environments/mission_*.gd` + `data/missions/*_layout.gd`).
- The other 17 levels are data: `data/campaigns.gd` lists each hero (look, ability, stats) and each level as a short list of
  segments (`run`, `gap`, `stairs`, `tower`, `foes`, `arena`, `boss`, `spikes`, `crumble`, `pillars`, `movers`, `stones`,
  `volley`, `ride`, ...). `LevelBuilder` turns the list into terrain and spawn lists; `MissionCampaign` runs it.
  **Adding a level or a fifth hero means editing that one data file.**
- Themes (sky, parallax, terrain style, weather, music) and enemy factions (colours, headgear) are tables in the same file.

## Tests (need a window; under CI use `xvfb-run`)
- `res://tests/smoke.tscn`: every level builds and loads; menu, hero select and level select open.
- `res://tests/playtest_campaign.tscn -- <level id> ...`: a bot plays the given levels (default: all 17 data-driven ones)
  from start to finish.
- `res://tests/playtest.tscn`, `playtest_m2.tscn`, `playtest_m3.tscn`: Pratap's missions 1-3. `asset_test.tscn`: asset pack.
- Screenshots: `res://tests/screens_campaign.tscn -- <output folder> [<level id> <x,x,...>]`.

## History
Story cards are labelled HISTORICAL RECORD, TRADITIONAL ACCOUNT or GAMEPLAY - FICTIONAL. Every soldier and every boss is a
fictional composite; opponents are armies, never faiths or communities. See `documentation/HISTORICAL_REFERENCES.md` -
**the cards for the three new heroes have not been source-checked yet.**

## What is not done
- **Art.** Pratap, Chetak and the imperial soldier use the Mewar asset pack; Shivaji Maharaj, Rani Lakshmibai, Lachit
  Borphukan, their allies and enemies are code-drawn figures. The two styles do not match. Real character art, tilesets
  per region and backgrounds are the biggest gap between this build and a shippable game.
- **Audio.** All music and sound are synthesised placeholders.
- **Balance with human players.** Bots prove every level can be finished; nobody has tuned the difficulty by hand yet.
- **Android APK** has not been built (`export_presets.cfg` is included). Not tested on a phone.
- No voice, no localisation (Hindi / Marathi / Assamese text would matter for this audience), no store assets.

See `documentation/` for history notes, the asset manifest and test results.
