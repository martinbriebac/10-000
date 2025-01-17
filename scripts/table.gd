extends Node2D

var rng = RandomNumberGenerator.new()
var dice_values = []
var players: Array[Player] = []
var current_player_index = 0
var throw_score = 0
var available_dice = 6
var hot_dice = false
var turn_score = 0
var dice_instances = []
var rolls_completed = 0
var dice_scene = preload("res://scenes/die.tscn")

const TARGET_SCORE = 10000
const INITIAL_THRESHOLD = 750
const MIN_PLAYERS = 2
const MAX_PLAYERS = 4


class Player:
	var name: String
	var score: int
	var on_scoreboard: bool
	func _init(player_name: String):
		name = player_name
		score = 0
		on_scoreboard = false

func _ready():
	
	# Set the window size
	get_window().size = Vector2(1280, 720)
	
	# Center the window on the screen
	var screen_size = DisplayServer.screen_get_size()
	var window_size = get_window().size
	get_window().position = (screen_size - window_size) / 2
	
	# Set content scaling mode
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	get_window().content_scale_size = Vector2i(1280, 720)
	
	get_window().size_changed.connect(_on_window_size_changed)
	
	rng.randomize()
	$ThrowButton.pressed.connect(_on_ThrowButton_pressed)
	$KeepScoreButton.pressed.connect(_on_KeepScoreButton_pressed)
	$KeepScoreButton.hide()
	setup_game()
	
	# Create dice instances but keep them invisible
	for i in range(6):
		var die = preload("res://scenes/die.tscn").instantiate()
		die.position = get_node("DiePosition" + str(i+1)).position
		add_child(die)
		dice_instances.append(die)
		die.connect("roll_completed", Callable(self, "_on_die_roll_completed"))
		var _connection_result = die.connect("roll_completed", func(): _on_dice_roll_completed(i))
		die.visible = false # Start with dice invisible

func _on_window_size_changed():
	var new_size = get_window().size
	var scale = min(new_size.x / 1280.0, new_size.y / 720.0)
	get_window().content_scale_size = Vector2i(1280, 720)
	get_window().content_scale_factor = scale

func _unhandled_input(event):
	if event.is_action_pressed("throw_dice") and $ThrowButton.visible:
		_on_ThrowButton_pressed()

func setup_game():
	var num_players = int(get_node("NumPlayersSpinBox").value)
	if num_players < MIN_PLAYERS or num_players > MAX_PLAYERS:
		printerr("Invalid number of players. Please select between %d and %d players." % [MIN_PLAYERS, MAX_PLAYERS])
		return
	$HotDiceSprite.hide()
	$NeedMorePoints.hide()
	
	players.clear()
	for i in range(num_players):
		players.append(Player.new("Player " + str(i+1)))
	update_display()

func _on_ThrowButton_pressed():
	if players.is_empty():
		printerr("Game not properly set up. Please set up the game first.")
		return
	
	$DiceLabel.hide()
	throw_dice()
	$NeedMorePoints.hide()
	$ThrowButton.hide()
	$KeepScoreButton.hide()

func throw_dice():
	dice_values.clear()
	rolls_completed = 0
	
	for i in range(available_dice):
		var die = dice_instances[i]
		die.visible = true
		var roll_value = randi_range(1, 6)
		dice_values.append(roll_value)
		die.start_rolling(roll_value)
	
	# Hide unused dice
	for i in range(available_dice, 6):
		dice_instances[i].visible = false
	
	# Disable throw button during roll
	$ThrowButton.disabled = true
	

@warning_ignore("unused_parameter")
func _on_dice_roll_completed(die_index):
	rolls_completed += 1
	
	# Check if all dice have finished rolling
	if rolls_completed == available_dice:
		print("All dice have finished rolling. Dice values: ", dice_values)
		var result = calculate_score()
		throw_score = result[0]
		var instant_win = result[1]
	
		if instant_win:
			print("Instant win! " + players[current_player_index].name + " rolled six of a kind!")
			end_game(true)
		elif throw_score == 0:
			print("No scoring dice. Turn score lost!")
			end_turn(true)
		else:
			turn_score += throw_score
			print("Current turn score: " + str(turn_score))
			update_display()
			$KeepScoreButton.show()
			if hot_dice:
				$HotDiceSprite.show()
				print("Hot dice! You can throw all 6 dice again!")
			
		# Re-enable throw button if there are available dice
		if available_dice > 0:
			$ThrowButton.disabled = false
			$ThrowButton.show()
		else:
			$ThrowButton.hide()
		
		$KeepScoreButton.show()
		update_display()

func _on_KeepScoreButton_pressed():
	if players.is_empty() or current_player_index >= players.size():
		printerr("Invalid game state. Please restart the game.")
		return

	var current_player = players[current_player_index]

	if not current_player.on_scoreboard and turn_score < INITIAL_THRESHOLD:
		print(current_player.name + " needs " + str(INITIAL_THRESHOLD) + " points to get on the scoreboard.")
		print("Current turn score: " + str(turn_score) + ". Keep rolling!")
		$NeedMorePoints.show()
		$KeepScoreButton.hide()
		return

	print(current_player.name + " is keeping a score of " + str(turn_score))
	
	if not current_player.on_scoreboard and turn_score >= INITIAL_THRESHOLD:
		current_player.on_scoreboard = true
		current_player.score += turn_score
		print(current_player.name + " is now on the scoreboard with " + str(current_player.score) + " points!")
	elif current_player.on_scoreboard:
		current_player.score += turn_score
		print(current_player.name + "'s new total score: " + str(current_player.score))

	if current_player.score >= TARGET_SCORE:
		end_game()
	else:
		end_turn(false)

func calculate_score():
	@warning_ignore("shadowed_variable")
	var throw_score = 0
	var counts = [0, 0, 0, 0, 0, 0]
	var scoring_dice = []
	var instant_win = false
	var special_rule = false # Flag for 1500-point rules
	
	# Input validation
	if dice_values.size() != available_dice:
		print("Error: Number of dice values doesn't match available dice")
		return [0, false]

	for value in dice_values:
		if value < 1 or value > 6:
			printerr("Invalid dice value: " + str(value))
			return [0, false]
		counts[value - 1] += 1

	# Check for instant win (all six dice with the same number)
	if counts.has(6):
		instant_win = true
		print("All six dice match! Instant win!")
		return [throw_score, instant_win]

	# Scoring logic for special 1500-point rules
	if counts.has(2) and counts.count(2) == 3:
		# Three pairs
		throw_score = 1500
		scoring_dice = range(6)
		special_rule = true
	elif counts.has(3) and counts.count(3) == 2:
		# Two triplets
		throw_score = 1500
		scoring_dice = range(6)
		special_rule = true
	elif counts == [1, 1, 1, 1, 1, 1]:
		# Straight from 1 to 6
		throw_score = 1500
		scoring_dice = range(6)
		special_rule = true
	
	# If no special rule is active, proceed with normal scoring
	if not special_rule:
		for i in range(6):
			if counts[i] >= 3:
				if i == 0:  # Special case for 1s
					throw_score += 1000 * pow(2, counts[i] - 3)
				else:
					throw_score += (i +1) * 100 * pow(2, counts[i] - 3)
				for j in range(counts[i]):
					scoring_dice.append(dice_values.find(i + 1, scoring_dice.size()))
	
	# Add points for single 1s and 5s
		for i in range(dice_values.size()):
			if dice_values[i] ==1 and i not in scoring_dice:
				throw_score += 100
				scoring_dice.append(i)
			elif dice_values[i] == 5 and i not in scoring_dice:
				throw_score += 50
				scoring_dice.append(i)
	
	# Hot dice logic
	hot_dice = (scoring_dice.size() == available_dice)

	if hot_dice:
		available_dice = 6
	else:
		available_dice -= scoring_dice.size()
		if available_dice < 0:
			available_dice = 6
		elif available_dice == 0:
			available_dice = 6
			hot_dice = true
	
	# Final validation
	if throw_score < 0:
		print("Error: Negative throw score calculated")
		return [0, false]
	
	print("Throw score: ", throw_score, " Available dice: ", available_dice, " Hot dice: ", hot_dice)
	
	return [throw_score, instant_win, scoring_dice]
	

func update_display():
	if dice_values.is_empty():
		$DiceLabel.text = "Dice: Not rolled yet"
	else:
		var dice_strings = dice_values.map(func(x): return str(x))
		var dice_text = ", ".join(dice_strings)
		$DiceLabel.text = "Dice: " + dice_text
	
	if players.is_empty():
		$CurrentPlayerLabel.text = "Current Player: None"
	else:
		$CurrentPlayerLabel.text = "Current Player: " + players[current_player_index].name
	
	$TurnScoreLabel.text = "Turn Score: " + str(turn_score)
	$AvailableDiceLabel.text = "Available Dice: " + str(available_dice)

	var scores_text = ""
	for player in players:
		scores_text += player.name + ": " + str(player.score) + "\n"
	$ScoresLabel.text = scores_text
	
	# Update dice visuals
	for i in range(dice_instances.size()):
		if i < dice_values.size():
			dice_instances[i].visible = true
			dice_instances[i].current_face = dice_values[i] - 1
			dice_instances[i].get_node("die_face").texture = dice_instances[i].dice_faces[dice_instances[i].current_face]
		else:
			dice_instances[i].visible = false
	
	print("Game state updated - current player: ", players[current_player_index].name, " Turn score: ", turn_score, " Available dice: ", available_dice)

func end_turn(busted: bool):
	if busted:
		print("Turn ended. No scoring dice.")
	else:
		print("Turn ended. Score kept.")

	print("Current scores:")
	for player in players:
		print(player.name, ": ", player.score)

	available_dice = 6
	turn_score = 0
	hot_dice = false
	$KeepScoreButton.hide()
	$HotDiceSprite.hide()
	
	# Hide all dice at the end of the turn
	for die in dice_instances:
		die.visible = false

	if not players.is_empty():
		current_player_index = (current_player_index + 1) % players.size()
	
	update_display()
	
	# Show throw button for the next player
	$ThrowButton.disabled = false
	$ThrowButton.show()

func end_game(instant_win: bool = false):
	if players.is_empty():
		printerr("Cannot end game. No players in the game.")
		return

	var winner = players[current_player_index]
	print("Game Over!")
	
	if instant_win:
		print(winner.name + " wins instantly by rolling six of a kind!")
	else:
		print(winner.name + " wins with " + str(winner.score) + " points!")
	
	print("Final scores:")
	for player in players:
		print(player.name, ": ", player.score)
	# Here you could add game over screen, restart option, etc.
	
	$ThrowButton.hide()
	$KeepScoreButton.hide()
	# $RestartButton.show()
