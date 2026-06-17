extends Control

@onready var new_game_btn = $CenterContainer/VBoxContainer/NewGameBtn
@onready var continue_btn = $CenterContainer/VBoxContainer/ContinueBtn

func _ready():
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	
	if not FileAccess.file_exists("user://save.dat"):
		continue_btn.visible = false

func _on_new_game():
	new_game_btn.text = "Loading..."
	new_game_btn.disabled = true
	SaveManager.delete_save()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_continue():
	continue_btn.text = "Loading..."
	continue_btn.disabled = true
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://scenes/main.tscn")
