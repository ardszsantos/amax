extends Control

func build_list():
	var main = get_node("/root/Main")
	var list = $MarginContainer/ScrollContainer/VBoxContainer
	
	for child in list.get_children():
		child.queue_free()
	
	for i in range(main.items.size()):
		var item = main.items[i]
		
		var item_container = VBoxContainer.new()
		item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var header = HBoxContainer.new()
		header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		header.custom_minimum_size = Vector2(0, 60)
		
		var toggle_btn = Button.new()
		toggle_btn.text = "▶"
		toggle_btn.custom_minimum_size = Vector2(40, 0)
		header.add_child(toggle_btn)
		
		var name_label = Label.new()
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		if item.unlocked:
			name_label.text = item.item_name + " (Owned)"
		else:
			name_label.text = item.item_name
		
		header.add_child(name_label)
		
		if not item.unlocked:
			var buy_btn = Button.new()
			var cost = get_item_cost(i)
			buy_btn.text = str(cost) + " Aura"
			buy_btn.custom_minimum_size = Vector2(100, 0)
			buy_btn.pressed.connect(func(): buy_item(i))
			header.add_child(buy_btn)
		
		item_container.add_child(header)
		
		var upgrades_box = VBoxContainer.new()
		upgrades_box.name = "Upgrades_" + str(i)
		upgrades_box.visible = false
		
		if item.unlocked:
			build_item_upgrades(upgrades_box, item)
		
		item_container.add_child(upgrades_box)
		
		toggle_btn.pressed.connect(func():
			upgrades_box.visible = not upgrades_box.visible
			toggle_btn.text = "▼" if upgrades_box.visible else "▶"
		)
		
		list.add_child(item_container)

func build_item_upgrades(container: VBoxContainer, item: Item):
	for upgrade in item.upgrades:
		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 50)
		
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(40, 0)
		row.add_child(spacer)
		
		var label = Label.new()
		label.text = upgrade.upgrade_name + " (Lv " + str(upgrade.level) + ")"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		
		var buy_btn = Button.new()
		buy_btn.text = str(upgrade.cost) + " Aura"
		buy_btn.custom_minimum_size = Vector2(100, 0)
		buy_btn.pressed.connect(func():
			var main = get_node("/root/Main")
			if upgrade.buy(main):
				label.text = upgrade.upgrade_name + " (Lv " + str(upgrade.level) + ")"
				buy_btn.text = str(upgrade.cost) + " Aura"
				main.recalculate_passive()
				main.update_hud()
		)
		row.add_child(buy_btn)
		
		container.add_child(row)

func get_item_cost(index: int) -> int:
	var base = 50
	return int(base * pow(5, index))

func buy_item(index: int):
	var main = get_node("/root/Main")
	var cost = get_item_cost(index)
	
	if main.aura >= cost:
		main.aura -= cost
		main.items[index].unlocked = true
		main.on_item_unlocked()
		main.update_hud()
		build_list()
