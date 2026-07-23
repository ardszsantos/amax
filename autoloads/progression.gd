extends Node

# Autoload "Progression" — dona da progressão pelos itens: qual item está ativo,
# o progresso da barra (cliques), o avanço/regressão e a drenagem constante.
# Estado global e singular, igual o Economy. Emite item_changed ao trocar de item;
# a barra (view, no main) reflete current_clicks a cada frame.

signal item_changed(new_index: int)

# >>> EDITÁVEL: quanto de progresso (em "cliques") a barra perde por segundo.
# Força constante puxando a barra pra baixo; os cliques têm que vencer ela.
const DRAIN_PER_SECOND: float = 1.5
# >>> EDITÁVEL: segundos de imunidade logo após promover pra um item novo
# (a barra não drena nem demove nessa janela).
const PROMOTE_GRACE: float = 2.0

# Referência à lista de itens. O main constrói o conteúdo e entrega aqui.
var items: Array = []
var current_item_index: int = 0
var current_clicks: float = 0.0
var promote_grace: float = 0.0

# Zera o estado. Chamado no boot antes de carregar o save (Progression é autoload
# e sobrevive ao reload de cena do wipe, então precisa ser resetado na mão).
func reset() -> void:
	current_item_index = 0
	current_clicks = 0.0
	promote_grace = 0.0

func get_current_item():
	return items[current_item_index]

# Aura por clique CUMULATIVA: soma o item atual + todos os anteriores.
# Ex.: no Mewing você ganha o clique do Mewing + o do 67 junto.
func get_click_value() -> float:
	var total := 0.0
	for i in range(current_item_index + 1):
		total += items[i].get_aura_per_click()
	return total

# Um clique do jogador: rende aura (Economy) e empurra a barra; avança se encheu.
func register_click() -> void:
	var item = get_current_item()
	Economy.add_aura(get_click_value())
	current_clicks += 1
	if can_advance() and current_clicks >= item.clicks_to_advance:
		advance_item()
	else:
		current_clicks = min(current_clicks, item.clicks_to_advance)

func can_advance() -> bool:
	return current_item_index < items.size() - 1 and items[current_item_index + 1].unlocked

func advance_item() -> void:
	current_item_index += 1
	current_clicks = 0
	promote_grace = PROMOTE_GRACE
	item_changed.emit(current_item_index)

# Inverso do advance: escorrega pro item anterior com a barra cheia.
func demote_item() -> void:
	current_item_index -= 1
	current_clicks = get_current_item().clicks_to_advance
	item_changed.emit(current_item_index)

func reset_to_first() -> void:
	var old_index = current_item_index
	current_item_index = 0
	current_clicks = 0
	if old_index != 0:
		item_changed.emit(current_item_index)

# Recalcula a renda passiva a partir dos itens desbloqueados (delega pro Economy).
func recalculate_income() -> void:
	var total := 0.0
	for item in items:
		if item.unlocked:
			total += item.get_passive_gain()
	Economy.set_income(total)

# Chamado quando um item novo é desbloqueado na loja: recalcula a renda e, se a
# barra já estava cheia esperando por ele, avança na hora.
func on_item_unlocked() -> void:
	recalculate_income()
	if current_clicks >= get_current_item().clicks_to_advance and can_advance():
		advance_item()

func _process(delta: float) -> void:
	_drain(delta)

# Drena a barra CONSTANTEMENTE (todo frame, até enquanto o jogador clica).
# Esvazia até 0; se não for o primeiro item, escorrega pro anterior ao zerar.
func _drain(delta: float) -> void:
	# Janela de imunidade pós-promoção: não drena nem demove.
	if promote_grace > 0.0:
		promote_grace = max(0.0, promote_grace - delta)
		return
	if current_clicks <= 0.0:
		return
	current_clicks = max(0.0, current_clicks - DRAIN_PER_SECOND * delta)
	if current_clicks <= 0.0 and current_item_index > 0:
		demote_item()
