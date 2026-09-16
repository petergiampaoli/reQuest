extends Node
## SaveManager — handles save/load + safe exit at Long Rest.
## Save file is only written at Long Rest / explicit save; start menu can also save.

const SAVE_PATH := "user://request_save.json"

func save_game(gm: Node) -> void:
	var data := {
		"gold": gm.gold,
		"lives": gm.lives,
		"quest_number": gm.quest_number,
		"total_successes": gm.total_successes,
		"total_tasks_completed": gm.total_tasks_completed,
		"total_failures": gm.total_failures,
		"upgrades": gm.upgrades,
		"owned_trinkets": gm.owned_trinkets,
		"equipped_trinkets": gm.equipped_trinkets,
		"version": 3,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("[SaveManager] Cannot open save file for write: %s" % SAVE_PATH)
		return
	f.store_string(JSON.stringify(data))
	f.close()
	print("[SaveManager] Saved to %s" % SAVE_PATH)

func load_game(gm: Node) -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveManager] No save file — fresh start")
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_error("[SaveManager] Cannot open save file for read")
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if parsed == null or not (parsed is Dictionary):
		push_error("[SaveManager] Corrupt save file — ignoring")
		return
	var d: Dictionary = parsed
	gm.gold = int(d.get("gold", 0))
	gm.lives = int(d.get("lives", 3))
	gm.quest_number = int(d.get("quest_number", 1))
	gm.total_successes = int(d.get("total_successes", 0))
	gm.total_tasks_completed = int(d.get("total_tasks_completed", gm.total_successes + int(d.get("total_failures", 0))))
	gm.total_failures = int(d.get("total_failures", 0))
	if d.has("upgrades") and d["upgrades"] is Dictionary:
		for k in gm.upgrades.keys():
			if d["upgrades"].has(k):
				gm.upgrades[k] = int(d["upgrades"][k])
	if d.has("owned_trinkets") and d["owned_trinkets"] is Dictionary:
		gm.owned_trinkets = {}
		for k in d["owned_trinkets"].keys():
			gm.owned_trinkets[k] = int(d["owned_trinkets"][k])
	if d.has("equipped_trinkets") and d["equipped_trinkets"] is Array:
		gm.equipped_trinkets.clear()
		for id in d["equipped_trinkets"]:
			if gm.owned_trinkets.get(id, 0) > 0 and not gm.equipped_trinkets.has(id):
				gm.equipped_trinkets.append(str(id))
	print("[SaveManager] Loaded: quest %d, gold %d, lives %d, tasks %d, trinkets %s" % [gm.quest_number, gm.gold, gm.lives, gm.total_tasks_completed, str(gm.equipped_trinkets)])

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
