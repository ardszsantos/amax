extends Control

const ItemRow = preload("res://ui/item_row.tscn")

@onready var list: VBoxContainer = %ItemList
@onready var info_popup: Control = %InfoPopup
@onready var info_backdrop: Control = %InfoBackdrop
@onready var popup_title: Label = %PopupTitle
@onready var popup_desc: Label = %PopupDesc

# Guarda o estado (nível + comprável?) da última montagem, pra só re-montar
# quando algo muda (evita rebuild a cada frame).
var _last_signature: Array = []
# Trava o rebuild enquanto a animação de compra toca.
var _busy: bool = false

func _ready() -> void:
	info_popup.visible = false
	# Tocar no fundo escuro fecha o popup.
	info_backdrop.gui_input.connect(_on_backdrop_input)
	# Ao reabrir a tela de itens, garante popup fechado e lista atualizada.
	visibility_changed.connect(func():
		if visible:
			info_popup.visible = false
			build_list()
	)

func _process(_delta: float) -> void:
	# A aura passiva pinga o tempo todo; se isso muda quem dá pra comprar, re-monta.
	if not visible or _busy:
		return
	if _current_signature() != _last_signature:
		build_list()

# Reconstroi a lista de itens. Cada item é comprável infinitas vezes: cada
# compra sobe 1 nível e aumenta a produção (clique + passivo).
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
		var row = ItemRow.instantiate()
		list.add_child(row)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.setup(item, i, main.aura >= item.cost)
		row.buy_pressed.connect(_on_buy_pressed.bind(row))
		row.info_pressed.connect(_on_info_pressed)

	# Placeholders só pra preencher a tela (não compráveis, sem info).
	for _i in range(10):
		var row = ItemRow.instantiate()
		list.add_child(row)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.setup_placeholder()

	_last_signature = _current_signature()

# Estado (nível, dá pra comprar?) de cada item, pra detectar mudanças.
func _current_signature() -> Array:
	var main = get_node("/root/Main")
	var sig: Array = []
	for item in main.items:
		sig.append([item.level, main.aura >= item.cost])
	return sig

func _on_buy_pressed(index: int, row) -> void:
	if _busy:
		return
	var main = get_node("/root/Main")
	var item = main.items[index]
	var was_locked = item.level == 0
	if item.buy(main):
		row.flash_success()  # comprou -> verde
		_busy = true
		# 1º nível desbloqueia o item na progressão; níveis seguintes só recalculam.
		if was_locked:
			main.on_item_unlocked()
		else:
			main.recalculate_passive()
		main.update_hud()
		# Deixa o flash/punch da row tocar antes de reconstruir a lista.
		await get_tree().create_timer(0.16).timeout
		_busy = false
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
