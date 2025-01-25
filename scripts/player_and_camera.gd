extends CharacterBody3D

# Constants and variables
const MIN_PITCH = -1.35
const MAX_PITCH = 1.35
const BOB_FREQUENCY = 24  # Frequency of the camera bob (higher = faster bobbing)
const BOB_AMPLITUDE = 0.03  # Amplitude of the bob (how much the camera moves up and down)
const FALL_MULTIPLIER = 2.5  # Multiplier to make falling faster
const SPRINT_MULTIPLIER = 1.5  # Speed multiplier when sprinting

@export_range(1.0, 30.0) var speed: float = 5.0
@export_range(2.0, 10.0) var jump_velocity: float = 10
@export_range(1.0, 5.0) var mouse_sensitivity: float = 3.0
@export_range(1.0, 10.0) var ground_acceleration: float = 4.0
@export_range(0.0, 5.0) var air_acceleration: float = 0.5
@export_range(5.0, 50.0) var gravity: float = 15.0  # Increased gravity for faster falling


var mouse_motion: Vector2 = Vector2.ZERO
var pitch: float = 0.0
var bob_timer: float = 0.0  # Timer to track bobbing

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot.get_node_or_null("Camera")  # Use get_node_or_null for safety

func _ready():
	if not camera:
		push_error("Camera node not found under CameraPivot! Check your scene structure.")

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta * FALL_MULTIPLIER
	else:
		velocity.y = 0  # Reset vertical velocity when on the ground

	# Handle jumping
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get movement input
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var target_velocity = Vector3.ZERO

	if direction != Vector3.ZERO:
		# Only apply sprint multiplier if moving forward (z > 0)
		var current_speed = speed
		if Input.is_action_pressed("sprint") and direction.z > 0:  # Sprint only when moving forward
			current_speed *= SPRINT_MULTIPLIER
		target_velocity = direction * current_speed

	# Smooth movement using manual linear interpolation
	var acceleration = ground_acceleration if is_on_floor() else air_acceleration
	if direction.length() > 0:
		velocity.x = velocity.x + (target_velocity.x - velocity.x) * acceleration * delta
		velocity.z = velocity.z + (target_velocity.z - velocity.z) * acceleration * delta
	else:
		# Apply strong deceleration when stopping
		var deceleration = ground_acceleration * 2.0 if is_on_floor() else air_acceleration
		velocity.x = velocity.x + (0 - velocity.x) * deceleration * delta
		velocity.z = velocity.z + (0 - velocity.z) * deceleration * delta

	# Move the character
	move_and_slide()

	# Handle camera and mouse movement
	_handle_mouse_look(delta)

	# Handle camera bopping
	_handle_camera_bob(delta, direction)

func _handle_mouse_look(_delta):
	# Rotate the player horizontally
	rotate_y(-mouse_motion.x * mouse_sensitivity / 1000)

	# Adjust pitch for vertical camera movement
	pitch -= mouse_motion.y * mouse_sensitivity / 1000
	pitch = clamp(pitch, MIN_PITCH, MAX_PITCH)
	if camera_pivot:
		camera_pivot.rotation.x = pitch

	# Reset mouse motion
	mouse_motion = Vector2.ZERO

func _handle_camera_bob(delta, direction):
	if is_on_floor() and direction.length() > 0.1:  # Only bob when moving and on the ground
		bob_timer += delta * BOB_FREQUENCY
		var bob_offset = sin(bob_timer) * BOB_AMPLITUDE
		if camera_pivot:
			camera_pivot.position.y = bob_offset
	else:
		# Reset bobbing instantly when not moving
		bob_timer = 0.0
		if camera_pivot:
			camera_pivot.position.y = 0.0

func _input(event: InputEvent):
	# Store mouse motion for camera rotation
	if event is InputEventMouseMotion:
		mouse_motion = event.relative
		
