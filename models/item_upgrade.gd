class_name ItemUpgrade

var upgrade_name: String
var cost: int

# >>> EDITÁVEL: descrição (flavor) que aparece no popup do "?" do upgrade.
var description: String = ""

# Compra ÚNICA: uma vez comprado, some da lista/menu de upgrades.
var purchased: bool = false

# ============================================================
# Efeitos MULTIPLICATIVOS por stat: { CHAVE_DO_STAT : multiplicador }.
#   Ex.: { "click": 1.01, "passive": 1.01 } -> +1% no clique e no passivo.
#        { "click": 2.0 } -> dobra só a aura por clique.
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

func _init(p_name: String, p_cost: int, p_effects: Dictionary, p_description: String = ""):
	upgrade_name = p_name
	cost = p_cost
	effects = p_effects
	description = p_description

# Multiplicador que este upgrade aplica num stat (1.0 = não afeta / não comprado).
func multiplier_for(key: String) -> float:
	if not purchased:
		return 1.0
	return float(effects.get(key, 1.0))

# Texto pro popup de info: descrição (flavor) + os efeitos em "+X%".
func describe() -> String:
	var lines: Array = []
	if description != "":
		lines.append(description)
		lines.append("")  # linha em branco separando o flavor dos stats
	for key in effects:
		var label: String = STAT_LABELS.get(key, key)
		# Multiplicador -> bônus em porcentagem (1.01 -> "+1%").
		var pct = snapped((float(effects[key]) - 1.0) * 100.0, 0.1)
		lines.append("+" + str(pct) + "% " + label)
	return "\n".join(lines)

# Compra ÚNICA. Retorna true se comprou agora.
func buy() -> bool:
	if purchased:
		return false
	if not Economy.spend(cost):
		return false
	purchased = true
	return true
