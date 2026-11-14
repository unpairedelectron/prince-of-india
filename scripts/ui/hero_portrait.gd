class_name HeroPortrait
extends Control
## A hero standing in a framed panel (hero select / level select).

var hero := "pratap"
var locked := false
var _rig: HumanRig


## The in-game rig for a hero: Pratap's sprite sheet, or the procedural figure
## dressed from data/campaigns.gd for everyone else.
static func make_rig(h: String) -> HumanRig:
	var look: Dictionary = Campaigns.HEROES[h].look
	if look.get("sprite", false):
		return SpriteRig.new()
	var r := HumanRig.new()
	r.apply_look(look)
	return r


func _ready() -> void:
	clip_contents = true
	_rig = make_rig(hero)
	add_child(_rig)
	_rig.play("idle")
	if locked:
		_rig.modulate = Color(0.05, 0.05, 0.08)
	resized.connect(_place)
	_place()


func _place() -> void:
	var k := maxf(0.5, (size.y - 30.0) / (150.0 if _rig is SpriteRig and (_rig as SpriteRig).uses_sprite() else 118.0))
	_rig.scale = Vector2(k, k)
	_rig.position = Vector2(size.x * 0.5 - 6.0, size.y - 14.0)


func _draw() -> void:
	var look: Dictionary = Campaigns.HEROES[hero].look
	var tone: Color = look.get("turban", Game.C_SAFFRON)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.06, 0.14))
	for i in 6:
		draw_circle(Vector2(size.x * 0.5, size.y * 0.55), size.y * (0.62 - i * 0.08), Color(tone, 0.05 + i * 0.012) if not locked else Color(1, 1, 1, 0.015))
	draw_rect(Rect2(0, size.y - 14.0, size.x, 14.0), Color(0.2, 0.15, 0.12))
	draw_rect(Rect2(Vector2.ZERO, size), Game.C_GOLD if not locked else Color(0.4, 0.35, 0.3), false, 2.0)
