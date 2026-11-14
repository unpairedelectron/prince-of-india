class_name StoryText
extends RefCounted
## Narrative cards shown between gameplay. Every card carries a label so the
## player can tell documented history, traditional accounts and fictional
## gameplay apart. Sources: documentation/HISTORICAL_REFERENCES.md

const HISTORY := "HISTORICAL RECORD"
const TRADITION := "TRADITIONAL ACCOUNT"
const FICTION := "GAMEPLAY - FICTIONAL"

const MISSION_1_INTRO := [
	{
		"tag": HISTORY,
		"title": "1540  -  Kumbhalgarh",
		"body": "Pratap Singh of the Sisodia dynasty was born in 1540. His birth is traditionally associated with Kumbhalgarh, the great hill fort of Mewar in the Aravalli range.",
	},
	{
		"tag": HISTORY,
		"title": "1572  -  Gogunda",
		"body": "After the death of his father, Maharana Udai Singh II, in 1572, Pratap became Maharana of Mewar. His accession took place at Gogunda, in the hills west of Udaipur.",
	},
	{
		"tag": FICTION,
		"title": "Mission 1  -  The Oath of Mewar",
		"body": "The training ground, the wall course and the sparring partners you are about to meet are invented for this game. They teach the controls; they are not historical events.",
	},
]

const MISSION_1_OUTRO := [
	{
		"tag": FICTION,
		"title": "Training complete",
		"body": "The young Maharana has proven himself on the training ground, and Chetak answers to his rider.",
	},
]

const MISSION_2_INTRO := [
	{
		"tag": HISTORY,
		"title": "1572 - 1576",
		"body": "Pratap would not accept Mughal overlordship. Emperor Akbar sent envoys; Pratap declined to submit in person. In 1576 an imperial army marched on Mewar under the command of Raja Man Singh of Amber.",
	},
	{
		"tag": HISTORY,
		"title": "18 June 1576  -  Haldighati",
		"body": "The armies met near the narrow pass of Haldighati, named for its turmeric-yellow earth. Mewar's forces included an Afghan contingent led by Hakim Khan Sur in the vanguard and Bhil archers under Punja. This was a contest of kingdoms and alliances, not of faiths.",
	},
	{
		"tag": FICTION,
		"title": "Mission 2  -  The Yellow Pass",
		"body": "The soldiers you fight and fight beside are fictional composites, and the chokepoint and rear-guard actions are invented gameplay. Your goal is survival: protect your allies and find the way out of the pass.",
	},
]

const MISSION_2_OUTRO := [
	{
		"tag": HISTORY,
		"title": "The outcome",
		"body": "The battle lasted a few hours. The imperial army held the field, but Pratap escaped and was not captured. He withdrew into the Aravalli hills, and the struggle for Mewar went on for years.",
	},
]

const MISSION_3_INTRO := [
	{
		"tag": TRADITION,
		"title": "Chetak",
		"body": "Tradition holds that Pratap's horse, Chetak, was wounded at Haldighati yet carried his rider out of the battle and across a stream to safety. Contemporary sources do not name the horse; the story comes to us through tradition and later accounts.",
	},
	{
		"tag": FICTION,
		"title": "Mission 3  -  Chetak: The Final Ride",
		"body": "The mountain route, its obstacles and their order are invented for gameplay, inspired by the Aravalli landscape.",
	},
]

const MISSION_3_OUTRO := [
	{
		"tag": TRADITION,
		"title": "A memorial",
		"body": "According to tradition, Chetak died soon after carrying Pratap to safety. A memorial, the Chetak Samadhi at Balicha near Haldighati, marks the place associated with him. It is protected by the Archaeological Survey of India.",
	},
	{
		"tag": HISTORY,
		"title": "After 1576",
		"body": "Pratap did not surrender. He regrouped in the Aravalli hills, and the struggle for Mewar went on.",
	},
]
