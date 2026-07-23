extends Node

# Autoload "Economy" — dona da moeda do jogo (a aura) e da renda passiva.
# Estado GLOBAL e SINGULAR: existe uma economia só, com muitos consumidores
# (HUD, loja de itens, loja de upgrades, clique do personagem). Em vez de todo
# mundo mexer em `main.aura`, mexem AQUI, e quem se importa escuta os signals.

# Emitidos quando o estado muda; o HUD e as telas escutam.
signal aura_changed(value: float)
signal income_changed(value: float)

var aura: float = 0.0
var aura_per_second: float = 0.0

# Soma aura (clique, bônus de mogador no futuro, etc.). Evento discreto -> emite.
func add_aura(amount: float) -> void:
	aura += amount
	aura_changed.emit(aura)

# Tenta gastar. Retorna false SEM gastar nada se não tiver o suficiente.
func spend(amount: float) -> bool:
	if aura < amount:
		return false
	aura -= amount
	aura_changed.emit(aura)
	return true

# Define a aura direto (load do save / reset pós-wipe).
func set_aura(value: float) -> void:
	aura = value
	aura_changed.emit(aura)

# Define a renda passiva/s (recalculada quando itens/upgrades mudam de produção).
func set_income(value: float) -> void:
	aura_per_second = value
	income_changed.emit(aura_per_second)

# Renda passiva pingando por frame. Só emite quando a parte INTEIRA muda, pra
# não disparar o HUD 60x por segundo à toa (era essa a otimização no main antigo).
func _process(delta: float) -> void:
	if aura_per_second > 0.0:
		var before := int(aura)
		aura += aura_per_second * delta
		if int(aura) != before:
			aura_changed.emit(aura)
