extends Control

func _ready() -> void:
	var viewport = get_viewport()
	viewport.set_size(Vector2(2300, 1295))
	
	# Disconnect the button to the function
	$StartButton.disconnect("pressed", Callable(self, "_on_StartGameButton_pressed"))	
	# Connect the button to the function
	$StartButton.connect("pressed", Callable(self, "_on_StartGameButton_pressed"))
	
	# Disconnect the button to the function
	$ShowCredits.disconnect("pressed", Callable(self, "_on_CreditsButton_pressed"))
	# Connect the button to the function
	$ShowCredits.connect("pressed", Callable(self, "_on_CreditsButton_pressed"))
	
	# Dissconnect the button to the function
	$Rules.disconnect("pressed", Callable(self, "_on_RulesButton_pressed"))
	# Connect the button to the function
	$Rules.connect("pressed", Callable(self, "_on_RulesButton_pressed"))



func _on_StartGameButton_pressed():
	get_tree().change_scene_to_file("res://scenes/table.tscn")

func _on_CreditsButton_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/credits_scene.tscn")

func _on_RulesButton_pressed():
	get_tree().change_scene_to_file("res://scenes/rules_scene.tscn")
