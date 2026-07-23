extends Label


var velocity = -100.0

func _process(delta):
	position.y += velocity * delta
	modulate.a -= 2.0 * delta
	
	
	if modulate.a <= 0:
		queue_free()
