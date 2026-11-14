# Prince of India: Maharana Pratap - The Defender of Mewar
Godot 4.3+ / GDScript, Android-first, landscape. Status: **Milestone 2. Missions 1-3 are playable end to end** (Gogunda, Haldighati, Chetak's ride). Mission 4 (Dewair) and the epilogue are not built yet.

## Run
Open the folder in Godot 4.3 or newer and press F5. Desktop keys: A/D move, W/S climb, Space jump, J attack (hold for heavy),
K block (tap just before a hit lands to parry), L dodge, E/F interact/mount, Shift (or J) gallop, Esc pause.
To try the touch buttons on desktop, set Settings > Touch controls > On. Mouse clicks act as touches.

## Tests
- Playtests (need a window): `res://tests/playtest.tscn` (M1, 50 checks), `playtest_m2.tscn` (21), `playtest_m3.tscn` (15)
- Screenshots: `res://tests/screens.tscn` / `screens2.tscn -- <output folder>`
- Main menu > Chapters lets you replay any unlocked mission.

## Android
Install Godot export templates + Android SDK, set the paths in Editor Settings, then Project > Export > Android.

See documentation/ for history sources, the asset manifest and test results.
