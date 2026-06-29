extends Area2D

var floating_text_scene = preload("res://scenes/floating_text.tscn")
var click_timer: float = 0.0

# >>> EDITÁVEL: tempo (em segundos) que o personagem fica na animação de clique
# antes de voltar pro frame parado (Idle). Maior = segura a animação por mais tempo.
var click_timeout: float = 1.0

var is_clicking: bool = false
@onready var main = get_node("/root/Main")
@onready var sprite = $AnimatedSprite2D

# Posição de descanso fixa do sprite e a transição em andamento.
# Guardamos o Y de descanso uma vez só pra que transições interrompidas
# nunca leiam uma posição "no meio do caminho" como se fosse o repouso.
var rest_y: float
var transition_tween: Tween

func _ready():
	input_pickable = true
	connect("input_event", _on_input_event)
	main.item_changed.connect(_on_item_changed)
	rest_y = sprite.position.y
	sprite.stop()
	call_deferred("update_sprite_state")

func _process(delta):
	if is_clicking:
		click_timer += delta
		if click_timer >= click_timeout:
			is_clicking = false
			sprite.frame = 0

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var item = main.get_current_item()
		main.on_click()

		var ft = floating_text_scene.instantiate()
		ft.text = "+" + str(snapped(main.get_click_value(), 0.001)) + " Aura"
		ft.global_position = get_global_mouse_position()
		main.add_child(ft)

		# HypeBeast tem animação automática (play/loop), então o clique só conta
		# a aura — não avançamos frames manualmente pra não brigar com ela.
		if item.item_name == "HypeBeast":
			return

		is_clicking = true
		click_timer = 0.0

		var total_frames = sprite.sprite_frames.get_frame_count(sprite.animation)

		if total_frames > 1:
			var loop_start = 1

			# >>> EDITÁVEL: por item, em qual frame o ciclo de clique recomeça.
			# Use 0 se a animação de clique do item incluir o frame parado; caso contrário, 1.
			match item.item_name:
				"67":
					loop_start = 1
				"Mewing":
					loop_start = 1
				"Gloving", "Academia", "Hype Beast":
					loop_start = 0

			var next_frame = sprite.frame + 1
			if next_frame >= total_frames:
				next_frame = loop_start

			sprite.frame = next_frame

func update_sprite_state():
	var anim = main.get_current_item().item_name
	# Itens sem animação própria (ex.: Gloving, Hype Beast) mantêm a animação
	# atual em vez de quebrar com "Animation doesn't exist". Assim que existir
	# uma animação com o nome do item no SpriteFrames, ela passa a ser usada.
	if sprite.sprite_frames.has_animation(anim):
		sprite.animation = anim
		sprite.frame = 0
		# HypeBeast cicla sozinho entre os 3 frames; os demais itens só avançam
		# frame no clique, então ficam parados (stop) esperando o input.
		if anim == "HypeBeast":
			sprite.play()
		else:
			sprite.stop()

func _on_item_changed(_new_index: int):
	# Interrompe qualquer transição anterior e remove sprites duplicados que
	# tenham sobrado, pra não acumular cópias nem corromper a posição de repouso.
	if transition_tween and transition_tween.is_valid():
		transition_tween.kill()
	for child in get_children():
		if child != sprite and child is AnimatedSprite2D:
			child.queue_free()

	# Cópia do item ANTERIOR (descansando em rest_y), que vai sair deslizando.
	var old_sprite = sprite.duplicate()
	add_child(old_sprite)
	old_sprite.position.y = rest_y

	update_sprite_state()

	var offset_y = get_viewport_rect().size.y
	sprite.position.y = rest_y + offset_y

	transition_tween = create_tween().set_parallel(true)
	transition_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	transition_tween.tween_property(old_sprite, "position:y", rest_y - offset_y, 0.4)
	transition_tween.tween_property(sprite, "position:y", rest_y, 0.4)

	transition_tween.chain().tween_callback(old_sprite.queue_free)
