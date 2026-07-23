class_name Content

# ============================================================
# CONTEÚDO DO JOGO (itens + upgrades) — é só DADO, sem lógica.
# O main pede Content.build_items() e recebe a lista de Item pronta.
#
# Cada item:
#   name / click / passive / clicks_to_advance / base_cost  -> números do item no nível 1
#   icon               -> caminho do ícone (carregado em runtime)
#   description        -> texto do popup "?"
#   starts_unlocked    -> true só no 1º item (começa no nível 1)
#   upgrade_start_cost / upgrade_cost_mult -> escala de custo dos upgrades (PLACEHOLDER)
#   upgrades           -> lista de [ nome, descrição ] (compra única)
#
# >>> Pra editar/adicionar item ou upgrade, é AQUI. Nada de mexer no main.
# >>> Valores de efeito e custo são PLACEHOLDER (a definir com o Pedro).
# ============================================================

# Efeito placeholder aplicado a TODO upgrade: +1% no clique e no passivo do item.
# Quando os upgrades virarem efeitos específicos, cada um ganha o seu.
const UPGRADE_EFFECT := {"click": 1.01, "passive": 1.01}

const ITEMS := [
	{
		"name": "67",
		"click": 0.143, "passive": 1, "clicks_to_advance": 20, "base_cost": 50,
		"icon": "res://assets/ui/67_icone.png",
		"description": "durante seu treino você finalmente entendeu, o 67 é a verdade absoluta",
		"starts_unlocked": true,
		"upgrade_start_cost": 100, "upgrade_cost_mult": 2.0,
		"upgrades": [
			["Jingle motivador", "uma musiquinha grudenta toca na sua cabeça o dia todo. impossível parar de produzir 67."],
			["Primo João", "todo mundo tem um primo João que entende de tudo. foi ele que te revelou o segredo do 67."],
			["Federação Esportiva de Aura Farming", "agora aura farming é esporte olímpico oficial. o 67 tem federação, patrocínio e até doping."],
			["Mão de obra indiana", "terceirizou a produção de 67 pra um call center em Mumbai. barato, rápido e escalável."],
			["Mão de obra filipina", "abriu uma segunda filial em Manila. dois turnos girando, o 67 não para nunca."],
			["Fábrica de 67", "uma linha de montagem industrial cuspindo 67 em massa. fumaça preta, aura pura."],
			["Doutrinação nas escolas", "colocou o 67 na grade curricular. as crianças já nascem sabendo a verdade."],
			["Base espacial em Marte", "o 67 agora é interplanetário. até o Elon bateu o martelo e aprovou."],
			["O medo ancestral de todas as coisas", "no fundo, tudo no universo teme o 67. inclusive o próprio 67."],
			["Ascensão espiritual", "você transcendeu. o 67 deixou de ser um número e virou um estado de consciência."],
		],
	},
	{
		"name": "Mewing",
		"click": 1, "passive": 7, "clicks_to_advance": 20, "base_cost": 500,
		"icon": "res://assets/ui/mewing.png",
		"description": "língua no céu da boca. o maxilar agradece.",
		"upgrade_start_cost": 1000, "upgrade_cost_mult": 2.0,
		"upgrades": [
			["Treinar no espelho", "encara o próprio reflexo fazendo mewing por horas. o maxilar agradece, a aura também."],
			["Tutorial no canal do Primo João", "o Primo João tem um canal de mewing com 3 inscritos. um deles é você."],
			["Jogar Minecraft para se inspirar", "os blocos do Minecraft te lembram do formato ideal de mandíbula. inspiração quadrada."],
			["Amolador de facão", "afia o maxilar igual facão no rebolo. corta o vento e ganha aura."],
			["Prensa hidráulica", "prensou o rosto pra ficar mais anguloso. doeu pra caralho, mas o mewing evoluiu."],
			["Tung Tung Sahur", "o brainrot indonésio bateu na sua porta às 3 da manhã. mewing ancestral desbloqueado."],
			["Harmonização facial", "foi na clínica e voltou com um rosto de estátua grega. aura estética nas alturas."],
			["Movimento supremacista quadrado", "fundou um movimento onde só quem tem rosto quadrado tem valor. polêmico, mas rende aura."],
			["Pressão estética nas grandes mídias", "toda propaganda agora só mostra gente de queixo reto. o mundo inteiro fazendo mewing."],
			["Proibição das bolas", "baniu tudo que é redondo do planeta. só sobrou o quadrado. mewing supremo."],
		],
	},
	{
		"name": "Academia",
		"click": 7.142, "passive": 50, "clicks_to_advance": 20, "base_cost": 5000,
		"icon": "res://assets/ui/gym_icone.png",
		"description": "sem dor, sem aura. simples assim.",
		"upgrade_start_cost": 10000, "upgrade_cost_mult": 2.0,
		"upgrades": [
			["Discurso do Rocky Balboa", "'não importa o quão forte você bate, importa quanto aguenta apanhar'. lágrimas viram aura."],
			["Parceiro de treino Primo João", "o Primo João segura sua barra... e solta na hora errada. ainda assim, conta."],
			["Pagar um ano de academia e não ir", "matriculou, pagou adiantado, foi uma vez. a culpa se converte em aura passiva."],
			["Enchimentos", "colocou enchimento na roupa pra parecer mais forte. ninguém percebe, você sim."],
			["Foto no espelho", "flexiona no espelho da academia entre uma série e outra. o pump é real."],
			["TikTok no descanso entre séries", "o descanso de 3 minutos virou 40. mas o algoritmo te motivou pra caralho."],
			["Postar que o de hoje já tá pago", "story postado, treino feito na cabeça. aura garantida sem levantar peso."],
			["Phonk de IA slowed + reverb no fone", "aquele phonk que a IA fez, lento e com reverb. você vira outra pessoa no supino."],
			["Pesos do Rock Lee", "tirou as caneleiras e sua velocidade de aura farming simplesmente explodiu."],
			["Sala do Tempo do Dragon Ball", "um dia lá dentro = um ano de treino. saiu com a aura de um Super Saiyajin."],
		],
	},
	{
		"name": "HypeBeast",
		"click": 349.985, "passive": 2450, "clicks_to_advance": 20, "base_cost": 50000,
		"icon": "res://assets/ui/hyper_beast_icone.png",
		"description": "se é caro, é aura.",
		"upgrade_start_cost": 100000, "upgrade_cost_mult": 2.0,
		"upgrades": [
			["Roubar o dinheiro da vó pra roupa cara", "a vó não vai sentir falta. o drip vai. aura absurdamente cara."],
			["Contrabandear roupa com o Primo João", "o Primo João tem um esquema na alfândega. Supreme original sem imposto."],
			["Consultoria com o gordinho do outfit", "aquele mano do YouTube que destrói outfit alheio te deu 3 dicas de ouro."],
			["Tirar fotos cobrindo o rosto", "o rosto some, o outfit aparece. misterioso e estiloso na medida."],
			["Entrar numa gang pelo estilo", "não é pelo crime, é pela estética coordenada. aura de bando uniformizado."],
			["Comprar um tijolo da Supreme", "sim, um tijolo de verdade com a logo. custou uma fortuna. o ápice do drip."],
			["Dormir na fila do drop", "48 horas na calçada pra ser o primeiro. os pés doem, a aura brilha."],
			["Revender tênis no Grailed por 3x", "comprou hype, vendeu bem mais caro. capitalismo puro vira aura."],
			["Corrente banhada da 25 de Março", "brilha igual ouro de verdade por duas semanas. depois enverdece, mas a aura fica."],
			["Photoshoot no estacionamento do shopping", "fundo de concreto, luz de garagem, poses de revista. o fotógrafo é o Primo João."],
		],
	},
]

# Constrói a lista de Item (com nível inicial e upgrades) a partir do dado acima.
# É o único lugar que transforma o DADO em objetos de runtime.
static func build_items() -> Array:
	var result: Array = []
	for data in ITEMS:
		var item := Item.new(
			data.name, data.click, data.passive,
			data.clicks_to_advance, data.base_cost, load(data.icon)
		)
		item.description = data.get("description", "")
		if data.get("starts_unlocked", false):
			item.level = 1
		var cost: float = data.upgrade_start_cost
		for entry in data.upgrades:
			item.add_upgrade(ItemUpgrade.new(entry[0], int(round(cost)), UPGRADE_EFFECT, entry[1]))
			cost *= data.upgrade_cost_mult
		result.append(item)
	return result
