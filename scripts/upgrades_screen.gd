extends Control

const ItemRow = preload("res://ui/item_row.tscn")

@onready var list: VBoxContainer = %ItemList
@onready var info_popup: Control = %InfoPopup
@onready var info_backdrop: Control = %InfoBackdrop
@onready var popup_title: Label = %PopupTitle
@onready var popup_desc: Label = %PopupDesc

func _ready() -> void:
	info_popup.visible = false
	# Tocar no fundo escuro fecha o popup.
	info_backdrop.gui_input.connect(_on_backdrop_input)
	# Ao reabrir a tela de itens, garante o popup fechado.
	visibility_changed.connect(func():
		if visible:
			info_popup.visible = false
	)

# Reconstroi a lista de itens. Chamado pelo Main no _ready e apos cada compra.
func build_list() -> void:
	var main = get_node("/root/Main")

	# Garante que a lista preencha a largura toda e que as rows fiquem grudadas
	# (a borda de cada row já serve de separador).
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 0)

	for child in list.get_children():
		child.queue_free()

	for i in range(main.items.size()):
		var item = main.items[i]
		var cost = get_item_cost(i)
		var row = ItemRow.instantiate()
		list.add_child(row)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.setup(item, i, cost, item.unlocked, main.aura >= cost)
		row.buy_pressed.connect(_on_buy_pressed.bind(row))
		row.info_pressed.connect(_on_info_pressed)

	# Placeholders só pra preencher a tela (não compráveis, sem info).
	for _i in range(10):
		var row = ItemRow.instantiate()
		list.add_child(row)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.setup_placeholder()

# >>> EDITÁVEL: custo pra desbloquear o item de índice `index`.
# base * 5^index -> cada item custa 5x o anterior.
func get_item_cost(index: int) -> int:
	var base = 50
	return int(base * pow(5, index))

func _on_buy_pressed(index: int, row) -> void:
	var main = get_node("/root/Main")
	var item = main.items[index]
	if item.unlocked:
		row.flash_owned()  # já tem -> azul neutro
		return

	var cost = get_item_cost(index)
	if main.aura >= cost:
		main.aura -= cost
		item.unlocked = true
		main.on_item_unlocked()
		main.update_hud()
		row.flash_success()  # comprou -> verde
		# Deixa o flash/punch da row tocar antes de reconstruir a lista.
		await get_tree().create_timer(0.16).timeout
		build_list()
	else:
		row.flash_denied()  # sem aura -> vermelho

func _on_info_pressed(index: int) -> void:
	var main = get_node("/root/Main")
	var item = main.items[index]
	popup_title.text = item.item_name
	popup_desc.text = item.description if item.description != "" else "(sem descrição)"
	info_popup.visible = true

func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		info_popup.visible = false
