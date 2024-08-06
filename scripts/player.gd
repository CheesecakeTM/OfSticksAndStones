class_name PlayerController
extends CharacterBody3D

# Nodes references
@onready var animation_player = $AnimationPlayer
@onready var head = $head
@onready var camera = $head/Camera3D
@onready var ray_head = $RayCast3D

# Constants
const LERP_SPEED = 10.0
const AIR_LERP_SPEED = 3.0
const MOUSE_SENS = 0.24


# !!CAUTION!! Movement variables 
@export_group("Movement")
## The intensity of the jump. More specifically this is the player's velocity that is applied on jump.
@export_range(1, 10, 0.5) var JUMP_VELOCITY: float = 4.5
@export_subgroup("Speed")
## The speed of the player when they're 'walking' 
@export_range(1, 10, 0.5) var WALKING_SPEED: float = 5.0
## The speed of the player while they're 'crouched'
@export_range(1, 10, 0.5) var CROUCHING_SPEED: float = 3.0
## The speed of the player when they're 'sprinting'
@export_range(1, 10, 0.5) var SPRINTING_SPEED: float = 8.5

# Private movement variables
var current_speed: float = 5
var direction := Vector3.ZERO
var air_damping := 0.1

# !!CAUTION!! Headbobbing variables
@export_group("Headbobbing")
## How fast the head bobs while 'sprinting' (the movement side-to-side)
@export var HEAD_BOB_SPRINT_SPEED: float = 22.0
## How fast the head bobs while 'walking' (the movement side-to-side)
@export var HEAD_BOB_WALK_SPEED: float = 14.0
## How intensly the head bobs while 'sprinting' (the movement up-and-down)
@export var head_bob_sprint_intensity: float = 0.2
## How intensly the head bobs while 'walking' (the movement up-and-down)
@export var head_bob_walk_intensity: float = 0.1

# Headbobbing variables
var head_bob_vector := Vector2.ZERO
var head_bob_index := 0.0
var head_bob_current_intensity := 0.0

# Gravity
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Function that runs on the first frame of the node
func _ready():
	animation_player.play("RESET")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Mouse input events
func _unhandled_input(event: InputEvent) -> void:
	# Hide and un-hide the cursor
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("escape"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Handle mouse motion when hidden
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(deg_to_rad( - event.relative.x * MOUSE_SENS))
			head.rotate_x(deg_to_rad( - event.relative.y * MOUSE_SENS))
			head.rotation.x = clamp(head.rotation.x, deg_to_rad( - 79), deg_to_rad(79))

# Physics calculation
func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "back")
	
	handle_states()
	handle_in_air(delta)
	handle_crouch()
	handle_movement_modes()
	handle_headbobbing(input_dir, delta)
	handle_jump()
	move_around(input_dir, delta)
	
	# Calculate the physics
	move_and_slide()

# Handle Player States
func handle_states():
	if is_on_floor() and not StateController.is_crouching:
		StateController.is_crouching = false
		StateController.can_sprint = true
		StateController.can_jump = true

# In Air
func handle_in_air(delta):
	if !is_on_floor():
		StateController.is_sprinting = false
		StateController.can_sprint = false
		StateController.can_jump = false
		velocity.y -= gravity * delta
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed

# Crouching
func handle_crouch():
	if is_on_floor() and Input.is_action_pressed("crouch"):
		current_speed = CROUCHING_SPEED
		StateController.is_crouching = true
		StateController.can_crouch = false
		StateController.can_sprint = false
		animation_player.play("crouch")
	if Input.is_action_just_released("crouch") or StateController.is_crouching:
		if not ray_head.is_colliding():
			StateController.can_crouch = true
			StateController.can_sprint = true
			StateController.is_crouching = false
			animation_player.play_backwards("crouch")

# Movement states
func handle_movement_modes():
	if Input.is_action_pressed("crouch") and StateController.can_crouch:
		handle_crouch()
	elif Input.is_action_pressed("run") and StateController.can_sprint:
		handle_sprint()
	else:
		current_speed = CROUCHING_SPEED if StateController.is_crouching else WALKING_SPEED
		StateController.is_sprinting = false

# Sprinting
func handle_sprint():
	current_speed = SPRINTING_SPEED
	StateController.is_sprinting = true

# Headbobbing
func handle_headbobbing(input_dir, delta):
	head_bob_current_intensity = head_bob_sprint_intensity if StateController.is_sprinting else head_bob_walk_intensity
	head_bob_index += HEAD_BOB_SPRINT_SPEED * delta if StateController.is_sprinting else HEAD_BOB_WALK_SPEED * delta
	if is_on_floor()&&input_dir != Vector2.ZERO:
		head_bob_vector.y = sin(head_bob_index)
		head_bob_vector.x = sin(head_bob_index / 2) + 0.5
		camera.position.y = lerp(camera.position.y, head_bob_vector.y * (head_bob_current_intensity / 2.0), delta * LERP_SPEED)
		camera.position.x = lerp(camera.position.x, head_bob_vector.x * (head_bob_current_intensity), delta * LERP_SPEED)
	else:
		camera.position.y = lerp(camera.position.y, 0.0, delta * LERP_SPEED)
		camera.position.x = lerp(camera.position.x, 0.0, delta * LERP_SPEED)

# Jumping
func handle_jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

# Moving around 
func move_around(input_dir, delta):
	if is_on_floor():
		direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * LERP_SPEED)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * AIR_LERP_SPEED)
	velocity.x = direction.x * current_speed if direction else move_toward(velocity.x, 0, current_speed)
	velocity.z = direction.z * current_speed if direction else move_toward(velocity.z, 0, current_speed)
