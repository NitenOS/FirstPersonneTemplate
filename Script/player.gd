extends CharacterBody3D

# Camera component
@onready var head : Node3D = $head
@onready var neck : Node3D = $head/neck
@onready var eyes: Node3D = $head/neck/eyes
@onready var camera : Camera3D = $head/neck/eyes/Camera3D

# Raycast component
@onready var rcUpView: RayCast3D = $RC_Up_View
@onready var rcCenterView: RayCast3D = $RC_Center_View

# Usefull Component
@onready var csStandup : CollisionShape3D = $CS_Standup
@onready var csCrouch : CollisionShape3D = $CS_Crouch
@onready var rcUpCrouch: RayCast3D = $RC_UpCrouch
@onready var animationPlayer: AnimationPlayer = $head/neck/eyes/AnimationPlayer


@export var standupCamera : float = 1.7
@export var crouchCamera : float = 1.2

# General var
var isGrounded : bool = false

# Stairs moving component
@onready var scStairs: ShapeCast3D = $SC_Stairs
@onready var rcStairsAhead: RayCast3D = $RC_Stairs_Ahead
@onready var rcStairsBelow: RayCast3D = $RC_Stairs_Below
const MAX_STEP_HEIGHT = 0.5
var snappedToStairsLastFrame : bool = false
var lastFrameWasOnFloor : float = -INF

# Speed var
var currentSpeed : float = 5.0
const NORMAL_SPEED : float = 5.0
const CROUCH_SPEED : float = 3.0
const SPRINT_SPEED : float = 8.0
const JUMP_VELOCITY : float = 4.5

# Input var
var lerpSpeed : float = 10.0
var airLerpSpeed : float = 3.0
var direction := Vector3.ZERO
const MOUSE_SENS : float = 0.2

# Slide var
@onready var timerSlide: Timer = $Timer_Slide
var slideVector := Vector2.ZERO
const SLIDE_SPEED : float = 10.0
var isSliding : bool = false

# Head bobbing var
const HEAD_BOBBING_SPRINTING_SPEED : float = 22.0
const HEAD_BOBBING_WALKING_SPEED : float = 14.0
const HEAD_BOBBING_CROUCHING_SPEED : float = 10.0

const HEAD_BOBBING_SPRINTING_INTENSITY : float = 0.2
const HEAD_BOBBING_WALKING_INTENSITY : float = 0.1
const HEAD_BOBBING_CROUCHING_INTENSITY : float = 0.05

var headBobbingVector = Vector2.ZERO
var headBobbingIndex : float = 0.0
var headBobbingCurrentIntensity : float = 0.0

# Climb var
var canClimbing : bool = false
var isClimbing : bool = false

# State 
var isWalking : bool = false
var isCrouching : bool = false
var isSprinting : bool = false

func _physics_process(delta: float) -> void:
	
	# Getting Input Movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Add the gravity.
	if not is_on_ground():
		velocity += get_gravity() * delta
		
	# Climb Logic
	if rcCenterView.is_colliding() and !rcUpView.is_colliding():
		canClimbing = true
		if Input.is_action_just_pressed("jump"):
			var tempLandingPosition :Vector3 = position + Vector3(rcUpView.target_position.x, rcUpView.target_position.y + 2.7, rcUpView.target_position.z)
			_climb_animation(tempLandingPosition)
			pass
		DebugLayer.debugText = str("Tu peut grimper")
		#print("Tu peut grimper")
	else:
		canClimbing = false
		DebugLayer.debugText = str("Tu peut PAS grimper")

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_ground() and !canClimbing:
		animationPlayer.play("jump")
		velocity.y = JUMP_VELOCITY
		isSliding = false
		
	if velocity.y < -4:
		animationPlayer.play("landing")
		
		# States logic
	# Crouch logic
	if Input.is_action_pressed("crouch") and is_on_ground():
		currentSpeed = lerp(currentSpeed, CROUCH_SPEED, delta * lerpSpeed)
		head.position.y = lerp(head.position.y, crouchCamera, delta*lerpSpeed)
		csStandup.disabled = true
		csCrouch.disabled = false
		
		# Slide begin logic
		if isSprinting and input_dir != Vector2.ZERO and is_on_ground():
			isSliding = true
			timerSlide.start()
			slideVector = input_dir
			print("Slide begin")
			pass
		
		isWalking = false
		if is_on_ground(): isSprinting = false
		isCrouching = true
	
	# Sprint logic begin
	elif Input.is_action_pressed("sprint") and !rcUpCrouch.is_colliding():
		currentSpeed = lerp(currentSpeed, SPRINT_SPEED, delta * lerpSpeed)
		head.position.y = lerp(head.position.y, standupCamera, delta*lerpSpeed)
		csStandup.disabled = false
		csCrouch.disabled = true
		
		isWalking = false
		isSprinting = true
		isCrouching = false
		
	# Walking logic
	elif !Input.is_action_pressed("sprint") and !Input.is_action_pressed("crouch") and !rcUpCrouch.is_colliding() and is_on_ground():
		head.position.y = lerp(head.position.y, standupCamera, delta*lerpSpeed)
		csStandup.disabled = false
		csCrouch.disabled = true

		currentSpeed = lerp(currentSpeed, NORMAL_SPEED, delta * lerpSpeed)
		
		isWalking = true
		isSprinting = false
		isCrouching = false
		
	# Slide logic end
	if isSliding and timerSlide.is_stopped():
		isSliding = false
		print("slide end")
		pass
		
	# Headbob logic
	if isSprinting:
		headBobbingCurrentIntensity = HEAD_BOBBING_SPRINTING_INTENSITY
		headBobbingIndex += HEAD_BOBBING_SPRINTING_SPEED * delta
	elif isWalking:
		headBobbingCurrentIntensity = HEAD_BOBBING_WALKING_INTENSITY
		headBobbingIndex += HEAD_BOBBING_WALKING_SPEED * delta
	elif isCrouching:
		headBobbingCurrentIntensity = HEAD_BOBBING_CROUCHING_INTENSITY
		headBobbingIndex += HEAD_BOBBING_CROUCHING_SPEED * delta
		
	if is_on_ground() and !isSliding and input_dir != Vector2.ZERO:
		headBobbingVector.y = sin(headBobbingIndex)
		headBobbingVector.x = sin(headBobbingIndex/2) + 0.5
		
		eyes.position.y = lerp(eyes.position.y, headBobbingVector.y * (headBobbingCurrentIntensity/2.0), delta*lerpSpeed)
		eyes.position.x = lerp(eyes.position.x, headBobbingVector.x * headBobbingCurrentIntensity, delta*lerpSpeed)
		
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta*lerpSpeed)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta*lerpSpeed)
		
	# Lean logic
	var leanDirection = float(Input.is_action_pressed("lean_right")) - float(Input.is_action_pressed("lean_left"))
	neck.position.x = lerp(neck.position.x, 0.5 * leanDirection, delta * lerpSpeed)
	neck.rotation.z = lerp(neck.rotation.z, deg_to_rad(-22 * leanDirection), lerpSpeed * delta)
		
	# Direction movement logic
	if is_on_ground():
		direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * lerpSpeed)
	else:
		if input_dir != Vector2.ZERO:
			direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), delta * airLerpSpeed)
	
	if isSliding: 
		direction = (transform.basis * Vector3(slideVector.x, 0, slideVector.y)).normalized()
		currentSpeed = (timerSlide.time_left + 0.1) * SLIDE_SPEED
	
	if direction:
		velocity.x = direction.x * currentSpeed
		velocity.z = direction.z * currentSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, currentSpeed)
		velocity.z = move_toward(velocity.z, 0, currentSpeed)

	# Stairs logic v1
	#scStairs.global_position.x = global_position.x + velocity.x * delta
	#scStairs.global_position.z = global_position.z + velocity.z * delta
	#
	#if is_on_ground():
		#scStairs.target_position.y = -1
	#else:
		#scStairs.target_position.y = -0.45
		#
	#var query = PhysicsShapeQueryParameters3D.new()
	#query.exclude = [self]
	#query.shape = scStairs.shape
	#query.transform = scStairs.global_transform
	#var result = get_world_3d().direct_space_state.intersect_shape(query, 1)
	#if !result:
		#scStairs.force_shapecast_update()
	#DebugLayer.debugText = str(bool(!result)) + str("\r")
	#
	#if scStairs.is_colliding() and velocity.y <= 0.0 and !result:
		#global_position.y = scStairs.get_collision_point(0).y
		#velocity.y = 0.0
		#isGrounded = true
	#else:
		#isGrounded = false
		
		
	# Stairs logic v2
	if is_on_floor(): lastFrameWasOnFloor = Engine.get_physics_frames()
	
	if not _snap_up_stairs_check(delta):
		move_and_slide()
		_snap_down_to_stairs_check()
	
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

# Réecriture de la fonction "is_on_floor()" pour pouvoir définir manuellement quand le personnage est au sol
func is_on_ground() -> bool:
	return isGrounded or is_on_floor()
	
# Check si l'angle du sol est plus grand ou non que la limite fixé
func is_surface_too_steep(normal : Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > self.floor_max_angle

func _run_body_test_motion(from: Transform3D, motion: Vector3, result = null) -> bool:
	if not result: result = PhysicsTestMotionResult3D.new()
	var params = PhysicsTestMotionParameters3D.new()
	params.from = from
	params.motion = motion
	return PhysicsServer3D.body_test_motion(self.get_rid(), params, result)

# Test le déplacement du joueur puis le déplace (-verticalement) si une plateforme (floor) est présente
func _snap_down_to_stairs_check() -> void:
	var didSnap : bool = false
	var wasOnFloorLastFrame : bool = Engine.get_physics_frames() - lastFrameWasOnFloor == 1
	var floorBelow : bool = rcStairsBelow.is_colliding() and not is_surface_too_steep(rcStairsBelow.get_collision_normal())
	if not is_on_floor() and velocity.y <= 0.0 and (wasOnFloorLastFrame or snappedToStairsLastFrame) and floorBelow:
		var bodyTestResult = PhysicsTestMotionResult3D.new()
		if _run_body_test_motion(self.global_transform, Vector3(0, -MAX_STEP_HEIGHT, 0), bodyTestResult):
			var translateY = bodyTestResult.get_travel().y
			self.position.y += translateY
			apply_floor_snap()
			didSnap = true
	snappedToStairsLastFrame = didSnap

func _snap_up_stairs_check(delta) -> bool:
	if not is_on_floor() and not snappedToStairsLastFrame : return false
	var expectedMoveMotion : Vector3 = self.velocity * Vector3(1, 0, 1) * delta
	var stepPosWithClearance : Transform3D = self.global_transform.translated(expectedMoveMotion + Vector3(0, MAX_STEP_HEIGHT * 2, 0))
	
	var downCheckResult = PhysicsTestMotionResult3D.new()
	var cnd1 : bool = _run_body_test_motion(stepPosWithClearance, Vector3(0, -MAX_STEP_HEIGHT * 2, 0), downCheckResult)
	if downCheckResult.get_collision_count() == 0: return false #Juste une vérification pour être certain qu'une collision à bien eu lieu
	var cnd2 : bool = downCheckResult.get_collider().is_class("StaticBody3D") or downCheckResult.get_collider().is_class("CSGShape3D") or downCheckResult.get_collider().is_class("CSGBox3D") 
	if cnd1 and cnd2:
		var stepHeight : float = ((stepPosWithClearance.origin + downCheckResult.get_travel()) - self.global_position).y
		
		if stepHeight > MAX_STEP_HEIGHT or stepHeight <= 0.01 or (downCheckResult.get_collision_point() - self.global_position).y > MAX_STEP_HEIGHT : return false
		rcStairsAhead.global_position = downCheckResult.get_collision_point() + Vector3(0, MAX_STEP_HEIGHT, 0) + expectedMoveMotion.normalized() * 0.1
		rcStairsAhead.force_raycast_update()
		if rcStairsAhead.is_colliding() and not is_surface_too_steep(rcStairsAhead.get_collision_normal()):
			self.global_position = stepPosWithClearance.origin + downCheckResult.get_travel()
			apply_floor_snap()
			snappedToStairsLastFrame = true
			return true
	return false

# Crée une animation d'escalade et déplace le joueur au point "placeToClimb"
func _climb_animation(placeToClimb : Vector3) -> void:
	isClimbing = true
	
	var verticalClimb := Vector3(global_transform.origin.x, placeToClimb.y, global_transform.origin.z)
	var verticalTween : Tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	verticalTween.tween_property(self, "global_transform:origin", verticalClimb, 0.4)
	
	await verticalTween.finished
	
	var forwardClimb : Vector3 = global_transform.origin + (-self.basis.z * 1.2)
	var forwardTween : Tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	forwardTween.tween_property(self, "global_transform:origin", forwardClimb, 0.3)
	
	await forwardTween.finished
	
	isClimbing = false
	pass
