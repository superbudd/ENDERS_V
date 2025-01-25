extends Node3D

@onready var first_person_camera: Camera3D = $Player/third_person_camera
@onready var third_person_camera: Camera3D = $Player/third_person_camera

var is_first_person = true

func _ready():
	# Start with the first-person camera active
	update_camera()

func _input(event):
	if Input.is_action_just_pressed("toggle_camera"):
		 # 'V' for toggling the view
			toggle_camera()

func toggle_camera():
	is_first_person = !is_first_person
	update_camera()

func update_camera():
	if is_first_person:
		first_person_camera.current = true
		third_person_camera.current = false
	else:
		first_person_camera.current = false
		third_person_camera.current = true
