extends Node

# Feedback tátil em TODOS os botoes, sem configurar nada por botao.
# Registrado como autoload (ver project.godot).
#
# PENSADO PRA MOBILE/TOUCH (button_down/up disparam no toque):
#   - Dedo desce  -> encolhe um pouco (sensacao de "apertou").
#   - Dedo solta  -> volta dando um "pop" (overshoot leve) e assenta.
#
# Hover (mouse_entered/exited) so existe no DESKTOP. No celular nunca
# dispara e e ignorado -- fica aqui so pra quando VOCE testa no editor
# com mouse. Nao e o foco.

# >>> EDITÁVEL
const NORMAL_SCALE := Vector2(1.0, 1.0)
const PRESSED_SCALE := Vector2(0.9, 0.9)    # ao tocar/pressionar
const HOVER_SCALE := Vector2(1.05, 1.05)    # so desktop (testar no editor)
const DOWN_DURATION := 0.05                  # encolher ao tocar (rapido)
const UP_DURATION := 0.22                    # voltar com o "pop"

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	_wire_existing(get_tree().root)

func _wire_existing(node: Node) -> void:
	for child in node.get_children():
		_on_node_added(child)
		_wire_existing(child)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_wire(node)

func _wire(btn: BaseButton) -> void:
	if btn.has_meta("juiced"):
		return
	btn.set_meta("juiced", true)

	# Escala a partir do centro, nao do canto.
	btn.pivot_offset = btn.size / 2.0
	btn.resized.connect(func(): btn.pivot_offset = btn.size / 2.0)

	# --- TOUCH (e tambem desktop): o que importa no celular ---
	btn.button_down.connect(func(): _press(btn))
	btn.button_up.connect(func(): _release(btn))

	# --- DESKTOP-only: hover. No-op no celular ---
	btn.mouse_entered.connect(func():
		if not btn.button_pressed:
			_tween(btn, HOVER_SCALE, DOWN_DURATION, Tween.TRANS_QUAD)
	)
	btn.mouse_exited.connect(func():
		if not btn.button_pressed:
			_tween(btn, NORMAL_SCALE, DOWN_DURATION, Tween.TRANS_QUAD)
	)

func _press(btn: Control) -> void:
	_tween(btn, PRESSED_SCALE, DOWN_DURATION, Tween.TRANS_QUAD)

func _release(btn: Control) -> void:
	# Volta ao normal com leve overshoot (o "pop"/sacudida).
	_tween(btn, NORMAL_SCALE, UP_DURATION, Tween.TRANS_BACK)

func _tween(btn: Control, target: Vector2, dur: float, trans: int) -> void:
	# Mata o tween anterior pra nao competir e dar jitter.
	if btn.has_meta("scale_tween"):
		var old = btn.get_meta("scale_tween")
		if old != null and old.is_valid():
			old.kill()

	var t := btn.create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(trans)
	t.tween_property(btn, "scale", target, dur)
	btn.set_meta("scale_tween", t)
