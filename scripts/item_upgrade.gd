class_name ItemUpgrade

var upgrade_name: String
var cost: int

# Compra ÚNICA: uma vez comprado, some da lista/menu de upgrades.
var purchased: bool = false

# ============================================================
# Efeitos MULTIPLICATIVOS por stat: { CHAVE_DO_STAT : multiplicador }.
#   Ex.: { "click": 2.0, "passive": 2.0 } -> dobra clique e passivo do item.
#   1.0 (ou stat ausente) = não afeta aquele stat.
#
# Pra um TIPO NOVO de efeito, use uma chave nova aqui — esta classe NÃO precisa
# mudar. O que precisa saber do efeito é:
#   1) quem CONSOME ele (ver _upgrade_multiplier em item.gd);
#   2) STAT_LABELS abaixo, pra aparecer bonito no popup de info.
# ============================================================
var effects: Dictionary = {}

# >>> EDITÁVEL: nome bonito de cada stat, usado no popup de info.
# Chave sem label aqui aparece com o próprio nome da chave.
const STAT_LABELS := {
	"click": "Aura por clique",
	"passive": "Ganho passivo/s",
}

func _init(p_name: String, p_cost: int, p_effects: Dictionary):
	upgrade_name = p_name
	cost = p_cost
	effects = p_effects

# Multiplicador que este upgrade aplica num stat (1.0 = não afeta / não comprado).
func multiplier_for(key: String) -> float:
	if not purchased:
		return 1.0
	return float(effects.get(key, 1.0))

# Texto de stats pro popup de info (lê todos os efeitos do upgrade).
func describe() -> String:
	var lines: Array = []
	for key in effects:
		var label: String = STAT_LABELS.get(key, key)
		lines.append("×" + str(effects[key]) + " " + label)
	return "\n".join(lines)

# Compra ÚNICA. Retorna true se comprou agora.
func buy(main) -> bool:
	if purchased:
		return false
	if main.aura >= cost:
		main.aura -= cost
		purchased = true
		return true
	return false
