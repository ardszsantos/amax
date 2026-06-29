extends Control

const ItemRow = preload("res://ui/item_row.tscn")

@onready var list: VBoxContainer = %UpgradeList
@onready var info_popup: Control = %UpgradeInfoPopup
@onready var info_backdrop: Control = %UpgradeInfoBackdrop
@onready var popup_title: Label = %UpgradeInfoTitle
@onready var popup_desc: Label = %UpgradeInfoDesc

# Guarda quais upgrades estavam "compráveis" na última montagem,
# pra só re-ordenar quando isso muda (evita rebuild a cada frame).
var _last_signature: Array = []
# Trava o rebuild enquanto a animação de compra toca.
var _busy: bool = false

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	info_popup.visible = false
	# Tocar no fundo escuro fecha o popup.
	info_backdrop.gui_input.connect(_on_backdrop_input)

func _on_visibility_changed() -> void:
	if visible:
		info_popup.visible = false
		build_list()

func _process(_delta: float) -> void:
	# Enquanto a tela está aberta, a aura passiva continua pingando.
	# Se isso mudar quem dá pra comprar, re-ordena.
	if not visible or _busy:
		return
	if _current_signature() != _last_signature:
		build_list()

func build_list() -> void:
	var main = get_node("/root/Main")

	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 0)

	for child in list.get_children():
		child.queue_free()

	# Coleta os upgrades de todos os itens que o jogador POSSUI.
	var entries: Array = []
	for item in main.items:
		if not item.unlocked:
			continue
		for up in item.upgrades:
			entries.append({"item": item, "upgrade": up})

	# Ordena: compráveis primeiro, e dentro de cada grupo o mais barato no topo.
	entries.sort_custom(func(a, b):
		var a_afford = main.aura >= a.upgrade.cost
		var b_afford = main.aura >= b.upgrade.cost
		if a_afford != b_afford:
			return a_afford
		return a.upgrade.cost < b.upgrade.cost
	)

	for e in entries:
		var affordable = main.aura >= e.upgrade.cost
		var row = ItemRow.instantiate()
		list.add_child(row)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.setup_upgrade(e.item, e.upgrade, affordable)
		row.upgrade_pressed.connect(_on_upgrade_pressed.bind(row))
		row.upgrade_info_pressed.connect(_on_upgrade_info)

	_last_signature = _current_signature()

# Lista de bools (dá pra comprar?) na ordem dos itens/upgrades.
func _current_signature() -> Array:
	var main = get_node("/root/Main")
	var sig: Array = []
	for item in main.items:
		if not item.unlocked:
			continue
		for up in item.upgrades:
			sig.append(main.aura >= up.cost)
	return sig

func _on_upgrade_pressed(up: ItemUpgrade, row) -> void:
	if _busy:
		return
	var main = get_node("/root/Main")
	if up.buy(main):
		row.flash_success()  # comprou -> verde
		_busy = true
		main.recalculate_passive()
		main.update_hud()
		# Deixa o flash/punch da row tocar antes de reconstruir a lista.
		await get_tree().create_timer(0.16).timeout
		_busy = false
		build_list()
	else:
		row.flash_denied()  # sem aura -> vermelho

# Abre o popup com os stats do upgrade (clique + passivo + o que mais tiver).
func _on_upgrade_info(item: Item, upgrade: ItemUpgrade) -> void:
	popup_title.text = item.item_name + " · " + upgrade.upgrade_name
	popup_desc.text = upgrade.describe()
	info_popup.visible = true

func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		info_popup.visible = false
