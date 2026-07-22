class_name Item

var item_name: String
# Produção NO NÍVEL 1 (base). Escala com o nível do item.
var aura_per_click: float
var base_passive: float

# >>> EDITÁVEL: texto que aparece no popup do "?" na tela de itens.
var description: String = ""

# >>> EDITÁVEL: cliques pra avançar caso um item seja criado sem esse valor.
# (Na prática isso já é definido na lista de itens do Main.gd.)
var clicks_to_advance: int = 200

var icon: Texture2D

# --- NÍVEL DO ITEM ---
# Cada compra na tela de itens sobe 1 nível.
#   level 0 = ainda não comprado (bloqueado, produz 0)
#   level >= 1 = desbloqueado e produzindo
var level: int = 0
var base_cost: int   # custo da 1ª compra (nível 0 -> 1)
var cost: int        # custo da PRÓXIMA compra (escala com o nível)

# >>> EDITÁVEL: quanto o custo do item sobe a cada nível comprado.
const COST_GROWTH := 1.20

# Melhorias de COMPRA ÚNICA deste item (ver item_upgrade.gd).
var upgrades: Array = []

func _init(p_name: String, p_aura: float, p_passive: float, p_clicks: int, p_cost: int, p_icon: Texture2D = null):
	item_name = p_name
	aura_per_click = p_aura
	base_passive = p_passive
	clicks_to_advance = p_clicks
	base_cost = p_cost
	cost = p_cost
	icon = p_icon

# "Desbloqueado" agora é DERIVADO do nível: comprou ao menos 1 vez.
# A progressão (barra/scroll) lê isto, por isso mantemos o nome.
var unlocked: bool:
	get:
		return level >= 1

func add_upgrade(upgrade: ItemUpgrade):
	upgrades.append(upgrade)

# Multiplicador acumulado dos upgrades de compra única já comprados, por stat.
# 1.0 = nenhum upgrade afeta esse stat.
func _upgrade_multiplier(key: String) -> float:
	var m := 1.0
	for u in upgrades:
		m *= u.multiplier_for(key)
	return m

# NÃO MEXER (fórmula): produção por clique = base × nível × upgrades.
func get_aura_per_click() -> float:
	return aura_per_click * level * _upgrade_multiplier("click")

# NÃO MEXER (fórmula): ganho passivo = base × nível × upgrades.
func get_passive_gain() -> float:
	return base_passive * level * _upgrade_multiplier("passive")

# Compra o PRÓXIMO nível do item. Retorna true se deu (tinha aura).
func buy(main) -> bool:
	if main.aura >= cost:
		main.aura -= cost
		level += 1
		# NÃO MEXER (fórmula): a cada nível o preço sobe.
		cost = int(base_cost * pow(COST_GROWTH, level))
		return true
	return false
