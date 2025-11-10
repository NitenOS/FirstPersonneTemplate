extends CharacterBody3D

@onready var head : Node3D = $head
@onready var neck : Node3D = $head/neck
@onready var camera : Camera3D = $head/neck/Camera3D

@onready var csStandup : CollisionShape3D = $CS_Standup
@onready var csCrouch : CollisionShape3D = $CS_Crouch
@onready var rcUpCrouch: RayCast3D = $RC_UpCrouch


@export var standupCamera = 1.7
@export var crouchCamera = 1.2

const JUMP_VELOCITY : float = 2.5
const MOUSE_SENS : float = 0.2

# Speed var
var currentSpeed : float = 5.0
const NORMAL_SPEED : float = 5.0
const CROUCH_SPEED : float = 3.0
const SPRINT_SPEED : float = 8.0

var lerpSpeed = 10.0
var direction := Vector3.ZERO

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_pressed("sprint") and !rcUpCrouch.is_colliding():
		currentSpeed = SPRINT_SPEED
		head.position.y = lerp(head.position.y, standupCamera, delta*lerpSpeed)
		csStandup.disabled = false
		csCrouch.disabled = true
	elif Input.is_action_pressed("crouch"):
		currentSpeed = CROUCH_SPEED
		head.position.y = lerp(head.position.y, crouchCamera, delta*lerpSpeed)
		csStandup.disabled = true
		csCrouch.disabled = false
	elif !Input.is_action_pressed("sprint") and !Input.is_action_pressed("crouch") and !rcUpCrouch.is_colliding():
		head.position.y = lerp(head.position.y, standupCamera, delta*lerpSpeed)
		csStandup.disabled = false
		csCrouch.disabled = true

		currentSpeed = NORMAL_SPEED

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerpSpeed)
	if direction:
		velocity.x = direction.x * currentSpeed
		velocity.z = direction.z * currentSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, currentSpeed)
		velocity.z = move_toward(velocity.z, 0, currentSpeed)

	move_and_slide()

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseButton:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		pass
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		pass
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENS))
			head.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENS))
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

			pass
		pass
	pass
