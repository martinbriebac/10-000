extends Control

func _ready():
	# Fade in the credits scene
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1, 1).set_ease(Tween.EASE_IN_OUT)
	tween.play()
	
	$Back.connect("pressed", Callable(self, "_on_back_pressed"))



func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/setup_scene.tscn")

