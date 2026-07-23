extends Control

const ItemRow = preload("res://ui/item_row.tscn")

@onready var list: VBoxContainer = %UpgradeList
@onready var info_popup: Control = %UpgradeInfoPopup
@onready var info_backdrop: Control = %UpgradeInfoBackdrop
@onready var popup_title: Label = %UpgradeInfoTitle
@onready var popup_desc: Label = %UpgradeInfoDesc

# >>> EDITÁVEL: tempo (s) que o upgrade fica "armado" esperando o 2º toque
# antes de desarmar sozinho.
const ARM_TIMEOUT := 2.5

# Guarda quais upgrades estavam "compráveis" na última montagem,
# pra só re-ordenar quando isso muda (evita rebuild a cada frame).
var _last_signature: Array = []
# Trava o rebuild enquanto a animação de compra toca.
var _busy: bool = false

# Double-tap: 1º toque ARMA o upgrade (visual âmbar), 2º toque na MESMA row COMPRA.
var _armed_upgrade: ItemUpgrade = null
var _armed_row = null
var _arm_token := 0

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	info_popup.visible = false
	# Tocar no fundo escuro fecha o popup.
	info_backdrop.gui_input.connect(_on_backdrop_input)

func _on_visibility_changed() -> void:
	if visible:
		info_popup.visible = false
		_disarm()
		build_list()

func _process(_delta: float) -> void:
	# Enquanto a tela está aberta, a aura passiva continua pingando.
	# Se isso mudar quem dá pra comprar, re-ordena. NÃO re-monta com um upgrade
	# armado (senão a row armada seria liberada no meio da confirmação).
	if not visible or _busy or _armed_upgrade != null:
		return
	if _current_signature() != _last_signature:
		build_list()

func build_list() -> void:
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 0)

	for child in list.get_children():
		child.queue_free()

	# Upgrades dos itens que o jogador POSSUI e que ainda NÃO foram comprados
	# (compra única: uma vez comprado, some da lista).
	var entries: Array = []
	for item in Progression.items:
		if not item.unlocked:
			continue
		for up in item.upgrades:
			if not up.purchased:
				entries.append({"item": item, "upgrade": up})

	# Do mais barato ao mais caro (spec do Miro).
	entries.sort_custom(func(a, b):
		return a.upgrade.cost < b.upgrade.cost
	)

	for e in entries:
		var affordable = Economy.aura >= e.upgrade.cost
		var row = ItemRow.instantiate()
		list.add_child(row)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.setup_upgrade(e.item, e.upgrade, affordable)
		row.upgrade_pressed.connect(_on_upgrade_pressed.bind(row))
		row.upgrade_info_pressed.connect(_on_upgrade_info)

	_last_signature = _current_signature()

# Lista de bools (dá pra comprar?) dos upgrades ainda não comprados.
func _current_signature() -> Array:
	var sig: Array = []
	for item in Progression.items:
		if not item.unlocked:
			continue
		for up in item.upgrades:
			if not up.purchased:
				sig.append(Economy.aura >= up.cost)
	return sig

# 1º toque ARMA o upgrade; 2º toque na MESMA row COMPRA. Tocar em outro upgrade
# desarma o anterior e arma o novo.
func _on_upgrade_pressed(up: ItemUpgrade, row) -> void:
	if _busy:
		return
	# 2º toque na row já armada -> compra.
	if up == _armed_upgrade and is_instance_valid(_armed_row):
		_buy_armed()
		return
	# Desarma qualquer anterior.
	_disarm()
	# Sem aura: nem arma, só dá o flash de negado.
	if Economy.aura < up.cost:
		row.flash_denied()
		return
	# Arma esta (1º toque): a row fica âmbar/pulsando via set_armed.
	_armed_upgrade = up
	_armed_row = row
	row.set_armed(true)
	_arm_token += 1
	_auto_disarm(up, _arm_token)

# Desarma sozinho depois de ARM_TIMEOUT, se ninguém confirmou nem re-armou.
func _auto_disarm(up: ItemUpgrade, token: int) -> void:
	await get_tree().create_timer(ARM_TIMEOUT).timeout
	if token == _arm_token and up == _armed_upgrade:
		_disarm()

# Efetua a compra do upgrade armado (com o flash verde). HUD atualiza via signals.
func _buy_armed() -> void:
	var up: ItemUpgrade = _armed_upgrade
	var row = _armed_row
	# Limpa o estado armado (restaura o texto do custo) antes do flash de compra.
	_disarm()
	if up == null:
		return
	if up.buy():
		if is_instance_valid(row):
			row.flash_success()  # comprou -> verde + punch
		_busy = true
		Progression.recalculate_income()
		# Deixa o flash/punch da row tocar antes de reconstruir a lista.
		await get_tree().create_timer(0.16).timeout
		_busy = false
		build_list()  # comprado -> some da lista
	elif is_instance_valid(row):
		row.flash_denied()  # sem aura -> vermelho

func _disarm() -> void:
	if is_instance_valid(_armed_row):
		_armed_row.set_armed(false)
	_armed_row = null
	_armed_upgrade = null

# Abre o popup com os efeitos do upgrade (clique + passivo + o que mais tiver).
func _on_upgrade_info(item: Item, upgrade: ItemUpgrade) -> void:
	popup_title.text = item.item_name + " · " + upgrade.upgrade_name
	popup_desc.text = upgrade.describe()
	info_popup.visible = true

func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		info_popup.visible = false
