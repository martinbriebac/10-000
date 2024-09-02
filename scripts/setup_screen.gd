extends Control

# Number of players dropdown
var num_players = 1
# Music volume slider
var music_volume = 0.5

func _ready():
	var viewport = get_viewport()
	viewport.set_size(Vector2(2300, 1295))
	
	# Initialize the number of players dropdown
	$NumPlayersOptionButton.add_item("1 Player")
	$NumPlayersOptionButton.add_item("2 Players")
	$NumPlayersOptionButton.add_item("3 Players")
	$NumPlayersOptionButton.add_item("4 Players")
	$NumPlayersOptionButton.select(0)

	# Initialize the music volume slider
	$MusicVolumeHSlider.value = music_volume

func _on_NumPlayersOptionButton_item_selected(index):
	num_players = index + 1
	print("Number of players selected: ", num_players)

func _on_StartGameButton_pressed():
	# Start the game with the selected number of players
	print("Starting game with ", num_players, " players")
	# Add code to start the game here
	get_tree().change_scene("res://table.tscn")

func _on_CreditsButton_pressed():
	# Show the credits screen
	print("Showing credits screen")
	# Add code to show the credits screen here

func _on_MusicVolumeHSlider_value_changed(value):
	music_volume = value
	print("Music volume set to: ", music_volume)
	# Add code to update the music volume here
