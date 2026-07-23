extends Control

# Cena principal / COORDENADOR. Não guarda economia, progressão nem conteúdo:
# - estado e regras vivem nos autoloads Economy e Progression;
# - conteúdo (itens/upgrades) vive em data/content.gd.
# Aqui fica só: montar a tela (HUD como view que escuta signals), trocar de tela,
# pause e save.

var save_timer: float = 0.0

# >>> EDITÁVEL: de quantos em quantos segundos o jogo salva sozinho
# (também é a frequência com que o "saved ✓" aparece no canto).
const SAVE_INTERVAL: float = 30.0

@onready var home_screen = $HomeScreen
@onready var items_screen = $ItemsScreen
@onready var upgrades_screen = $UpgradesScreen
@onready var pause_menu = $PauseMenu

@onready var label_aura = $HomeScreen/MarginContainer/VBoxContainer/LabelAura
@onready var label_renda = $HomeScreen/MarginContainer/VBoxContainer/LabelRenda
@onready var progress_bar = $HomeScreen/MarginContainer/VBoxContainer/ProgressBar
@onready var item_label = $HomeScreen/MarginContainer/VBoxContainer/ItemLabel

@onready var upgrades_tab = $HomeScreen/SideButtons/HBoxContainer/UpgradesTab
@onready var favorites_tab = $HomeScreen/SideButtons/HBoxContainer/FavoritesTab
@onready var home_tab = $HomeScreen/SideButtons/HBoxContainer/HomeTab
@onready var back_btn = $ItemsScreen/BackBtn
@onready var upgrades_back_btn = $UpgradesScreen/BackBtn

@onready var resume_btn = $PauseMenu/VBoxContainer/ResumeBtn
@onready var save_btn = $PauseMenu/VBoxContainer/SaveBtn
@onready var wipe_btn = $PauseMenu/VBoxContainer/WipeBtn
@onready var save_flash = $HomeScreen/SaveFlash

# Estado do botão "Wipe Save": precisa de dois toques pra confirmar.
var wipe_armed: bool = false

func _ready():
	# O conteúdo (itens + upgrades) mora em data/content.gd. Progression é o dono
	# da lista em runtime; entregamos pronta e zeramos o estado antes de carregar
	# (autoload sobrevive ao reload de cena do wipe, então precisa reset na mão).
	Progression.items = Content.build_items()
	Progression.reset()
	Economy.set_aura(0.0)
	SaveManager.load_game()
	Progression.recalculate_income()

	upgrades_tab.pressed.connect(func(): switch_screen(items_screen))
	favorites_tab.pressed.connect(_toggle_pause)
	home_tab.pressed.connect(func(): switch_screen(upgrades_screen))
	back_btn.pressed.connect(func(): switch_screen(home_screen))
	upgrades_back_btn.pressed.connect(func(): switch_screen(home_screen))

	# O HUD é view: reage à economia (aura/renda) e à progressão (troca de item).
	Economy.aura_changed.connect(func(_v): update_hud())
	Economy.income_changed.connect(func(_v): update_hud())
	Progression.item_changed.connect(func(_i): update_hud())

	pause_menu.visible = false
	resume_btn.pressed.connect(_toggle_pause)
	save_btn.pressed.connect(_on_save)
	wipe_btn.pressed.connect(_on_wipe_save)

	update_hud()
	switch_screen(home_screen, false)
	items_screen.build_list()

# HUD é só VIEW: lê o estado do Economy e da Progression e pinta a tela.
func update_hud():
	var item = Progression.get_current_item()

	label_aura.text = str(int(Economy.aura)) + " Aura"
	label_renda.text = str(snapped(Economy.aura_per_second, 0.01)) + "/s"
	progress_bar.max_value = item.clicks_to_advance
	progress_bar.value = Progression.current_clicks

	var text = item.item_name
	if Progression.can_advance():
		text += " → " + Progression.items[Progression.current_item_index + 1].item_name
	elif Progression.current_item_index == Progression.items.size() - 1 or not Progression.items[Progression.current_item_index + 1].unlocked:
		text += " (Max)"
	item_label.text = text

func switch_screen(screen: Control, play_swipe: bool = true):
	home_screen.visible = false
	items_screen.visible = false
	upgrades_screen.visible = false
	screen.visible = true
	# Swipe na troca de tela/menu. play_swipe=false no boot (montar a tela
	# inicial não é uma transição que o jogador provocou).
	if play_swipe:
		Audio.play_sfx("swipe")

func _toggle_pause():
	pause_menu.visible = not pause_menu.visible
	# Sempre que o menu abre/fecha, desarma o "Wipe Save" pra não apagar sem querer.
	_disarm_wipe()

func _on_save():
	SaveManager.save_game()
	_flash_saved()
	save_btn.text = "Saved!"
	save_btn.disabled = true
	await get_tree().create_timer(1.5).timeout
	save_btn.text = "Save"
	save_btn.disabled = false

# Mostra um "saved ✓" discreto no canto, segura ~2s e some suave.
func _flash_saved():
	save_flash.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(save_flash, "modulate:a", 0.0, 1.0)

func _disarm_wipe():
	wipe_armed = false
	wipe_btn.text = "Wipe Save"

# Primeiro toque arma; segundo toque apaga o save e recomeça do zero.
func _on_wipe_save():
	if not wipe_armed:
		wipe_armed = true
		wipe_btn.text = "Sure? Tap again"
		return
	SaveManager.delete_save()
	get_tree().reload_current_scene()

func _process(delta):
	# A barra drena continuamente na Progression; reflete o valor a cada frame.
	progress_bar.value = Progression.current_clicks

	save_timer += delta
	if save_timer >= SAVE_INTERVAL:
		save_timer = 0.0
		SaveManager.save_game()
		_flash_saved()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		SaveManager.save_game()
		get_tree().quit()
	elif what == NOTIFICATION_APPLICATION_PAUSED:
		SaveManager.save_game()
