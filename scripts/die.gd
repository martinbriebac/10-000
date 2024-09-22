extends Node2D

var dice_faces = []
var current_face = 0
var is_rolling = false
var roll_speed = 0.05
var roll_duration = 2.0
var roll_timer = 0.0
var final_value = 1

signal roll_completed

func _ready():
	# Load dice face textures
	for i in range(1, 7):
		dice_faces.append(load("res://art/dice_face_" + str(i) +".png"))
	
	# Set initial face
	$die_face.texture = dice_faces[0]

func _process(delta):
	if is_rolling:
		roll_timer += delta
		if roll_timer < roll_duration:
			# Change face rapidly during rolling
			current_face = (current_face+1) % 6
			$die_face.texture = dice_faces[current_face]
		else:
			# Stop at the final value
			print("Die roll duration exceeded, stopping roll")
			stop_rolling()
		

func start_rolling(value):
	is_rolling = true
	roll_timer = 0.0
	final_value = value
	print("Die starting to roll, target value: ", value)

func stop_rolling():
	is_rolling = false
	current_face = final_value - 1
	$die_face.texture = dice_faces[current_face]
	print("Die finished rolling, final value: ", final_value)
	emit_signal("roll_completed") # Emit the signal when rolling stops
	print("Emitting roll_completed signal")

func get_value():
	return current_face + 1

func highlight_as_scoring():
	modulate = Color(1, 0.5, 0.5) # Light red tint

func remove_highlight():
	modulate = Color(1, 1, 1) # Reset to normal color
