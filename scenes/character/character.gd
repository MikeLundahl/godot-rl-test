extends CharacterBody3D
class_name Character

var m = preload("res://scenes/muzzle_flash.tscn")

@onready var ai_controller: AIController3D = $AIController3D
@onready var mesh: Node3D = $AIController3D/ShootRoot/Mesh
@onready var ray_cast_shoot = $AIController3D/ShootRoot/RayCastShoot
@onready var shoot_root = $AIController3D/ShootRoot
@onready var shoot_timer: Timer = $TimerShoot
@onready var sprint_label: Label3D = $Label3D

const SPEED = 10
const SPRINT_MULTIPLIER = 1.5
const JUMP_VELOCITY = 5
const FACTOR = 10
const LERP_ACCELERATION = 0.3

var requested_movement: Vector2 = Vector2.ZERO
var requested_jump: bool = false
var requested_shoot: bool = false
var requested_sprint: bool = false

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
			if requested_sprint:
				if !sprint_label.visible: sprint_label.show()
				velocity.x = lerp(velocity.x, direction.x * (SPEED * SPRINT_MULTIPLIER), LERP_ACCELERATION)
				velocity.z = lerp(velocity.z, direction.z * (SPEED * SPRINT_MULTIPLIER), LERP_ACCELERATION)
			else:
				if sprint_label.visible: sprint_label.hide()
				velocity.x = lerp(velocity.x, direction.x * SPEED, LERP_ACCELERATION)
				velocity.z = lerp(velocity.z, direction.z * SPEED, LERP_ACCELERATION)
			# This makes the robot appear to turn toward its movement direction
			#mesh.global_rotation.y = atan2(direction.x, direction.z)
			#ai_controller.raycast_sensor.global_rotation.y = atan2(direction.x, direction.z)
			shoot_root.global_rotation.y = lerp(shoot_root.global_rotation.y, atan2(direction.x, direction.z), LERP_ACCELERATION)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
		#endregion
		
		if requested_shoot:
			pass
			"""
			if shoot_timer.is_stopped():
				shoot_timer.start()
			"""
		else:
			pass
			"""
			if !shoot_timer.is_stopped():
				shoot_timer.stop()
			"""
				
	move_and_slide()

func try_to_jump() -> void:
	var did_jump: bool = false
	var does_see_obstacle: bool
	for obs in ai_controller.raycast_sensor.get_observation():
		if obs is Wall:
			does_see_obstacle = true
	
	if is_on_floor():
		did_jump = true
		velocity.y = JUMP_VELOCITY
		ai_controller.reward -= 0.1
	
	if did_jump && !does_see_obstacle:
		ai_controller.reward -= 0.5
		did_jump = false

func shoot() -> void:
	var r = RayCast3D.new()
	r.target_position = Vector3(0, 0, 30)
	r.debug_shape_thickness = 5
	ray_cast_shoot.add_child(r)
	
	var muzzle_flash = m.instantiate()
	ray_cast_shoot.add_child(muzzle_flash)
	
	if r.is_colliding():
		var hit = r.get_collider()
		if hit != null && hit is Enemy:
			print("Hit!")
			var hit_fx = m.instantiate()
			var hit_pos = r.get_collision_point()
			hit_fx.set_deferred("global_position", hit_pos)
			get_tree().get_root().get_node("Main").add_child(hit_fx)
			ai_controller.reward += 5
	else:
		print("Miss!")
		ai_controller.reward -= 0.03
		var hit_fx = m.instantiate()
		var hit_pos = to_global(r.target_position)
		hit_fx.set_deferred("global_position", hit_pos)
		get_tree().get_root().get_node("Main").add_child(hit_fx)
	
	await get_tree().create_timer(0.2).timeout
	r.queue_free()

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

func _on_timer_shoot_timeout() -> void:
	shoot()
	
