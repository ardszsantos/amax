extends Control

var aura: float = 0.0
var aura_per_second: float = 0.0
var items: Array = []
var current_item_index: int = 0
var current_clicks: float = 0.0
var save_timer: float = 0.0
# Tempo restante de imunidade pós-promoção (ver PROMOTE_GRACE).
var promote_grace: float = 0.0

# >>> EDITÁVEL: quanto de progresso (em "cliques") a barra perde por segundo.
# A drenagem é CONSTANTE — acontece sempre, até enquanto o jogador clica.
# É uma força puxando a barra pra baixo; pra avançar, os cliques têm que
# vencer essa força. Maior = mais difícil avançar.
const DRAIN_PER_SECOND: float = 1.5
# >>> EDITÁVEL: segundos de "imunidade" logo após promover pra um item novo.
# Durante essa janela a barra não drena nem demove, dando tempo de começar a clicar.
const PROMOTE_GRACE: float = 2.0
# >>> EDITÁVEL: de quantos em quantos segundos o jogo salva sozinho
# (também é a frequência com que o "saved ✓" aparece no canto).
const SAVE_INTERVAL: float = 30.0

@onready var home_screen = $HomeScreen
@onready var items_screen = $ItemsScreen
@onready var upgrades_screen = $UpgradesScreen
@onready var pause_menu = $PauseMenu

@onready var label_aura = $HomeScreen/MarginContainer/VBoxContainer/LabelAura
@onready var label_renda = $HomeScreen/MarginContainer/VBoxContainer/LabelRenda
@onready var progress_bar = $HomeScreen/MarginContainer/VBoxContainer/ProgressBar
@onready var item_label = $HomeScreen/MarginContainer/VBoxContainer/ItemLabel

@onready var upgrades_tab = $HomeScreen/SideButtons/HBoxContainer/UpgradesTab
@onready var favorites_tab = $HomeScreen/SideButtons/HBoxContainer/FavoritesTab
@onready var home_tab = $HomeScreen/SideButtons/HBoxContainer/HomeTab
@onready var back_btn = $ItemsScreen/BackBtn
@onready var upgrades_back_btn = $UpgradesScreen/BackBtn

@onready var resume_btn = $PauseMenu/VBoxContainer/ResumeBtn
@onready var save_btn = $PauseMenu/VBoxContainer/SaveBtn
@onready var wipe_btn = $PauseMenu/VBoxContainer/WipeBtn
@onready var save_flash = $HomeScreen/SaveFlash

# Estado do botão "Wipe Save": precisa de dois toques pra confirmar.
var wipe_armed: bool = false

signal item_changed(new_index: int)

func _ready():
	# ============================================================
	# >>> EDITÁVEL: LISTA DE ITENS
	# Cada Item.new() segue esta ordem:
	#   Item.new( NOME , AURA_POR_CLIQUE , GANHO_PASSIVO/s , CLIQUES_PRA_AVANCAR , CUSTO_BASE , ICONE )
	#     - NOME: precisa bater EXATAMENTE com o nome da animação do sprite.
	#     - AURA_POR_CLIQUE: aura por clique NO NÍVEL 1 (escala com o nível do item).
	#     - GANHO_PASSIVO/s: aura passiva por segundo NO NÍVEL 1 (escala com o nível).
	#     - CLIQUES_PRA_AVANCAR: quantos cliques pra passar pro próximo item.
	#     - CUSTO_BASE: preço da 1ª compra. Sobe a cada nível comprado.
	# Item começa no nível 0 (bloqueado); cada compra na tela de itens = +1 nível.
	# ============================================================
	items = [
		Item.new("67", 0.143, 1, 20, 50, preload("res://assets/ui/67_icone.png")),
		Item.new("Mewing", 1, 7, 20, 500, preload("res://assets/ui/mewing.png")),
		Item.new("Academia", 7.142, 50, 20, 5000, preload("res://assets/ui/gym_icone.png")),
		Item.new("HypeBeast", 349.985, 2450, 20, 50000, preload("res://assets/ui/hyper_beast_icone.png")),
	]
	# O primeiro item começa desbloqueado (nível 1).
	items[0].level = 1

	# >>> EDITÁVEL: descrição que aparece no popup do "?" (estilo meme, edita à vontade).
	items[0].description = "durante seu treino você finalmente entendeu, o 67 é a verdade absoluta"
	items[1].description = "língua no céu da boca. o maxilar agradece."
	items[2].description = "sem dor, sem aura. simples assim."
	items[3].description = "se é caro, é aura."

	# ============================================================
	# >>> EDITÁVEL: UPGRADES DE COMPRA ÚNICA (1 por item, por enquanto)
	# items[0]="67", items[1]="Mewing", items[2]="Academia", items[3]="HypeBeast".
	# Cada ItemUpgrade.new() segue esta ordem:
	#   ItemUpgrade.new( NOME , CUSTO , EFEITOS )
	#     - NOME: texto que aparece no card do upgrade.
	#     - CUSTO: preço (compra única -- some da lista depois de comprado).
	#     - EFEITOS: dicionário { stat: MULTIPLICADOR } aplicado à produção do item.
	#         "click"   -> multiplica a AURA POR CLIQUE do item
	#         "passive" -> multiplica o GANHO PASSIVO do item
	#   >>> Pra um stat novo, use uma chave nova e ensine o item a lê-la
	#       (ver _upgrade_multiplier em item.gd).
	# >>> Os 2x são PLACEHOLDER do Miro -- ajustar depois.
	# ============================================================
	items[0].add_upgrade(ItemUpgrade.new("Angolanos do 67", 500, {"click": 2.0, "passive": 2.0}))
	items[1].add_upgrade(ItemUpgrade.new("Meditações do Maewing", 5000, {"click": 2.0, "passive": 2.0}))
	items[2].add_upgrade(ItemUpgrade.new("Supino Perfeito", 50000, {"click": 2.0, "passive": 2.0}))
	items[3].add_upgrade(ItemUpgrade.new("Besta do Hype", 5000000, {"click": 2.0, "passive": 2.0}))

	SaveManager.load_game(self)
	recalculate_passive()

	upgrades_tab.pressed.connect(func(): switch_screen(items_screen))
	favorites_tab.pressed.connect(_toggle_pause)
	home_tab.pressed.connect(func(): switch_screen(upgrades_screen))
	back_btn.pressed.connect(func(): switch_screen(home_screen))
	upgrades_back_btn.pressed.connect(func(): switch_screen(home_screen))

	pause_menu.visible = false
	resume_btn.pressed.connect(_toggle_pause)
	save_btn.pressed.connect(_on_save)
	wipe_btn.pressed.connect(_on_wipe_save)

	update_hud()
	switch_screen(home_screen, false)
	items_screen.build_list()

func get_current_item() -> Item:
	return items[current_item_index]

# Aura por clique CUMULATIVA: soma o valor do item atual + todos os anteriores.
# Ex.: no Mewing você ganha o clique do Mewing + o do 67 junto.
func get_click_value() -> float:
	var total = 0.0
	for i in range(current_item_index + 1):
		total += items[i].get_aura_per_click()
	return total

func on_click():
	var item = get_current_item()
	aura += get_click_value()
	current_clicks += 1

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
	promote_grace = PROMOTE_GRACE
	update_hud()
	item_changed.emit(current_item_index)

# Inverso do advance: escorrega pro item anterior com a barra cheia.
func demote_item():
	current_item_index -= 1
	current_clicks = get_current_item().clicks_to_advance
	update_hud()
	item_changed.emit(current_item_index)

func reset_to_first():
	var old_index = current_item_index
	current_item_index = 0
	current_clicks = 0
	update_hud()
	if old_index != 0:
		item_changed.emit(current_item_index)

# Drena a barra CONSTANTEMENTE (roda todo frame, até enquanto o jogador
# clica). É uma força puxando o progresso pra baixo: os cliques precisam
# vencer ela pra avançar. Esvazia até 0 e para ali.
func _drain(delta: float):
	# Janela de imunidade pós-promoção: não drena nem demove.
	if promote_grace > 0.0:
		promote_grace = max(0.0, promote_grace - delta)
		return
	if current_clicks <= 0.0:
		return
	current_clicks = max(0.0, current_clicks - DRAIN_PER_SECOND * delta)
	# Barra zerou: se não for o primeiro item, escorrega pro anterior.
	if current_clicks <= 0.0 and current_item_index > 0:
		demote_item()
	else:
		update_hud()

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

func switch_screen(screen: Control, play_swipe: bool = true):
	home_screen.visible = false
	items_screen.visible = false
	upgrades_screen.visible = false
	screen.visible = true
	# Swipe na troca de tela/menu. play_swipe=false no boot (montar a tela
	# inicial não é uma transição que o jogador provocou).
	if play_swipe:
		Audio.play_sfx("swipe")

func _toggle_pause():
	pause_menu.visible = not pause_menu.visible
	# Sempre que o menu abre/fecha, desarma o "Wipe Save" pra não apagar sem querer.
	_disarm_wipe()

func _on_save():
	SaveManager.save_game(self)
	_flash_saved()
	save_btn.text = "Saved!"
	save_btn.disabled = true
	await get_tree().create_timer(1.5).timeout
	save_btn.text = "Save"
	save_btn.disabled = false

# Mostra um "saved ✓" discreto no canto, segura ~2s e some suave.
func _flash_saved():
	save_flash.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(save_flash, "modulate:a", 0.0, 1.0)

func _disarm_wipe():
	wipe_armed = false
	wipe_btn.text = "Wipe Save"

# Primeiro toque arma; segundo toque apaga o save e recomeça do zero.
func _on_wipe_save():
	if not wipe_armed:
		wipe_armed = true
		wipe_btn.text = "Sure? Tap again"
		return
	SaveManager.delete_save()
	get_tree().reload_current_scene()

func _process(delta):
	_drain(delta)

	save_timer += delta
	if save_timer >= SAVE_INTERVAL:
		save_timer = 0.0
		SaveManager.save_game(self)
		_flash_saved()

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
