extends CharacterBody3D
class_name Character


@onready var ai_controller: AIController3D = $AIController3D
@onready var mesh: Node3D = $Mesh

const SPEED = 10
const JUMP_VELOCITY = 8
const FACTOR = 10

var requested_movement: Vector2 = Vector2.ZERO
var requested_jump: bool = false

var initial_transformation: Transform3D

func _ready() -> void:
	initial_transformation = transform
	
	ai_controller.init(self)

func _physics_process(delta: float) -> void:
	reset_if_needed()

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta	
	
	var input_dir
	
	if ai_controller.heuristic == "human":
		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if Input.is_action_just_pressed("ui_accept"):
			try_to_jump()
		
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
	else:
		#velocity.x = lerp(velocity.x, ai_controller.move.x * SPEED, 0.3)
		#velocity.z = lerp(velocity.z, ai_controller.move.y * SPEED,  0.3)
		input_dir = requested_movement
		if requested_jump:
			try_to_jump()
		
		#region Calculates movement direction and sets animation
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			# This makes the robot appear to turn toward its movement direction
			#mesh.global_rotation.y = atan2(direction.x, direction.z)
			mesh.global_rotation.y = atan2(direction.x, direction.z)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
		#endregion
	
	move_and_slide()

func try_to_jump() -> void:
	if is_on_floor():
		velocity.y = JUMP_VELOCITY

func game_over(reward: float = 0) -> void:
	ai_controller.reward += reward
	ai_controller.needs_reset = true
	ai_controller.done = true
	
func reset() -> void:
	transform = initial_transformation
	
func reset_if_needed():
	if ai_controller.needs_reset:
		reset()
		ai_controller.reset()

func _on_timer_distance_timeout() -> void:
	#print("Current reward: ", ai_controller.reward)
	pass
