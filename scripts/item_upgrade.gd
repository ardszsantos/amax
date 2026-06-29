class_name ItemUpgrade

var upgrade_name: String
var cost: int
var base_cost: int
var level: int = 0

# >>> EDITÁVEL: nível máximo do upgrade. Deixe -1 pra ser ilimitado,
# ou coloque um número (ex: 10) pra travar a compra naquele nível.
var max_level: int = -1

var modifier: float
var modifier_type: String

func _init(p_name: String, p_cost: int, p_modifier: float, p_type: String):
	upgrade_name = p_name
	cost = p_cost
	base_cost = p_cost
	modifier = p_modifier
	modifier_type = p_type

func buy(main) -> bool:
	if max_level != -1 and level >= max_level:
		return false
	if main.aura >= cost:
		main.aura -= cost
		level += 1
		# NÃO MEXER (fórmula): a cada nível o preço sobe.
		cost = int(base_cost * pow(1.20, level))
		return true
	return false
