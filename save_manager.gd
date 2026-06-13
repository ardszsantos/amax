class_name SaveManager

const SAVE_PATH = "user://save.dat"

static func save_game(main):
	var data = {
		"aura": main.aura,
		"items": [],
		"timestamp": Time.get_unix_time_from_system()
	}
	
	for item in main.items:
		var item_data = {
			"unlocked": item.unlocked,
			"upgrades": []
		}
		for upgrade in item.upgrades:
			item_data.upgrades.append({
				"level": upgrade.level,
				"cost": upgrade.cost
			})
		data.items.append(item_data)
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

static func load_game(main):
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var data = json.data
	
	if data == null:
		return
	
	main.aura = data.aura
	
	for i in range(min(data.items.size(), main.items.size())):
		main.items[i].unlocked = data.items[i].unlocked
		for j in range(min(data.items[i].upgrades.size(), main.items[i].upgrades.size())):
			main.items[i].upgrades[j].level = data.items[i].upgrades[j].level
			main.items[i].upgrades[j].cost = data.items[i].upgrades[j].cost
	
	# Always reset bar on load
	main.current_item_index = 0
	main.current_clicks = 0
	
	# Check idle time
	var elapsed = Time.get_unix_time_from_system() - data.timestamp
	if elapsed > 60:
		main.current_item_index = 0
		main.current_clicks = 0

static func delete_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
