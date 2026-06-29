extends PanelContainer

# Emitido ao tocar no card (comprar/desbloquear o item).
signal buy_pressed(index: int)
# Emitido ao tocar no "?" de um item (abrir o popup de descrição do item).
signal info_pressed(index: int)
# Emitido ao tocar no "?" de um upgrade (abrir o popup de stats do upgrade).
signal upgrade_info_pressed(item: Item, upgrade: ItemUpgrade)
# Emitido ao tocar num card de upgrade (comprar 1 nível).
signal upgrade_pressed(upgrade: ItemUpgrade)

@onready var icon: TextureRect = $MarginContainer/HBoxContainer/PanelContainer/Icon
@onready var title_label: Label = $MarginContainer/HBoxContainer/InfoBox/Title
@onready var cost_label: Label = $MarginContainer/HBoxContainer/InfoBox/Cost
@onready var info_button: Button = $MarginContainer/HBoxContainer/InfoButton

# Estados semânticos do card.
const STATE_NONE := 0     # placeholder, sem feedback
const STATE_BUYABLE := 1  # dá pra comprar  -> verde
const STATE_DENIED := 2   # sem aura        -> vermelho
const STATE_OWNED := 3    # já possui/sem ação -> azul neutro

# Tons SUAVES pro hover.
const HOVER_COLOR := {
	STATE_BUYABLE: Color(0.78, 1.0, 0.78),
	STATE_DENIED: Color(1.0, 0.78, 0.78),
	STATE_OWNED: Color(0.8, 0.88, 1.0),
}
# Tons FORTES pro flash do clique.
const FLASH_COLOR := {
	STATE_BUYABLE: Color(0.4, 1.0, 0.4),
	STATE_DENIED: Color(1.0, 0.35, 0.35),
	STATE_OWNED: Color(0.6, 0.8, 1.0),
}

var item_index: int = -1
var disabled: bool = false
var upgrade: ItemUpgrade = null
# Item dono do upgrade (só usado em cards de upgrade, pro popup de info).
var row_item: Item = null
var state: int = STATE_NONE
var _rest_modulate := Color(1, 1, 1, 1)
var _fx_tween: Tween

func _ready() -> void:
	# Faz o toque "atravessar" os filhos e chegar no card inteiro,
	# menos o "?", que trata o próprio clique.
	mouse_filter = Control.MOUSE_FILTER_STOP
	for node in _all_controls(self):
		if node == info_button:
			node.mouse_filter = Control.MOUSE_FILTER_STOP
		else:
			node.mouse_filter = Control.MOUSE_FILTER_PASS

	info_button.pressed.connect(_on_info_button)
	gui_input.connect(_on_gui_input)

	# Escala a partir do centro, não do canto.
	pivot_offset = size / 2.0
	resized.connect(func(): pivot_offset = size / 2.0)
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)

# ---------- SETUP ----------

# Card de item (tela de itens).
func setup(item: Item, index: int, cost: int, owned: bool, affordable: bool) -> void:
	item_index = index
	upgrade = null
	row_item = null
	disabled = false
	title_label.text = item.item_name
	cost_label.text = "Owned" if owned else "custo: " + str(cost) + " aura"
	if item.icon != null:
		icon.texture = item.icon
	if owned:
		state = STATE_OWNED
	elif affordable:
		state = STATE_BUYABLE
	else:
		state = STATE_DENIED
	_set_rest(Color(1, 1, 1, 1))

# Card de upgrade (tela de upgrades). Não-comprável fica cinza, mas ainda
# clicável pra dar o flash vermelho.
func setup_upgrade(item: Item, up: ItemUpgrade, affordable: bool) -> void:
	item_index = -1
	upgrade = up
	row_item = item
	disabled = false
	title_label.text = item.item_name + " · " + up.upgrade_name
	cost_label.text = "Lv " + str(up.level) + "  ·  custo: " + str(up.cost) + " aura"
	if item.icon != null:
		icon.texture = item.icon
	# Mostra o "?" pra abrir o popup com os stats do upgrade.
	info_button.visible = true
	info_button.disabled = false
	if affordable:
		state = STATE_BUYABLE
		_set_rest(Color(1, 1, 1, 1))
	else:
		state = STATE_DENIED
		_set_rest(Color(1, 1, 1, 0.45))

# Linha vazia só pra preencher a tela: sem feedback nenhum.
func setup_placeholder() -> void:
	disabled = true
	item_index = -1
	state = STATE_NONE
	title_label.text = "???"
	cost_label.text = ""
	icon.texture = null
	info_button.disabled = true
	_set_rest(Color(1, 1, 1, 0.5))

func _set_rest(c: Color) -> void:
	_rest_modulate = c
	modulate = c

# ---------- FEEDBACK DE CLIQUE (a tela chama com o resultado real) ----------

func flash_success() -> void:
	_flash(STATE_BUYABLE)

func flash_denied() -> void:
	_flash(STATE_DENIED)

func flash_owned() -> void:
	_flash(STATE_OWNED)

func _flash(s: int) -> void:
	_punch()
	var c: Color = FLASH_COLOR[s]
	c.a = _rest_modulate.a
	modulate = c
	_kill_fx()
	_fx_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_fx_tween.tween_property(self, "modulate", _rest_modulate, 0.3)

# Cresce rápido e volta (sensação de "apertou").
func _punch() -> void:
	var t := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(self, "scale", Vector2(1.08, 1.08), 0.05)
	t.tween_property(self, "scale", Vector2(1.0, 1.0), 0.10)

# ---------- HOVER (desktop) ----------

func _on_hover_enter() -> void:
	if disabled or state == STATE_NONE:
		return
	var c: Color = HOVER_COLOR[state]
	c.a = _rest_modulate.a
	_kill_fx()
	_fx_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_fx_tween.tween_property(self, "modulate", c, 0.08)
	_fx_tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.08)

func _on_hover_exit() -> void:
	if disabled or state == STATE_NONE:
		return
	_kill_fx()
	_fx_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_fx_tween.tween_property(self, "modulate", _rest_modulate, 0.08)
	_fx_tween.tween_property(self, "scale", Vector2(1, 1), 0.08)

func _kill_fx() -> void:
	if _fx_tween != null and _fx_tween.is_valid():
		_fx_tween.kill()

# ---------- INPUT ----------

func _on_info_button() -> void:
	# Card de upgrade abre o popup de stats; card de item abre a descrição.
	if upgrade != null:
		upgrade_info_pressed.emit(row_item, upgrade)
	else:
		info_pressed.emit(item_index)

func _on_gui_input(event: InputEvent) -> void:
	if disabled:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if upgrade != null:
			upgrade_pressed.emit(upgrade)
		else:
			buy_pressed.emit(item_index)

func _all_controls(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		if child is Control:
			result.append(child)
			result.append_array(_all_controls(child))
	return result
