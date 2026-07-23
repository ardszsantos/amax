class_name SaveManager

# Serviço de persistência. Lê/grava direto dos autoloads Economy e Progression —
# não precisa mais do main.

const SAVE_PATH = "user://save.dat"

static func save_game() -> void:
	var data = {
		"aura": Economy.aura,
		"items": [],
		"timestamp": Time.get_unix_time_from_system()
	}

	for item in Progression.items:
		var item_data = {
			"level": item.level,
			"cost": item.cost,
			"upgrades": []
		}
		for upgrade in item.upgrades:
			item_data.upgrades.append({
				"purchased": upgrade.purchased
			})
		data.items.append(item_data)

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

static func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var data = json.data

	if data == null:
		return

	Economy.set_aura(data.aura)

	for i in range(min(data.items.size(), Progression.items.size())):
		var idata = data.items[i]
		var item = Progression.items[i]

		# Nível do item. Saves antigos não tinham "level": derivamos do antigo
		# "unlocked" (desbloqueado = nível 1).
		if idata.has("level"):
			item.level = int(idata.level)
		else:
			item.level = 1 if idata.get("unlocked", false) else 0

		# Custo da próxima compra. Sem "cost" salvo, recalcula pela fórmula.
		if idata.has("cost"):
			item.cost = int(idata.cost)
		else:
			item.cost = int(item.base_cost * pow(Item.COST_GROWTH, item.level))

		# Upgrades de compra única. Saves antigos guardavam level/cost do antigo
		# "Boost"; como o conceito mudou, só lemos "purchased" (default false).
		for j in range(min(idata.upgrades.size(), item.upgrades.size())):
			item.upgrades[j].purchased = idata.upgrades[j].get("purchased", false)

	# Sempre reseta a barra/progresso ao carregar.
	Progression.current_item_index = 0
	Progression.current_clicks = 0

static func delete_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
