extends Control

var aura: float = 0.0
var aura_per_second: float = 0.0
var items: Array = []
var current_item_index: int = 0
var current_clicks: int = 0
var idle_timer: float = 0.0
var save_timer: float = 0.0

# >>> EDITÁVEL: segundos parado (sem clicar) até voltar pro primeiro item.
const IDLE_TIMEOUT: float = 60.0
# >>> EDITÁVEL: de quantos em quantos segundos o jogo salva sozinho.
const SAVE_INTERVAL: float = 5.0

@onready var home_screen = $HomeScreen
@onready var upgrades_screen = $UpgradesScreen
@onready var pause_menu = $PauseMenu

@onready var label_aura = $HomeScreen/MarginContainer/VBoxContainer/LabelAura
@onready var label_renda = $HomeScreen/MarginContainer/VBoxContainer/LabelRenda
@onready var progress_bar = $HomeScreen/MarginContainer/VBoxContainer/ProgressBar
@onready var item_label = $HomeScreen/MarginContainer/VBoxContainer/ItemLabel

@onready var upgrades_tab = $HomeScreen/SideButtons/HBoxContainer/UpgradesTab
@onready var favorites_tab = $HomeScreen/SideButtons/HBoxContainer/FavoritesTab
@onready var back_btn = $UpgradesScreen/BackBtn

@onready var resume_btn = $PauseMenu/VBoxContainer/ResumeBtn
@onready var save_btn = $PauseMenu/VBoxContainer/SaveBtn
@onready var menu_btn = $PauseMenu/VBoxContainer/MenuBtn

signal item_changed(new_index: int)

func _ready():
	# ============================================================
	# >>> EDITÁVEL: LISTA DE ITENS
	# Cada Item.new() segue esta ordem:
	#   Item.new( NOME , AURA_POR_CLIQUE , GANHO_PASSIVO_POR_SEGUNDO , CLIQUES_PRA_AVANCAR )
	#     - NOME: precisa bater EXATAMENTE com o nome da animação do sprite.
	#     - AURA_POR_CLIQUE: quanto ganha em cada clique (antes dos upgrades).
	#     - GANHO_PASSIVO_POR_SEGUNDO: aura que pinga sozinha, por segundo, se desbloqueado.
	#     - CLIQUES_PRA_AVANCAR: quantos cliques pra passar pro próximo item.
	# ============================================================
	items = [
		Item.new("67", 1.0, 0.1, 20),
		Item.new("Mewing", 5.0, 0.5, 20),
		Item.new("Academia", 25.0, 2.5, 20),
		Item.new("Gloving", 125.0, 12.5, 20),
		Item.new("Hype Beast", 625.0, 62.5, 20),
	]
	items[0].unlocked = true

	# ============================================================
	# >>> EDITÁVEL: UPGRADES DE CADA ITEM
	# items[0] = "67", items[1] = "Mewing", items[2] = "Academia", etc.
	# Cada ItemUpgrade.new() segue esta ordem:
	#   ItemUpgrade.new( NOME , CUSTO_INICIAL , BONUS , TIPO )
	#     - CUSTO_INICIAL: preço da 1ª compra (sobe sozinho a cada nível).
	#     - BONUS: quanto cada nível soma.
	#     - TIPO: "click" soma na aura por clique | "passive" soma no ganho por segundo.
	# ============================================================
	items[0].add_upgrade(ItemUpgrade.new("Click Boost", 10, 0.5, "click"))
	items[0].add_upgrade(ItemUpgrade.new("Passive Gain", 15, 0.05, "passive"))

	items[1].add_upgrade(ItemUpgrade.new("Click Boost", 50, 2.0, "click"))
	items[1].add_upgrade(ItemUpgrade.new("Passive Gain", 75, 0.25, "passive"))

	items[2].add_upgrade(ItemUpgrade.new("Click Boost", 200, 10.0, "click"))
	items[2].add_upgrade(ItemUpgrade.new("Passive Gain", 300, 1.0, "passive"))

	items[3].add_upgrade(ItemUpgrade.new("Click Boost", 1000, 50.0, "click"))
	items[3].add_upgrade(ItemUpgrade.new("Passive Gain", 1500, 5.0, "passive"))

	items[4].add_upgrade(ItemUpgrade.new("Click Boost", 5000, 250.0, "click"))
	items[4].add_upgrade(ItemUpgrade.new("Passive Gain", 7500, 25.0, "passive"))

	SaveManager.load_game(self)
	recalculate_passive()

	upgrades_tab.pressed.connect(func(): switch_screen(upgrades_screen))
	favorites_tab.pressed.connect(_toggle_pause)
	back_btn.pressed.connect(func(): switch_screen(home_screen))

	pause_menu.visible = false
	resume_btn.pressed.connect(_toggle_pause)
	save_btn.pressed.connect(_on_save)
	menu_btn.pressed.connect(_on_return_menu)

	update_hud()
	switch_screen(home_screen)
	upgrades_screen.build_list()

func get_current_item() -> Item:
	return items[current_item_index]

func on_click():
	var item = get_current_item()
	aura += item.get_aura_per_click()
	current_clicks += 1
	idle_timer = 0.0

	if can_advance() and current_clicks >= item.clicks_to_advance:
		advance_item()
	else:
		current_clicks = min(current_clicks, item.clicks_to_advance)

	update_hud()

func can_advance() -> bool:
	return current_item_index < items.size() - 1 and items[current_item_index + 1].unlocked

func advance_item():
	current_item_index += 1
	current_clicks = 0
	update_hud()
	item_changed.emit(current_item_index)

func reset_to_first():
	var old_index = current_item_index
	current_item_index = 0
	current_clicks = 0
	update_hud()
	if old_index != 0:
		item_changed.emit(current_item_index)

func recalculate_passive():
	aura_per_second = 0.0
	for item in items:
		if item.unlocked:
			aura_per_second += item.get_passive_gain()

func update_hud():
	var item = get_current_item()

	label_aura.text = str(int(aura)) + " Aura"
	label_renda.text = str(snapped(aura_per_second, 0.01)) + "/s"
	progress_bar.max_value = item.clicks_to_advance
	progress_bar.value = current_clicks

	var text = item.item_name
	if can_advance():
		text += " → " + items[current_item_index + 1].item_name
	elif current_item_index == items.size() - 1 or not items[current_item_index + 1].unlocked:
		text += " (Max)"
	item_label.text = text

func on_item_unlocked():
	recalculate_passive()
	if current_clicks >= get_current_item().clicks_to_advance and can_advance():
		advance_item()

func switch_screen(screen: Control):
	home_screen.visible = false
	upgrades_screen.visible = false
	screen.visible = true

func _toggle_pause():
	pause_menu.visible = not pause_menu.visible

func _on_save():
	SaveManager.save_game(self)
	save_btn.text = "Saved!"
	save_btn.disabled = true
	await get_tree().create_timer(1.5).timeout
	save_btn.text = "Save"
	save_btn.disabled = false

func _on_return_menu():
	SaveManager.save_game(self)
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _process(delta):
	idle_timer += delta
	if idle_timer >= IDLE_TIMEOUT:
		idle_timer = 0.0
		reset_to_first()

	save_timer += delta
	if save_timer >= SAVE_INTERVAL:
		save_timer = 0.0
		SaveManager.save_game(self)

	if aura_per_second > 0:
		var old_aura = int(aura)
		aura += aura_per_second * delta
		if int(aura) != old_aura:
			update_hud()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveManager.save_game(self)
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		SaveManager.save_game(self)
