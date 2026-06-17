extends Area2D

var floating_text_scene = preload("res://floating_text.tscn")
var click_timer: float = 0.0

# >>> EDITÁVEL: tempo (em segundos) que o personagem fica na animação de clique
# antes de voltar pro frame parado (Idle). Maior = segura a animação por mais tempo.
var click_timeout: float = 1.0

var is_clicking: bool = false
@onready var main = get_node("/root/Main")
@onready var sprite = $AnimatedSprite2D

func _ready():
	input_pickable = true
	connect("input_event", _on_input_event)
	main.item_changed.connect(_on_item_changed)
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
		ft.text = "+" + str(item.get_aura_per_click()) + " Aura"
		ft.global_position = get_global_mouse_position()
		main.add_child(ft)

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
	sprite.animation = main.get_current_item().item_name
	sprite.frame = 0

func _on_item_changed(_new_index: int):
	var old_sprite = sprite.duplicate()
	add_child(old_sprite)

	update_sprite_state()

	var center_y = sprite.position.y
	var offset_y = get_viewport_rect().size.y

	sprite.position.y = center_y + offset_y

	var tween = create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	tween.tween_property(old_sprite, "position:y", center_y - offset_y, 0.4)
	tween.tween_property(sprite, "position:y", center_y, 0.4)

	tween.chain().tween_callback(old_sprite.queue_free)
