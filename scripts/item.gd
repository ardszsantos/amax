class_name Item

var item_name: String
var aura_per_click: float
var base_passive: float

# >>> EDITÁVEL: texto que aparece no popup do "?" na tela de itens.
var description: String = ""

# >>> EDITÁVEL: cliques pra avançar caso um item seja criado sem esse valor.
# (Na prática isso já é definido na lista de itens do Main.gd.)
var clicks_to_advance: int = 200

var icon: Texture2D
var animation_set: Dictionary = {}
var upgrades: Array = []
var unlocked: bool = false

func _init(p_name: String, p_aura: float, p_passive: float, p_clicks: int, p_icon: Texture2D = null):
	item_name = p_name
	aura_per_click = p_aura
	base_passive = p_passive
	clicks_to_advance = p_clicks
	icon = p_icon

func add_upgrade(upgrade: ItemUpgrade):
	upgrades.append(upgrade)

# NÃO MEXER (fórmula): soma o valor base do item + os bônus dos upgrades de clique.
func get_aura_per_click() -> float:
	var total = aura_per_click
	for u in upgrades:
		if u.modifier_type == "click":
			total += u.modifier * u.level
	return total

# NÃO MEXER (fórmula): soma o ganho passivo base + os bônus dos upgrades passivos.
func get_passive_gain() -> float:
	var total = base_passive
	for u in upgrades:
		if u.modifier_type == "passive":
			total += u.modifier * u.level
	return total
