extends Node
## Smoke test: every campaign level builds, and the menu opens. No gameplay.

func _ready() -> void:
	var bad := 0
	for id in Campaigns.LEVELS:
		var l: Dictionary = Campaigns.LEVELS[id]
		if l.get("kind", "") == "scene":
			continue
		var b := LevelBuilder.new().build(l.segments, Campaigns.THEMES[l.theme], l.tier, 1)
		var ok: bool = b.end_x > 3000.0 and b.C.CHECKPOINTS.size() >= 3
		print("%s  %-14s len %5d  cps %d  foes %2d  arenas %d  spikes %2d  movers %2d  leaves %d" % ["ok " if ok else "BAD", id, b.end_x, b.C.CHECKPOINTS.size(), b.foes.size(), b.arenas.size(), b.spikes.size(), b.movers.size(), b.C.LEAVES.size()])
		if not ok:
			bad += 1
	for id in Campaigns.LEVELS:
		Game.reset_progress()
		Game.progress.current_mission = id
		var m: Node = load(Game.MISSIONS[id]).instantiate()
		add_child(m)
		await get_tree().create_timer(0.4).timeout
		m.queue_free()
		await get_tree().process_frame
	var menu: Node = load(Game.SCENE_MENU).instantiate()
	add_child(menu)
	await get_tree().create_timer(0.3).timeout
	menu._on_heroes()
	await get_tree().create_timer(0.2).timeout
	menu._on_levels("lachit")
	await get_tree().create_timer(0.2).timeout
	print("SMOKE DONE bad=%d" % bad)
	Game.reset_progress()
	get_tree().quit(bad)
