class_name ItemUpgrade

var upgrade_name: String
var cost: int
var base_cost: int
var level: int = 0

# >>> EDITÁVEL: nível máximo do upgrade. Deixe -1 pra ser ilimitado,
# ou coloque um número (ex: 10) pra travar a compra naquele nível.
var max_level: int = -1

# ============================================================
# "Bag" de efeitos: { CHAVE_DO_STAT : quanto soma POR NÍVEL }.
#   Ex.: { "click": 0.143, "passive": 1.0 }
#
# Pra criar um TIPO NOVO de stat, é só usar uma chave nova aqui — esta
# classe NÃO precisa mudar. O que precisa saber do stat novo é:
#   1) quem CONSOME ele (ex.: item.gd lê "click" e "passive");
#   2) STAT_LABELS abaixo, pra ele aparecer bonito no popup de info.
# ============================================================
var effects: Dictionary = {}

# >>> EDITÁVEL: nome bonito de cada stat, usado no popup de info.
# Chave nova sem label aqui aparece com o próprio nome da chave.
const STAT_LABELS := {
	"click": "Aura por clique",
	"passive": "Ganho passivo/s",
}

func _init(p_name: String, p_cost: int, p_effects: Dictionary):
	upgrade_name = p_name
	cost = p_cost
	base_cost = p_cost
	effects = p_effects

# Quanto este upgrade soma num stat, JÁ considerando o nível atual.
func total_for(key: String) -> float:
	return float(effects.get(key, 0.0)) * level

# Texto de stats pro popup de info (lê todos os efeitos do upgrade).
# Mostra o ganho POR NÍVEL e, se já comprado, o total acumulado.
func describe() -> String:
	var lines: Array = []
	for key in effects:
		var label: String = STAT_LABELS.get(key, key)
		var per_level = effects[key]
		var line = "+" + str(per_level) + " " + label + " por nível"
		if level > 0:
			line += "  (atual: +" + str(snapped(total_for(key), 0.001)) + ")"
		lines.append(line)
	return "\n".join(lines)

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
