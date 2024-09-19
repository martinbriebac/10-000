extends Node2D

var dice_faces = []
var current_face = 0
var is_rolling = false
var roll_speed = 0.05
var roll_duration = 1.0
var roll_timer = 0.0


signal roll_completed(value)

func _ready():
	# Load dice face textures
	for i in range(1, 7):
		dice_faces.append(load("res://art/dice_face_" + str(i) +".png"))
	
	# Set initial face
	$Sprite2D.texture = dice_faces[0]

func _process(delta):
	if is_rolling:
		roll_timer += delta
		if roll_timer >= roll_speed:
			roll_timer = 0
			current_face = (current_face+1) % 6
			$Sprite2D.texture = dice_faces[current_face]
		
		if roll_timer >= roll_duration:
			is_rolling = false
			emit_signal("roll_completed", current_face + 1)

func roll(final_value):
	is_rolling = true
	roll_timer = 0.0
	current_face = final_value - 1   # Adjust for 0-based array index
