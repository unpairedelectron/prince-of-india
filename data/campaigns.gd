class_name Campaigns
extends RefCounted
## All heroes, their looks and abilities, and their five levels each.
## Levels of kind "scene" are the hand-built missions; every other level is a
## segment list consumed by LevelBuilder (scripts/environments/level_builder.gd).
##
## Segment vocabulary:  run w | gap w | step dy | stairs n dy w | tower h |
##   foes [[type, offset]..] w | allies [[type, offset]..] | arena waves w |
##   boss cfg w | spikes n | crumble n | pillars n gap | movers n style |
##   stones w | volley w style | cp | supply | leaf dy | hint text | obj text | ride n
## Enemy types: sword, spear, archer, armoured, musket.
##
## Story cards are tagged so players can tell documented history, traditional
## accounts and invented gameplay apart (see documentation/HISTORICAL_REFERENCES.md).
## Every soldier and every boss the player fights is a fictional composite.

const H := "HISTORICAL RECORD"
const T := "TRADITIONAL ACCOUNT"
const F := "GAMEPLAY - FICTIONAL"

const GAME_TITLE := "AJEYA"
const GAME_SUBTITLE := "LEGENDS WHO NEVER BOWED"
const GAME_TAGLINE := "4 legends.  20 battles.  Zero surrender."

const SCENE_LEVEL := "res://scenes/environments/campaign/campaign_level.tscn"
const HERO_ORDER := ["pratap", "shivaji", "lakshmibai", "lachit"]

# ------------------------------------------------------------------ factions
# Visuals only. "imperial" = whoever opposes the hero in that campaign.

const FACTIONS := {
	"bijapur": {
		"foe_name": "Bijapur soldier",
		"imperial": {"turban": Color("d8d2c0"), "turban_band": Color("3d6b63"), "jama": Color("2f5d5a"), "jama_trim": Color("c9b98a"), "sash": Color("8c6a2b"), "pants": Color("d8d0bc"), "headgear": "helmet"},
		"ally": {"turban": Color("b3392b"), "turban_band": Color("e8892b"), "jama": Color("efe6d2"), "jama_trim": Color("e8892b"), "sash": Color("e8892b"), "pants": Color("efe6d2"), "headgear": "turban"},
	},
	"mughal": {
		"foe_name": "Imperial soldier",
		"imperial": {"turban": Color("e4ddc8"), "turban_band": Color("8a2b2b"), "jama": Color("5f7385"), "jama_trim": Color("c9b98a"), "sash": Color("8a2b2b"), "pants": Color("d8d0bc"), "headgear": "helmet"},
		"ally": {"turban": Color("b3392b"), "turban_band": Color("e8892b"), "jama": Color("efe6d2"), "jama_trim": Color("e8892b"), "sash": Color("e8892b"), "pants": Color("efe6d2"), "headgear": "turban"},
	},
	"orchha": {
		"foe_name": "Orchha soldier",
		"imperial": {"turban": Color("d9b23a"), "turban_band": Color("6b4a1c"), "jama": Color("6b5a8c"), "jama_trim": Color("d9b23a"), "sash": Color("d9b23a"), "pants": Color("e2d9c2"), "headgear": "turban"},
		"ally": {"turban": Color("2f7a5c"), "turban_band": Color("c9a14a"), "jama": Color("8c2f3a"), "jama_trim": Color("c9a14a"), "sash": Color("2f7a5c"), "pants": Color("efe6d2"), "headgear": "turban"},
	},
	"company": {
		"foe_name": "Company soldier",
		"imperial": {"turban": Color("26262e"), "turban_band": Color("c9a14a"), "jama": Color("b3261e"), "jama_trim": Color("efe6d2"), "sash": Color("efe6d2"), "pants": Color("3a3f52"), "headgear": "shako", "moustache": false},
		"ally": {"turban": Color("2f7a5c"), "turban_band": Color("c9a14a"), "jama": Color("8c2f3a"), "jama_trim": Color("c9a14a"), "sash": Color("2f7a5c"), "pants": Color("efe6d2"), "headgear": "turban"},
	},
	"mughal_east": {
		"foe_name": "Imperial soldier",
		"imperial": {"turban": Color("e4ddc8"), "turban_band": Color("8a2b2b"), "jama": Color("6a6f8c"), "jama_trim": Color("c9b98a"), "sash": Color("8a2b2b"), "pants": Color("d8d0bc"), "headgear": "helmet"},
		"ally": {"turban": Color("f2ecdc"), "turban_band": Color("b3261e"), "jama": Color("f2ecdc"), "jama_trim": Color("b3261e"), "sash": Color("b3261e"), "pants": Color("f2ecdc"), "headgear": "ahom"},
	},
}

# ------------------------------------------------------------------ themes

const THEMES := {
	"aravalli_night": {
		"terrain": "ground", "sky": [Color("141a36"), Color("3a3350"), Color("5a4a55")], "grade": Color(0.62, 0.68, 0.9),
		"parallax": [
			[Vector2(0.05, 0.08), "bg:aravalli_forest_parallax", 82.0, 85, -55, Color(0.45, 0.5, 0.75)],
			[Vector2(0.18, 0.15), "bg:forest_silhouette", 86.0, 30, -50, Color(0.2, 0.22, 0.35, 0.95)],
			[Vector2(0.45, 0.7), "forest", 60.0, 47, -40, Color(0.5, 0.55, 0.7)],
			[Vector2(1.25, 1.0), "foreground", 210.0, 53, 30],
		],
		"ambient": {"color": Color(1.0, 0.9, 0.5, 0.5), "amount": 18, "speed": 40.0}, "music": "night_theme",
		"decor": [{"type": "tree", "size": 1.0}, {"type": "boulder", "size": 1.0}, {"type": "torch"}, {"type": "prop", "name": "bush", "size": 0.6}],
	},
	"mewar": {
		"terrain": "ochre", "sky": [Color("7fa9cf"), Color("f0cf98"), Color("f5d9a6")], "grade": Color(1.04, 0.98, 0.88),
		"parallax": [
			[Vector2(0.05, 0.08), "bg:kumbhalgarh_parallax", 82.0, 85, -55],
			[Vector2(0.18, 0.15), "bg:fort_silhouette", 86.0, 28, -50, Color(0.8, 0.6, 0.4, 0.85)],
			[Vector2(0.32, 0.55), "troops", 70.0, 13, -44],
			[Vector2(0.45, 0.7), "rocks", 70.0, 17, -40],
			[Vector2(1.25, 1.0), "foreground", 210.0, 19, 30],
		],
		"ambient": {"color": Color(0.95, 0.8, 0.45, 0.35), "amount": 50, "speed": 240.0}, "music": "battle_theme",
		"decor": [{"type": "banner"}, {"type": "boulder", "size": 1.0}, {"type": "tree", "size": 0.8}, {"type": "prop", "name": "rock", "size": 0.6}, {"type": "flag"}],
	},
	"sahyadri": {
		"terrain": "basalt", "sky": [Color("6f93a8"), Color("b9cfc0"), Color("d8e2c8")], "grade": Color(0.93, 1.0, 0.95),
		"parallax": [
			[Vector2(0.05, 0.08), "ghats", 200.0, 61, -55, Color(0.75, 0.9, 0.85)],
			[Vector2(0.18, 0.15), "bg:forest_silhouette", 88.0, 30, -50, Color(0.3, 0.45, 0.38, 0.9)],
			[Vector2(0.3, 0.5), "mid_hills", 70.0, 43, -46, Color(0.55, 0.8, 0.6)],
			[Vector2(0.45, 0.7), "forest", 60.0, 47, -40, Color(0.75, 1.0, 0.8)],
			[Vector2(1.25, 1.0), "foreground", 210.0, 53, 30, Color(0.6, 1.0, 0.6)],
		],
		"ambient": {"color": Color(0.9, 1.0, 0.9, 0.25), "amount": 20, "speed": 60.0}, "music": "sahyadri_theme",
		"decor": [{"type": "tree", "size": 1.1}, {"type": "boulder", "size": 1.0}, {"type": "flag"}, {"type": "prop", "name": "bush", "size": 0.7}, {"type": "prop", "name": "rock", "size": 0.6}],
	},
	"sahyadri_rain": {
		"terrain": "basalt", "sky": [Color("2c3a4a"), Color("4a5a66"), Color("65756f")], "grade": Color(0.66, 0.76, 0.86),
		"parallax": [
			[Vector2(0.05, 0.08), "ghats", 200.0, 61, -55, Color(0.4, 0.5, 0.55)],
			[Vector2(0.3, 0.5), "mid_hills", 70.0, 43, -46, Color(0.35, 0.5, 0.45)],
			[Vector2(0.45, 0.7), "forest", 60.0, 47, -40, Color(0.45, 0.6, 0.55)],
			[Vector2(1.25, 1.0), "foreground", 210.0, 53, 30, Color(0.4, 0.6, 0.5)],
		],
		"rain": true, "music": "night_theme", "ambience": "rain",
		"decor": [{"type": "tree", "size": 1.1}, {"type": "boulder", "size": 1.1}, {"type": "prop", "name": "bush", "size": 0.7}, {"type": "prop", "name": "rock", "size": 0.7}],
	},
	"pune_night": {
		"terrain": "paving", "sky": [Color("10142c"), Color("2c2a4a"), Color("4a3a50")], "grade": Color(0.6, 0.64, 0.88),
		"parallax": [
			[Vector2(0.05, 0.08), "bg:fort_silhouette", 84.0, 60, -55, Color(0.25, 0.25, 0.42)],
			[Vector2(0.3, 0.5), "town", 70.0, 21, -46, Color(0.45, 0.45, 0.65)],
			[Vector2(1.25, 1.0), "foreground", 210.0, 53, 30],
		],
		"ambient": {"color": Color(1.0, 0.85, 0.5, 0.45), "amount": 14, "speed": 30.0}, "music": "night_theme",
		"decor": [{"type": "torch"}, {"type": "prop", "name": "pot", "size": 0.5}, {"type": "prop", "name": "crate", "size": 0.5}, {"type": "prop", "name": "barrel", "size": 0.5}, {"type": "torch"}],
	},
	"jhansi": {
		"terrain": "fort", "sky": [Color("8fb4d6"), Color("efd3a0"), Color("f6dfb2")], "grade": Color(1.02, 0.98, 0.92),
		"parallax": [
			[Vector2(0.05, 0.08), "bg:kumbhalgarh_parallax", 82.0, 85, -55, Color(0.95, 0.9, 0.9)],
			[Vector2(0.2, 0.3), "fortline", 120.0, 71, -48, Color(0.85, 0.75, 0.7)],
			[Vector2(0.4, 0.6), "town", 70.0, 23, -42],
			[Vector2(1.25, 1.0), "foreground", 210.0, 19, 30],
		],
		"ambient": {"color": Color(0.95, 0.85, 0.6, 0.3), "amount": 24, "speed": 120.0}, "music": "jhansi_theme",
		"decor": [{"type": "torch"}, {"type": "rack"}, {"type": "prop", "name": "barrel", "size": 0.5}, {"type": "prop", "name": "crate", "size": 0.5}, {"type": "flag"}],
	},
	"jhansi_siege": {
		"terrain": "fort", "sky": [Color("5a5560"), Color("c98a5a"), Color("e6a868")], "grade": Color(1.0, 0.86, 0.76),
		"parallax": [
			[Vector2(0.05, 0.08), "bg:kumbhalgarh_parallax", 82.0, 85, -55, Color(0.8, 0.62, 0.55)],
			[Vector2(0.2, 0.3), "fortline", 120.0, 71, -48, Color(0.6, 0.45, 0.42)],
			[Vector2(0.32, 0.55), "troops", 70.0, 13, -44],
			[Vector2(1.25, 1.0), "foreground", 210.0, 19, 30],
		],
		"ambient": {"color": Color(0.5, 0.45, 0.42, 0.45), "amount": 70, "speed": 200.0}, "music": "battle_theme",
		"decor": [{"type": "torch"}, {"type": "prop", "name": "barrel", "size": 0.5}, {"type": "prop", "name": "crate", "size": 0.5}, {"type": "boulder", "size": 0.8}],
	},
	"bundelkhand_night": {
		"terrain": "ground", "sky": [Color("121830"), Color("34304e"), Color("584858")], "grade": Color(0.62, 0.68, 0.92),
		"parallax": [
			[Vector2(0.05, 0.08), "far_hills", 120.0, 31, -55, Color(0.35, 0.38, 0.6)],
			[Vector2(0.2, 0.3), "fortline", 120.0, 71, -48, Color(0.3, 0.3, 0.48)],
			[Vector2(0.45, 0.7), "rocks", 70.0, 17, -40, Color(0.5, 0.5, 0.7)],
			[Vector2(1.25, 1.0), "foreground", 210.0, 19, 30],
		],
		"ambient": {"color": Color(0.9, 0.9, 1.0, 0.3), "amount": 20, "speed": 160.0}, "music": "ride_theme",
		"decor": [{"type": "tree", "size": 0.9}, {"type": "boulder", "size": 1.0}, {"type": "prop", "name": "bush", "size": 0.6}],
	},
	"gwalior": {
		"terrain": "ochre", "sky": [Color("c8a070"), Color("eab868"), Color("f4d090")], "grade": Color(1.06, 0.95, 0.82),
		"parallax": [
			[Vector2(0.05, 0.08), "far_hills", 120.0, 33, -55, Color(1.0, 0.85, 0.7)],
			[Vector2(0.2, 0.3), "fortline", 150.0, 77, -48, Color(0.95, 0.75, 0.6)],
			[Vector2(0.32, 0.55), "troops", 70.0, 13, -44],
			[Vector2(1.25, 1.0), "foreground", 210.0, 19, 30],
		],
		"ambient": {"color": Color(0.95, 0.8, 0.45, 0.4), "amount": 70, "speed": 280.0}, "music": "battle_theme",
		"decor": [{"type": "boulder", "size": 1.0}, {"type": "tree", "size": 0.7}, {"type": "prop", "name": "rock", "size": 0.6}, {"type": "flag"}],
	},
	"assam": {
		"terrain": "grass", "sky": [Color("7fb0c0"), Color("c8e0c8"), Color("e4eed0")], "grade": Color(0.94, 1.02, 0.96),
		"parallax": [
			[Vector2(0.05, 0.08), "far_hills", 150.0, 35, -55, Color(0.55, 0.8, 0.8)],
			[Vector2(0.15, 0.2), "river", 40.0, 81, -50],
			[Vector2(0.3, 0.5), "mid_hills", 60.0, 45, -46, Color(0.5, 0.85, 0.6)],
			[Vector2(0.45, 0.7), "forest", 60.0, 49, -40, Color(0.7, 1.05, 0.75)],
			[Vector2(1.25, 1.0), "foreground", 210.0, 53, 30, Color(0.5, 1.0, 0.5)],
		],
		"ambient": {"color": Color(1.0, 1.0, 1.0, 0.2), "amount": 20, "speed": 40.0}, "music": "assam_theme", "water": true,
		"decor": [{"type": "tree", "size": 1.2}, {"type": "prop", "name": "bush", "size": 0.8}, {"type": "prop", "name": "pot", "size": 0.5}, {"type": "torch"}],
	},
	"assam_night": {
		"terrain": "grass", "sky": [Color("0e1a2c"), Color("23384a"), Color("3a5058")], "grade": Color(0.58, 0.72, 0.86),
		"parallax": [
			[Vector2(0.05, 0.08), "far_hills", 150.0, 35, -55, Color(0.25, 0.4, 0.5)],
			[Vector2(0.15, 0.2), "river", 40.0, 81, -50, Color(0.5, 0.6, 0.8)],
			[Vector2(0.45, 0.7), "forest", 60.0, 49, -40, Color(0.4, 0.6, 0.6)],
			[Vector2(1.25, 1.0), "foreground", 210.0, 53, 30, Color(0.4, 0.7, 0.5)],
		],
		"ambient": {"color": Color(0.8, 1.0, 0.6, 0.6), "amount": 16, "speed": 25.0}, "music": "night_theme", "water": true,
		"decor": [{"type": "tree", "size": 1.2}, {"type": "torch"}, {"type": "prop", "name": "bush", "size": 0.8}, {"type": "prop", "name": "crate", "size": 0.5}],
	},
	"brahmaputra": {
		"terrain": "deck", "sky": [Color("5f8aa0"), Color("d8b888"), Color("f0d0a0")], "grade": Color(1.0, 0.96, 0.9),
		"parallax": [
			[Vector2(0.05, 0.08), "far_hills", 150.0, 35, -55, Color(0.6, 0.75, 0.8)],
			[Vector2(0.12, 0.2), "river", 60.0, 83, -50],
			[Vector2(0.3, 0.5), "fleet", 80.0, 87, -44],
		],
		"ambient": {"color": Color(1.0, 1.0, 1.0, 0.25), "amount": 30, "speed": 90.0}, "music": "battle_theme", "water": true,
		"decor": [{"type": "prop", "name": "crate", "size": 0.5}, {"type": "prop", "name": "barrel", "size": 0.5}, {"type": "torch"}],
	},
}

# ------------------------------------------------------------------ heroes

const HEROES := {
	"pratap": {
		"name": "Maharana Pratap", "epithet": "The Lion of Mewar", "region": "Mewar, Rajasthan", "years": "1540 - 1597",
		"pitch": "He chose the hills over a throne under another's flag - and won his kingdom back.",
		"ability": "Dhal Mastery", "ability_text": "Blocking costs far less stamina, and a perfect parry restores it.",
		"horse": "Chetak", "faction": "",
		"look": {"sprite": true},
		"stats": {"block_cost": 0.55, "parry_refund": 30.0},
		"levels": ["gogunda", "haldighati", "aravalli", "pratap_4", "pratap_5"],
	},
	"shivaji": {
		"name": "Chhatrapati Shivaji Maharaj", "epithet": "Founder of Swarajya", "region": "The Sahyadri, Maharashtra", "years": "1630 - 1680",
		"pitch": "A teenager took one hill fort. Twenty-eight years later he was crowned at Raigad.",
		"ability": "Ganimi Kava", "ability_text": "Dodging is cheap and fast. The first strike after a dodge hits twice as hard.",
		"horse": "", "faction": "bijapur",
		"look": {"headgear": "jiretop", "beard": true, "turban": Color("e8892b"), "turban_band": Color("c9a14a"), "jama": Color("f3ecd8"), "jama_trim": Color("c9a14a"), "sash": Color("b3392b"), "pants": Color("f3ecd8"), "shield": Color("2a1c14")},
		"stats": {"speed": 1.08, "dodge_cost": 0.6, "dodge_crit": 2.0},
		"levels": ["shivaji_1", "shivaji_2", "shivaji_3", "shivaji_4", "shivaji_5"],
	},
	"lakshmibai": {
		"name": "Rani Lakshmibai", "epithet": "The Queen of Jhansi", "region": "Jhansi, Bundelkhand", "years": "c. 1828 - 1858",
		"pitch": "They annexed her kingdom on paper. She answered from the ramparts, sword in hand.",
		"ability": "Twin Blades", "ability_text": "Two swords, no shield: much faster combos and a wider parry window, but blocking drains more stamina.",
		"horse": "Badal", "faction": "company",
		"look": {"headgear": "pagdi_f", "female": true, "dual": true, "armour": false, "turban": Color("b3261e"), "turban_band": Color("c9a14a"), "jama": Color("f1e9d6"), "jama_trim": Color("b3261e"), "sash": Color("c9a14a"), "pants": Color("f1e9d6")},
		"stats": {"attack_speed": 1.3, "light_cost": 0.7, "block_cost": 1.4, "parry_window": 1.4},
		"levels": ["lakshmibai_1", "lakshmibai_2", "lakshmibai_3", "lakshmibai_4", "lakshmibai_5"],
	},
	"lachit": {
		"name": "Lachit Borphukan", "epithet": "Guardian of the Brahmaputra", "region": "The Ahom kingdom, Assam", "years": "1622 - 1672",
		"pitch": "Too ill to stand, he had himself carried to a boat - and turned the river against an empire.",
		"ability": "Hengdang", "ability_text": "The Ahom long sword: tougher, with a heavy blow that winds up quickly and hits much harder.",
		"horse": "", "faction": "mughal_east",
		"look": {"headgear": "ahom", "armour": false, "blade_length": 52.0, "turban": Color("f2ecdc"), "turban_band": Color("b3261e"), "jama": Color("f2ecdc"), "jama_trim": Color("b3261e"), "sash": Color("b3261e"), "pants": Color("e8dfc8"), "shield": Color("5a3a22"), "hilt": Color("e0b84a")},
		"stats": {"health": 125.0, "speed": 0.95, "heavy_damage": 1.5, "heavy_windup": 0.75},
		"levels": ["lachit_1", "lachit_2", "lachit_3", "lachit_4", "lachit_5"],
	},
}

# ------------------------------------------------------------------ levels

const LEVELS := {
	# ============================== MAHARANA PRATAP
	"gogunda": {"kind": "scene", "scene": "res://scenes/environments/gogunda/gogunda.tscn",
		"title": "The Oath of Mewar", "place": "Gogunda, 1572"},
	"haldighati": {"kind": "scene", "scene": "res://scenes/environments/haldighati/haldighati.tscn",
		"title": "The Yellow Pass", "place": "Haldighati, 1576"},
	"aravalli": {"kind": "scene", "scene": "res://scenes/environments/aravalli/aravalli.tscn",
		"title": "Chetak - The Final Ride", "place": "Aravalli hills, 1576"},
	"pratap_4": {
		"title": "Shadows of the Aravalli", "place": "The Aravalli forests, 1576 - 1582", "caption": "THE ARAVALLI FORESTS  -  AFTER HALDIGHATI",
		"theme": "aravalli_night", "faction": "", "tier": 4, "objective": "Raid the imperial outpost under cover of night.",
		"intro": [
			{"tag": H, "title": "The years in the hills", "body": "After Haldighati, Pratap did not surrender. From the forests and ravines of the Aravallis he harried imperial outposts and supply lines year after year, helped by the Bhils who knew every path."},
			{"tag": T, "title": "Bhamashah", "body": "Tradition holds that when Mewar's treasury was empty, the minister Bhamashah laid his own fortune at Pratap's feet - enough to raise and feed an army again."},
			{"tag": F, "title": "Level 4  -  Shadows of the Aravalli", "body": "This night raid, the outpost and its garrison are invented for gameplay. They stand in for many small actions of which few details survive."},
		],
		"outro": [{"tag": H, "title": "The tide turns", "body": "Raid by raid, the imperial posts in Mewar grew harder to hold. By 1582 Pratap was ready to strike in the open."}],
		"segments": [
			["hint", "Night raid. Spear traps guard the forest path - watch their rhythm and cross as they drop."],
			["run", 500], ["spikes", 2], ["run", 300], ["foes", [["sword", 250], ["archer", 620]], 800], ["gap", 150], ["run", 260], ["leaf", -150],
			["pillars", 3, 140], ["cp"], ["supply"],
			["foes", [["spear", 260], ["sword", 480], ["armoured", 760]], 1000], ["stairs", 3, -80, 210], ["stones", 760],
			["tower", 230], ["cp"], ["leaf", -150], ["crumble", 3], ["run", 260], ["spikes", 3], ["foes", [["archer", 300], ["spear", 520]], 760],
			["cp"], ["supply"], ["obj", "Break the garrison at the outpost."],
			["arena", [[["sword", 0.55], ["spear", 0.8]], [["archer", 0.9], ["armoured", 0.6], ["sword", 0.75]], [["armoured", 0.6], ["armoured", 0.85], ["archer", 0.95]]], 1100],
			["run", 500],
		],
	},
	"pratap_5": {
		"title": "The Return of Mewar", "place": "Dewair, 1582", "caption": "DEWAIR  -  1582",
		"theme": "mewar", "faction": "", "tier": 5, "objective": "Storm the imperial post at Dewair.",
		"intro": [
			{"tag": H, "title": "1582  -  Dewair", "body": "Six years after Haldighati, Pratap's forces attacked the imperial post at Dewair in the hills of Mewar and overran it. After Dewair the remaining imperial posts in Mewar were abandoned one after another."},
			{"tag": F, "title": "Level 5  -  The Return of Mewar", "body": "The assault you play, the post commander and his guards are fictional composites. Mewar's allies fight beside you."},
		],
		"outro": [
			{"tag": H, "title": "Mewar restored", "body": "In the years that followed, Pratap recovered most of Mewar - though not Chittor. He ruled from Chavand and died in 1597, never having submitted."},
			{"tag": F, "title": "A legend complete", "body": "You have finished Maharana Pratap's story. Other legends are waiting."},
		],
		"segments": [
			["hint", "Dewair. Your allies charge with you - keep them standing and they will keep you standing."],
			["allies", [["sword", 120], ["sword", 220]]],
			["run", 500], ["foes", [["sword", 300], ["spear", 560], ["archer", 900]], 1100], ["volley", 900, "arrows"], ["gap", 160], ["run", 280],
			["cp"], ["supply"], ["spikes", 3], ["foes", [["armoured", 300], ["sword", 520], ["archer", 820]], 1000], ["stairs", 3, -85, 200], ["leaf", -150],
			["crumble", 3], ["run", 250], ["stones", 800], ["cp"], ["allies", [["sword", 60], ["archer", 140]]],
			["arena", [[["spear", 0.6], ["sword", 0.8], ["archer", 0.95]], [["armoured", 0.6], ["armoured", 0.8]], [["sword", 0.55], ["spear", 0.7], ["armoured", 0.85], ["archer", 0.95]]], 1200],
			["tower", 240], ["leaf", -150], ["pillars", 3, 150], ["spikes", 3], ["cp"], ["supply"],
			["obj", "Defeat the commander of the post."],
			["boss", {"name": "The Commander of Dewair", "hp": 380.0, "adds": [["sword", 0.9]]}, 1100],
			["run", 500],
		],
	},

	# ============================== CHHATRAPATI SHIVAJI MAHARAJ
	"shivaji_1": {
		"title": "The First Fort", "place": "Torna, 1646", "caption": "TORNA FORT  -  1646",
		"theme": "sahyadri", "tier": 1, "objective": "Climb to the gate of Torna.",
		"intro": [
			{"tag": H, "title": "1646  -  The Sahyadri", "body": "Shivaji Bhonsle was about sixteen when he took control of Torna, a hill fort of the Bijapur sultanate in the Sahyadri mountains. It was the first fort of what he would call Swarajya - self-rule."},
			{"tag": F, "title": "Level 1  -  The First Fort", "body": "Accounts say Torna was taken with little fighting. The climb and the guards you meet here are invented, to teach running, jumping and swordplay."},
		],
		"outro": [{"tag": H, "title": "Swarajya begins", "body": "Treasure found at Torna paid for a new fort nearby: Rajgad, his capital for the next quarter of a century. More forts followed."}],
		"segments": [
			["hint", "Run with A/D, jump with SPACE. Strike with J, block with K, dodge with L. Dodge, then strike: that is Ganimi Kava."],
			["run", 500], ["gap", 110], ["run", 400], ["foes", [["sword", 300]], 600], ["stairs", 3, -70, 220], ["leaf", -140], ["cp"],
			["tower", 220], ["run", 300], ["foes", [["sword", 250], ["spear", 520]], 760], ["pillars", 2, 120], ["supply"], ["run", 300], ["cp"],
			["hint", "Loose rock falls from the cliffs. Watch for the shadows."],
			["stones", 700], ["stairs", 3, -80, 200], ["crumble", 2], ["run", 300], ["leaf", -150], ["tower", 240], ["cp"],
			["obj", "Clear the guards at the gate."],
			["arena", [[["sword", 0.6], ["sword", 0.85]], [["spear", 0.7], ["archer", 0.92]]], 900],
			["run", 400],
		],
	},
	"shivaji_2": {
		"title": "The Tiger's Claw", "place": "Pratapgad, 1659", "caption": "BELOW PRATAPGAD  -  10 NOVEMBER 1659",
		"theme": "sahyadri", "tier": 2, "objective": "The signal has sounded. Sweep the forest of Javali.",
		"intro": [
			{"tag": H, "title": "10 November 1659", "body": "Bijapur sent its general Afzal Khan with a large army to crush Shivaji. The two met for a parley on the slope below Pratapgad fort. The meeting ended in a deadly struggle; Afzal Khan was killed. The accounts disagree on who struck first."},
			{"tag": H, "title": "The forest of Javali", "body": "At the signal from the fort, Maratha troops hidden in the dense forest fell upon the leaderless Bijapur army and routed it."},
			{"tag": F, "title": "Level 2  -  The Tiger's Claw", "body": "You play the forest battle that followed the signal. Its soldiers and its captain are fictional composites. The parley itself is not shown."},
		],
		"outro": [{"tag": H, "title": "A name known across the Deccan", "body": "The victory at Pratapgad brought Shivaji horses, guns and treasure - and the full attention of far greater powers."}],
		"segments": [
			["hint", "Mavala soldiers fight beside you. Spear traps mark the old hunting paths."],
			["allies", [["sword", 140]]],
			["run", 450], ["foes", [["sword", 300], ["sword", 560]], 800], ["gap", 130], ["run", 260], ["spikes", 2], ["leaf", -140], ["cp"],
			["foes", [["spear", 280], ["archer", 620]], 820], ["pillars", 3, 130], ["supply"], ["stairs", 2, -80, 220], ["stones", 700], ["cp"],
			["allies", [["sword", 60], ["archer", 150]]],
			["arena", [[["sword", 0.6], ["spear", 0.85]], [["archer", 0.92], ["sword", 0.6], ["sword", 0.75]]], 1000],
			["crumble", 3], ["run", 260], ["leaf", -150], ["foes", [["armoured", 320], ["archer", 700]], 900], ["tower", 220], ["cp"], ["supply"],
			["obj", "Defeat the captain rallying the Bijapur line."],
			["boss", {"name": "Captain of the Vanguard", "hp": 240.0, "adds": []}, 1000],
			["run", 400],
		],
	},
	"shivaji_3": {
		"title": "The Night of Rain", "place": "Panhala to Vishalgad, 1660", "caption": "PANHALA  -  A NIGHT IN JULY 1660",
		"theme": "sahyadri_rain", "tier": 3, "objective": "Slip through the siege lines and run for Vishalgad.",
		"intro": [
			{"tag": H, "title": "July 1660  -  Panhala", "body": "Besieged for months in Panhala fort by the Bijapur general Siddi Jauhar, Shivaji slipped out on a night of heavy monsoon rain and made for Vishalgad, some sixty kilometres away."},
			{"tag": H, "title": "Ghod Khind", "body": "When the pursuit closed in, Baji Prabhu Deshpande and a few hundred men held a narrow pass, Ghod Khind, for hours - until cannon fire from Vishalgad told them Shivaji was safe. Baji Prabhu died of his wounds. The pass is remembered as Pavan Khind, the sacred pass."},
			{"tag": F, "title": "Level 3  -  The Night of Rain", "body": "The route, its traps and the stand you make in the pass are invented gameplay inspired by that night."},
		],
		"outro": [{"tag": H, "title": "Vishalgad", "body": "Shivaji reached Vishalgad. The rear guard at the pass paid for his escape with their lives."}],
		"segments": [
			["hint", "Rain and darkness hide you - but the ground is treacherous. Keep moving."],
			["run", 450], ["gap", 140], ["run", 240], ["gap", 150], ["run", 260], ["foes", [["sword", 260], ["spear", 520]], 760], ["crumble", 3], ["run", 220], ["leaf", -150], ["cp"],
			["spikes", 3], ["stairs", 3, -85, 190], ["foes", [["archer", 300], ["sword", 520], ["sword", 700]], 900], ["pillars", 4, 140], ["supply"], ["cp"],
			["volley", 900, "arrows"], ["gap", 150], ["run", 240], ["stones", 760], ["tower", 240], ["leaf", -150], ["cp"],
			["foes", [["armoured", 300], ["spear", 560], ["archer", 860]], 1050], ["crumble", 4], ["run", 240], ["supply"], ["cp"],
			["obj", "Hold the pass until the cannon sounds."], ["allies", [["sword", 60], ["sword", 140]]],
			["arena", [[["sword", 0.6], ["sword", 0.75], ["spear", 0.9]], [["armoured", 0.6], ["archer", 0.92], ["spear", 0.78]], [["sword", 0.55], ["armoured", 0.7], ["armoured", 0.85], ["archer", 0.95]]], 1100],
			["run", 500],
		],
	},
	"shivaji_4": {
		"title": "Midnight at Lal Mahal", "place": "Pune, 1663", "caption": "PUNE  -  APRIL 1663",
		"theme": "pune_night", "faction": "mughal", "tier": 4, "objective": "Cross the sleeping city to Lal Mahal.",
		"intro": [
			{"tag": H, "title": "April 1663  -  Pune", "body": "The Mughal governor Shaista Khan had occupied Pune with a vast army and made his residence in Lal Mahal - Shivaji's own childhood home. One night Shivaji entered the guarded city with a small band and raided the palace."},
			{"tag": T, "title": "The wedding procession", "body": "Tradition says the raiders slipped past the guards mingled with a wedding party. Shaista Khan escaped through a window, losing fingers to a sword stroke; he was soon recalled from the Deccan."},
			{"tag": F, "title": "Level 4  -  Midnight at Lal Mahal", "body": "The rooftops, courtyards and palace guard you face are invented gameplay. No named historical figure appears as an opponent."},
		],
		"outro": [{"tag": H, "title": "An empire embarrassed", "body": "A handful of men had struck at the heart of a camp of tens of thousands and vanished into the night."}],
		"segments": [
			["hint", "Rooftops and courtyards. Crumbling tiles will not hold you for long."],
			["run", 400], ["tower", 220], ["crumble", 3], ["run", 200], ["gap", 150], ["run", 220], ["foes", [["sword", 240], ["archer", 520]], 700], ["leaf", -150], ["cp"],
			["spikes", 3], ["pillars", 4, 150], ["foes", [["armoured", 280], ["spear", 520]], 760], ["stairs", 3, -85, 180], ["supply"], ["cp"],
			["crumble", 4], ["run", 200], ["stones", 700], ["foes", [["archer", 260], ["archer", 520], ["sword", 700]], 900], ["tower", 240], ["leaf", -150], ["cp"],
			["spikes", 4], ["gap", 160], ["run", 220], ["pillars", 3, 155], ["foes", [["armoured", 300], ["armoured", 560], ["archer", 820]], 1000], ["supply"], ["cp"],
			["obj", "Break through the palace guard."],
			["arena", [[["sword", 0.6], ["spear", 0.8], ["archer", 0.95]], [["armoured", 0.6], ["armoured", 0.8], ["archer", 0.95]]], 1000],
			["boss", {"name": "Captain of the Palace Guard", "hp": 330.0, "adds": [["archer", 0.95]]}, 1000],
			["run", 400],
		],
	},
	"shivaji_5": {
		"title": "Road to Raigad", "place": "The Sahyadri forts, 1670 - 1674", "caption": "THE SAHYADRI  -  1670",
		"theme": "sahyadri", "faction": "mughal", "tier": 5, "objective": "Retake the fort, wall by wall.",
		"intro": [
			{"tag": H, "title": "1665 - 1670", "body": "By the Treaty of Purandar in 1665 Shivaji gave up twenty-three forts to the Mughal empire. He was detained at Agra in 1666, escaped, and from 1670 took his forts back one by one - Sinhagad first, stormed at night by Tanaji Malusare, who fell in the assault."},
			{"tag": F, "title": "Level 5  -  Road to Raigad", "body": "The fort you storm is a composite of that campaign. Its defenders and its commander are fictional."},
		],
		"outro": [
			{"tag": H, "title": "6 June 1674  -  Raigad", "body": "At Raigad, Shivaji was crowned Chhatrapati - sovereign of an independent Maratha kingdom with its own forts, navy and administration. He died in 1680. The state he founded outlived the empire that had tried to stop it."},
			{"tag": F, "title": "A legend complete", "body": "You have finished Shivaji Maharaj's story. Other legends are waiting."},
		],
		"segments": [
			["hint", "The last climb. Everything you have learned, all at once."],
			["allies", [["sword", 120], ["archer", 200]]],
			["run", 400], ["foes", [["sword", 260], ["spear", 500], ["archer", 820]], 1000], ["spikes", 3], ["gap", 160], ["run", 220], ["tower", 240], ["leaf", -150], ["cp"],
			["volley", 900, "arrows"], ["crumble", 4], ["run", 220], ["foes", [["armoured", 280], ["archer", 560], ["spear", 760]], 950], ["stairs", 4, -85, 180], ["supply"], ["cp"],
			["stones", 800], ["pillars", 4, 155], ["spikes", 4], ["tower", 240], ["foes", [["armoured", 260], ["armoured", 500], ["archer", 800]], 980], ["leaf", -150], ["cp"],
			["allies", [["sword", 60], ["sword", 140]]],
			["arena", [[["sword", 0.55], ["spear", 0.75], ["archer", 0.95]], [["armoured", 0.6], ["spear", 0.8], ["archer", 0.95]], [["armoured", 0.55], ["armoured", 0.75], ["sword", 0.88], ["archer", 0.97]]], 1200],
			["crumble", 3], ["run", 220], ["spikes", 3], ["tower", 220], ["cp"], ["supply"],
			["obj", "Defeat the Killedar - the keeper of the fort."],
			["boss", {"name": "The Killedar", "hp": 420.0, "adds": [["archer", 0.95], ["sword", 0.85]]}, 1150],
			["run", 500],
		],
	},

	# ============================== RANI LAKSHMIBAI
	"lakshmibai_1": {
		"title": "Manikarnika", "place": "Jhansi fort, 1853 - 1857", "caption": "JHANSI FORT  -  1857",
		"theme": "jhansi", "faction": "orchha", "tier": 1, "objective": "Complete the morning drill on the ramparts.",
		"intro": [
			{"tag": H, "title": "Manikarnika", "body": "Born Manikarnika in Varanasi, she married Raja Gangadhar Rao of Jhansi in 1842 and became Rani Lakshmibai. When the Raja died in 1853, the East India Company refused to recognise their adopted son and annexed Jhansi under the Doctrine of Lapse."},
			{"tag": T, "title": "\"I will not give up my Jhansi\"", "body": "Tradition remembers her as an expert rider and swordswoman from girlhood, who trained the women of her household to fight. The famous words refusing to surrender Jhansi are attributed to her."},
			{"tag": F, "title": "Level 1  -  Manikarnika", "body": "The drill course and the sparring guards are invented, to teach the Rani's twin-sword style."},
		],
		"outro": [{"tag": H, "title": "June 1857", "body": "When the Company's garrison at Jhansi mutinied in June 1857, the Rani took charge of the kingdom's administration and defence."}],
		"segments": [
			["hint", "Twin blades: strike fast with J, J, J. You have no shield - block with K only when you must, or dodge with L."],
			["run", 500], ["gap", 110], ["run", 380], ["foes", [["sword", 280]], 600], ["stairs", 2, -70, 240], ["leaf", -140], ["cp"],
			["crumble", 2], ["run", 300], ["foes", [["sword", 240], ["sword", 520]], 760], ["tower", 220], ["supply"], ["cp"],
			["hint", "The drill-master's spear traps rise and fall in rhythm. Cross as they drop."],
			["spikes", 2], ["pillars", 2, 120], ["run", 260], ["leaf", -150], ["foes", [["spear", 300]], 600], ["cp"],
			["obj", "Spar with the fort guard."],
			["arena", [[["sword", 0.6], ["sword", 0.85]], [["spear", 0.7], ["sword", 0.9]]], 900],
			["run", 400],
		],
	},
	"lakshmibai_2": {
		"title": "The Rani Takes Command", "place": "Jhansi, autumn 1857", "caption": "JHANSI  -  AUTUMN 1857",
		"theme": "jhansi", "faction": "orchha", "tier": 2, "objective": "Throw the invaders back from the walls.",
		"intro": [
			{"tag": H, "title": "Autumn 1857", "body": "With the Company's authority gone from Bundelkhand, the neighbouring states of Orchha and Datia sent their armies to seize Jhansi. The Rani raised troops, cast cannon, and defeated the invasion."},
			{"tag": F, "title": "Level 2  -  The Rani Takes Command", "body": "The fighting on the walls and the enemy captain are fictional composites of that defence."},
		],
		"outro": [{"tag": H, "title": "A kingdom held", "body": "For the winter of 1857 Jhansi was at peace under the Rani's rule. A far larger army was already marching toward it."}],
		"segments": [
			["hint", "Soldiers of Jhansi fight beside you. Keep them standing."],
			["allies", [["sword", 140]]],
			["run", 450], ["foes", [["sword", 280], ["spear", 560]], 820], ["gap", 130], ["run", 260], ["spikes", 2], ["leaf", -140], ["cp"],
			["tower", 220], ["foes", [["archer", 300], ["sword", 560]], 800], ["crumble", 3], ["run", 240], ["supply"], ["cp"],
			["stones", 700], ["pillars", 3, 130], ["foes", [["armoured", 320]], 600], ["stairs", 3, -80, 200], ["leaf", -150], ["cp"],
			["allies", [["sword", 60], ["archer", 150]]],
			["arena", [[["sword", 0.6], ["spear", 0.85]], [["archer", 0.92], ["sword", 0.6], ["sword", 0.75]], [["armoured", 0.65], ["spear", 0.85]]], 1000],
			["supply"], ["obj", "Defeat the invaders' captain."],
			["boss", {"name": "Captain of the Invaders", "hp": 250.0, "adds": []}, 1000],
			["run", 400],
		],
	},
	"lakshmibai_3": {
		"title": "Jhansi Will Not Fall", "place": "The siege of Jhansi, March 1858", "caption": "THE SIEGE OF JHANSI  -  MARCH 1858",
		"theme": "jhansi_siege", "faction": "company", "tier": 3, "objective": "Hold the ramparts under the bombardment.",
		"intro": [
			{"tag": H, "title": "March 1858", "body": "A Company army under Sir Hugh Rose laid siege to Jhansi. For days its guns battered the walls while the defenders - men and women - repaired the breaches by night and answered with their own cannon."},
			{"tag": H, "title": "The Betwa", "body": "A relief army under Tatya Tope was beaten off at the Betwa river on 1 April. Two days later the city was stormed."},
			{"tag": F, "title": "Level 3  -  Jhansi Will Not Fall", "body": "The rampart you defend, the falling shells and the storming party are invented gameplay. Musketeers fire in a straight line: raise your blades or get behind cover."},
		],
		"outro": [{"tag": H, "title": "3 April 1858", "body": "The walls were breached and there was fighting from street to street. The Rani resolved to break out and carry on the war elsewhere."}],
		"segments": [
			["hint", "Cannon fire! Shadows show where each shell will land. Musketeers aim for a moment before they fire - dodge through the shot."],
			["run", 450], ["volley", 900, "shells"], ["foes", [["musket", 520], ["sword", 300]], 760], ["gap", 140], ["run", 240], ["crumble", 3], ["run", 220], ["leaf", -150], ["cp"],
			["tower", 230], ["foes", [["sword", 260], ["sword", 460], ["musket", 760]], 900], ["spikes", 3], ["supply"], ["cp"],
			["volley", 1000, "shells"], ["pillars", 3, 140], ["stones", 700], ["foes", [["armoured", 300], ["musket", 620]], 820], ["stairs", 3, -85, 190], ["leaf", -150], ["cp"],
			["crumble", 4], ["run", 220], ["foes", [["spear", 260], ["musket", 540], ["musket", 760]], 900], ["supply"], ["cp"],
			["obj", "Throw back the storming party at the breach."], ["allies", [["sword", 60], ["sword", 140]]],
			["arena", [[["sword", 0.6], ["sword", 0.75], ["musket", 0.95]], [["armoured", 0.6], ["spear", 0.78], ["musket", 0.95]], [["armoured", 0.55], ["sword", 0.7], ["sword", 0.82], ["musket", 0.96]]], 1100],
			["run", 500],
		],
	},
	"lakshmibai_4": {
		"title": "The Leap", "place": "Jhansi to Kalpi, April 1858", "caption": "JHANSI  -  THE NIGHT OF 4 APRIL 1858",
		"theme": "bundelkhand_night", "faction": "company", "tier": 4, "objective": "Fight your way down to the horses.",
		"intro": [
			{"tag": H, "title": "4 April 1858", "body": "With the city lost, the Rani left the fort by night with a small escort and her adopted son Damodar Rao, broke through the cordon, and rode hard for Kalpi - about a hundred and fifty kilometres away."},
			{"tag": T, "title": "Badal", "body": "The best-loved telling has her leaping from the fort wall on her horse Badal, the boy tied to her back. Historians doubt the leap; no one doubts the ride."},
			{"tag": F, "title": "Level 4  -  The Leap", "body": "The descent, the pickets and the obstacles on the road are invented gameplay."},
		],
		"outro": [{"tag": H, "title": "Kalpi", "body": "She reached Kalpi and joined Tatya Tope and Rao Sahib. Defeated there in May, they did what no one expected: they marched on Gwalior."}],
		"segments": [
			["hint", "Down through the broken fort, then ride. Badal waits beyond the last picket."],
			["run", 400], ["crumble", 3], ["run", 220], ["foes", [["sword", 240], ["musket", 540]], 720], ["spikes", 3], ["gap", 150], ["run", 220], ["leaf", -150], ["cp"],
			["pillars", 4, 150], ["foes", [["armoured", 280], ["musket", 560]], 780], ["stones", 700], ["supply"], ["cp"],
			["crumble", 4], ["run", 220], ["spikes", 4], ["foes", [["sword", 240], ["spear", 440], ["musket", 720]], 880], ["leaf", -150], ["cp"],
			["arena", [[["sword", 0.6], ["spear", 0.8], ["musket", 0.95]], [["armoured", 0.6], ["armoured", 0.8], ["musket", 0.95]]], 1000],
			["supply"], ["obj", "Reach Badal and ride for Kalpi."],
			["ride", 11],
		],
	},
	"lakshmibai_5": {
		"title": "The Last Charge", "place": "Kotah-ki-Serai, Gwalior, June 1858", "caption": "KOTAH-KI-SERAI, GWALIOR  -  17 JUNE 1858",
		"theme": "gwalior", "faction": "company", "tier": 5, "objective": "Hold the eastern approach to Gwalior.",
		"intro": [
			{"tag": H, "title": "June 1858  -  Gwalior", "body": "On 1 June the Rani, Tatya Tope and Rao Sahib took the great fortress of Gwalior. Hugh Rose's army came after them. The Rani commanded the defence of the eastern approach, at Kotah-ki-Serai."},
			{"tag": F, "title": "Level 5  -  The Last Charge", "body": "The battle you fight and the cavalry officer who leads the attack are fictional composites. History decides how this day ends; you decide how it is fought."},
		],
		"outro": [
			{"tag": H, "title": "17 June 1858", "body": "Dressed as a cavalry soldier, Rani Lakshmibai was killed in the fighting at Kotah-ki-Serai. She was about thirty years old. Her opponent Hugh Rose called her the best and bravest of the rebel leaders."},
			{"tag": H, "title": "After", "body": "Jhansi was not hers again. But the ballad every Indian schoolchild learns still ends the same way: she fought like a man, she was the Rani of Jhansi."},
			{"tag": F, "title": "A legend complete", "body": "You have finished Rani Lakshmibai's story. Other legends are waiting."},
		],
		"segments": [
			["hint", "The last day. Give no ground."],
			["allies", [["sword", 120], ["sword", 210]]],
			["run", 400], ["volley", 900, "shells"], ["foes", [["sword", 260], ["musket", 520], ["musket", 760]], 950], ["gap", 160], ["run", 220], ["spikes", 3], ["leaf", -150], ["cp"],
			["foes", [["armoured", 280], ["spear", 500], ["musket", 800]], 1000], ["crumble", 4], ["run", 220], ["stairs", 3, -85, 180], ["supply"], ["cp"],
			["volley", 1000, "shells"], ["pillars", 4, 155], ["foes", [["armoured", 260], ["armoured", 480], ["musket", 760]], 950], ["spikes", 4], ["leaf", -150], ["cp"],
			["allies", [["sword", 60], ["sword", 140]]],
			["arena", [[["sword", 0.55], ["spear", 0.75], ["musket", 0.95]], [["armoured", 0.6], ["sword", 0.78], ["musket", 0.9], ["musket", 0.97]], [["armoured", 0.55], ["armoured", 0.72], ["spear", 0.85], ["musket", 0.97]]], 1200],
			["cp"], ["supply"], ["obj", "Meet the cavalry charge."],
			["boss", {"name": "Officer of the Hussars", "hp": 430.0, "adds": [["musket", 0.96], ["sword", 0.85]]}, 1150],
			["run", 500],
		],
	},

	# ============================== LACHIT BORPHUKAN
	"lachit_1": {
		"title": "The Hengdang", "place": "The Ahom kingdom, 1667", "caption": "THE AHOM KINGDOM  -  1667",
		"theme": "assam", "tier": 1, "objective": "Inspect the river stockades.",
		"intro": [
			{"tag": H, "title": "1663 - 1667", "body": "After a Mughal invasion reached the Ahom capital in 1662, the kingdom of Assam had to cede Guwahati and pay a heavy indemnity. King Chakradhwaj Singha resolved to win it back, and in 1667 chose Lachit as his Borphukan - commander of the army of the west."},
			{"tag": T, "title": "The gold-hilted sword", "body": "The king is said to have presented Lachit with the Hengdang, a gold-hilted sword of office, as the sign of his command."},
			{"tag": F, "title": "Level 1  -  The Hengdang", "body": "The stockade course and the sparring soldiers are invented, to teach the weight of the Hengdang. Hold J for a heavy blow."},
		],
		"outro": [{"tag": H, "title": "August 1667", "body": "The army and its river fleet set out down the Brahmaputra for Guwahati."}],
		"segments": [
			["hint", "The Hengdang is heavy. Tap J to strike; HOLD J and release for a crushing blow that breaks any guard."],
			["run", 500], ["gap", 110], ["run", 380], ["foes", [["sword", 280]], 600], ["movers", 1, "raft"], ["run", 260], ["leaf", -140], ["cp"],
			["hint", "Rafts drift back and forth. Step on when they are close."],
			["stairs", 2, -70, 240], ["foes", [["sword", 240], ["armoured", 540]], 800], ["pillars", 2, 120], ["supply"], ["cp"],
			["movers", 2, "raft"], ["run", 260], ["tower", 220], ["leaf", -150], ["foes", [["spear", 300]], 600], ["cp"],
			["obj", "Test the garrison's drill."],
			["arena", [[["sword", 0.6], ["sword", 0.85]], [["armoured", 0.7], ["spear", 0.9]]], 900],
			["run", 400],
		],
	},
	"lachit_2": {
		"title": "Night at Itakhuli", "place": "Guwahati, November 1667", "caption": "ITAKHULI FORT, GUWAHATI  -  NOVEMBER 1667",
		"theme": "assam_night", "tier": 2, "objective": "Scale Itakhuli before dawn.",
		"intro": [
			{"tag": H, "title": "November 1667", "body": "The Ahom army took the Mughal forts around Guwahati one after another. The strongest, Itakhuli, on its hill above the river, fell to a night assault. Guwahati was Ahom again."},
			{"tag": T, "title": "Water in the guns", "body": "Tradition says Ahom scouts crept into the fort before the assault and poured water down the barrels of its cannon."},
			{"tag": F, "title": "Level 2  -  Night at Itakhuli", "body": "The climb, the traps and the fort's captain are invented gameplay."},
		],
		"outro": [{"tag": H, "title": "The empire answers", "body": "The emperor Aurangzeb sent a great army and fleet under Raja Ram Singh of Amber to take Guwahati back."}],
		"segments": [
			["hint", "A night assault. Cross the moat on the rafts, then climb."],
			["allies", [["sword", 140]]],
			["run", 450], ["movers", 2, "raft"], ["run", 240], ["foes", [["sword", 280], ["spear", 540]], 800], ["spikes", 2], ["leaf", -140], ["cp"],
			["tower", 220], ["foes", [["archer", 300], ["sword", 540]], 800], ["crumble", 3], ["run", 240], ["supply"], ["cp"],
			["stairs", 3, -80, 200], ["stones", 700], ["pillars", 3, 130], ["foes", [["armoured", 320], ["archer", 640]], 860], ["tower", 220], ["leaf", -150], ["cp"],
			["allies", [["sword", 60], ["archer", 150]]],
			["arena", [[["sword", 0.6], ["spear", 0.85]], [["archer", 0.92], ["sword", 0.6], ["armoured", 0.78]]], 1000],
			["supply"], ["obj", "Defeat the captain of the fort."],
			["boss", {"name": "Captain of Itakhuli", "hp": 260.0, "adds": []}, 1000],
			["run", 400],
		],
	},
	"lachit_3": {
		"title": "The Field of Alaboi", "place": "Alaboi, August 1669", "caption": "ALABOI  -  5 AUGUST 1669",
		"theme": "assam", "tier": 3, "objective": "Survive the open field. Bring your soldiers back to the river.",
		"intro": [
			{"tag": H, "title": "1669", "body": "Lachit knew his army could not match Mughal cavalry on open ground, and kept to the hills and the river. But the king, impatient, ordered an attack. At Alaboi the Ahom force was caught in the open and about ten thousand soldiers were lost."},
			{"tag": F, "title": "Level 3  -  The Field of Alaboi", "body": "This is a defeat. The fighting withdrawal you play is invented; your goal is to survive it and reach the boats."},
		],
		"outro": [{"tag": H, "title": "The lesson", "body": "Lachit grieved for the dead and went back to the strategy he trusted: earthworks, narrow water, and patience."}],
		"segments": [
			["hint", "The field is lost. Fall back to the river - fight only to keep the way open."],
			["allies", [["sword", 120], ["sword", 200]]],
			["run", 450], ["volley", 1000, "arrows"], ["foes", [["sword", 260], ["sword", 460], ["archer", 780]], 950], ["gap", 140], ["run", 240], ["spikes", 3], ["leaf", -150], ["cp"],
			["foes", [["armoured", 280], ["spear", 520], ["archer", 820]], 1000], ["pillars", 3, 140], ["supply"], ["cp"],
			["volley", 1000, "arrows"], ["crumble", 3], ["run", 220], ["stones", 700], ["foes", [["armoured", 280], ["armoured", 520]], 800], ["leaf", -150], ["cp"],
			["allies", [["sword", 60], ["archer", 140]]],
			["arena", [[["sword", 0.6], ["sword", 0.75], ["spear", 0.9]], [["armoured", 0.6], ["archer", 0.92], ["spear", 0.78]], [["sword", 0.55], ["armoured", 0.7], ["armoured", 0.85], ["archer", 0.95]]], 1100],
			["supply"], ["cp"], ["obj", "Cross to the boats."],
			["movers", 3, "raft"], ["run", 300], ["volley", 700, "arrows"], ["movers", 2, "raft"],
			["run", 500],
		],
	},
	"lachit_4": {
		"title": "Not Greater Than My Country", "place": "The ramparts of Guwahati, 1670", "caption": "THE RAMPARTS OF GUWAHATI  -  1670",
		"theme": "assam_night", "tier": 4, "objective": "Walk the unfinished rampart and drive off the raiders.",
		"intro": [
			{"tag": T, "title": "One night", "body": "The best-known story of Lachit: an earthen rampart had to be finished in a single night, and he put his own maternal uncle in charge. Finding the work stalled, Lachit had him put to death, saying: \"My uncle is not greater than my country.\" By morning the wall stood."},
			{"tag": H, "title": "The defences of Guwahati", "body": "Whatever the truth of the story, the Ahom earthworks on both banks were real, and they forced the Mughal army to seek a decision on the river."},
			{"tag": F, "title": "Level 4  -  Not Greater Than My Country", "body": "The raid on the rampart that you fight off tonight is invented gameplay."},
		],
		"outro": [{"tag": H, "title": "The river", "body": "With the land route shut, Ram Singh's fleet pushed up the Brahmaputra toward the narrows at Saraighat."}],
		"segments": [
			["hint", "Half-built walls, loose scaffolding, raiders in the dark. Keep the builders safe."],
			["run", 400], ["tower", 220], ["crumble", 3], ["run", 200], ["foes", [["sword", 240], ["archer", 520]], 720], ["spikes", 3], ["leaf", -150], ["cp"],
			["movers", 2, "lift"], ["run", 220], ["foes", [["armoured", 280], ["spear", 520]], 760], ["pillars", 4, 150], ["supply"], ["cp"],
			["allies", [["sword", 60], ["sword", 140]]],
			["arena", [[["sword", 0.6], ["spear", 0.8], ["archer", 0.95]], [["armoured", 0.6], ["armoured", 0.8], ["archer", 0.95]]], 1000],
			["stairs", 3, -85, 180], ["crumble", 4], ["run", 200], ["stones", 700], ["foes", [["archer", 260], ["archer", 520], ["sword", 720]], 900], ["leaf", -150], ["cp"],
			["spikes", 4], ["movers", 3, "lift"], ["run", 220], ["foes", [["armoured", 300], ["armoured", 560], ["archer", 820]], 1000], ["supply"], ["cp"],
			["obj", "Defeat the leader of the raiders."],
			["boss", {"name": "Leader of the Night Raid", "hp": 340.0, "adds": [["archer", 0.95]]}, 1000],
			["run", 400],
		],
	},
	"lachit_5": {
		"title": "Saraighat", "place": "The Brahmaputra, March 1671", "caption": "SARAIGHAT, THE BRAHMAPUTRA  -  MARCH 1671",
		"theme": "brahmaputra", "tier": 5, "objective": "Boat to boat - carry the fight across the river.",
		"intro": [
			{"tag": H, "title": "March 1671  -  Saraighat", "body": "The Mughal fleet forced its way up the Brahmaputra to the narrows at Saraighat. The Ahom boats began to give way. Lachit was gravely ill - and had himself carried aboard a war boat and rowed straight at the enemy."},
			{"tag": T, "title": "\"Let the king's men go where they please\"", "body": "The chronicles have him shouting that he would die doing his duty even if every man left him. The retreating boats turned around."},
			{"tag": F, "title": "Level 5  -  Saraighat", "body": "The boat-to-boat fighting and the fleet captain are invented gameplay. The decks drift: time every leap."},
		],
		"outro": [
			{"tag": H, "title": "Victory on the river", "body": "The smaller, faster Ahom boats broke the Mughal fleet at Saraighat, and Ram Singh's army withdrew from Assam. Lachit died about a year later. India's National Defence Academy awards its best cadet a gold medal in his name."},
			{"tag": F, "title": "A legend complete", "body": "You have finished Lachit Borphukan's story."},
		],
		"segments": [
			["hint", "Saraighat. The boats never stop moving - and neither should you."],
			["allies", [["sword", 120]]],
			["run", 400], ["foes", [["sword", 260], ["archer", 560]], 760], ["movers", 3, "boat"], ["run", 320], ["leaf", -150], ["cp"],
			["volley", 800, "arrows"], ["foes", [["armoured", 280], ["spear", 520], ["archer", 780]], 950], ["movers", 3, "boat"], ["run", 300], ["supply"], ["cp"],
			["spikes", 3], ["crumble", 3], ["run", 260], ["foes", [["armoured", 260], ["armoured", 480], ["archer", 760]], 950], ["pillars", 3, 150], ["leaf", -150], ["cp"],
			["allies", [["sword", 60], ["sword", 140]]],
			["arena", [[["sword", 0.55], ["spear", 0.75], ["archer", 0.95]], [["armoured", 0.6], ["spear", 0.8], ["archer", 0.95]], [["armoured", 0.55], ["armoured", 0.75], ["sword", 0.88], ["archer", 0.97]]], 1200],
			["movers", 4, "boat"], ["run", 300], ["volley", 700, "arrows"], ["cp"], ["supply"],
			["obj", "Board the flagship and defeat its captain."],
			["boss", {"name": "Captain of the Flagship", "hp": 440.0, "adds": [["archer", 0.95], ["spear", 0.85]]}, 1150],
			["run", 500],
		],
	},
}


# ------------------------------------------------------------------ lookups

static func hero_of(level_id: String) -> String:
	for h in HERO_ORDER:
		if level_id in HEROES[h].levels:
			return h
	return ""


static func level_index(level_id: String) -> int:
	var h := hero_of(level_id)
	return HEROES[h].levels.find(level_id) if h != "" else -1


static func next_level(level_id: String) -> String:
	var h := hero_of(level_id)
	if h == "":
		return ""
	var i: int = HEROES[h].levels.find(level_id)
	return HEROES[h].levels[i + 1] if i + 1 < HEROES[h].levels.size() else ""


static func scene_of(level_id: String) -> String:
	var l: Dictionary = LEVELS.get(level_id, {})
	return l.get("scene", SCENE_LEVEL) if not l.is_empty() else ""


static func label(level_id: String) -> String:
	var l: Dictionary = LEVELS.get(level_id, {})
	return "%d. %s  (%s)" % [level_index(level_id) + 1, l.get("title", level_id), l.get("place", "")]


static func faction_of(level_id: String) -> Dictionary:
	var l: Dictionary = LEVELS.get(level_id, {})
	var f: String = l.get("faction", HEROES[hero_of(level_id)].faction) if hero_of(level_id) != "" else ""
	return FACTIONS.get(f, {})
