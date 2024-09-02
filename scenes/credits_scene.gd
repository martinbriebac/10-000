extends Control

func _ready():
	# Fade in the credits scene
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1, 1).set_ease(Tween.EASE_IN_OUT)
	tween.play()
