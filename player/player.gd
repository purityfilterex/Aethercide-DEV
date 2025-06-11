extends CharacterBody3D

var speed

@export var JUMP_VELOCITY = 4.8
@export var SENSITIVITY = 0.004
@export var CONTROLLER_SENSITIVITY = 0.04

@export var AIM_SPEED = 4
@export var WALK_SPEED = 5
@export var SPRINT_SPEED = 6
@export var ground_accel = 14.0
@export var ground_decel = 12.0
@export var ground_friction = 4

@export var air_cap = 0.05
@export var air_accel = 800.0
@export var air_move_speed = 500.0

var wish_dir = Vector3.ZERO

#bob variables
const BOB_FREQ = 2.4
const BOB_AMP = 0.03
var t_bob = 0.0

#fov variables
const BASE_FOV = 75.0
const FOV_CHANGE = 0.3

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 12
var wallgrab = 2.2

var jumps = 2
var jump_counter = 2

@export var autobhop = true

@onready var head = %Head
@onready var camera = %Head/mainCamera

func _ready():
	pass

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * SENSITIVITY)
			%mainCamera.rotate_x(-event.relative.y * SENSITIVITY)
			%mainCamera.rotation.x = clamp(%mainCamera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

var _cur_controller_look = Vector2()
func _handle_controller_look_input(delta):
	var target_look_r = Input.get_action_strength("look right")
	var target_look_l = Input.get_action_strength("look left")
	var target_look_u = Input.get_action_strength("look up")
	var target_look_d = Input.get_action_strength("look down")
	
	rotate_y(-target_look_r * CONTROLLER_SENSITIVITY) #left right
	rotate_y(target_look_l * CONTROLLER_SENSITIVITY) #left right
	%mainCamera.rotate_x(target_look_u * CONTROLLER_SENSITIVITY) #up down
	%mainCamera.rotate_x(-target_look_d * CONTROLLER_SENSITIVITY) #up down
	%mainCamera.rotation.x = clamp(%mainCamera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func move_speed():
	if Input.is_action_pressed("ads"):
		return AIM_SPEED
	elif Input.is_action_pressed("dash") and !Input.is_action_pressed("ads"):
		return SPRINT_SPEED
	else:
		return WALK_SPEED

func _handle_ground_physics(delta):
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var add_speed_till_cap = move_speed() - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = ground_accel * delta * move_speed()
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir
		
	var control = max(self.velocity.length(), ground_decel)
	var drop = control * ground_friction * delta
	var new_speed = max(self.velocity.length() - drop, 0.0)
	if self.velocity.length() > 0:
		new_speed /= self.velocity.length()
	self.velocity *= new_speed

func _handle_air_physics(delta):
	self.velocity.y -= gravity * delta
	var cur_speed_in_wish_dir = self.velocity.dot(wish_dir)
	var capped_speed = min((air_move_speed * wish_dir).length(), air_cap)
	var add_speed_till_cap = capped_speed - cur_speed_in_wish_dir
	if add_speed_till_cap > 0:
		var accel_speed = air_accel * air_move_speed * delta
		accel_speed = min(accel_speed, add_speed_till_cap)
		self.velocity += accel_speed * wish_dir

func _physics_process(delta):
	var input_dir = Input.get_vector("left", "right", "up", "down").normalized()
	wish_dir = self.global_transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)
	
	if is_on_floor():
		jump_counter = jumps
	if Input.is_action_just_pressed("jump") and jump_counter > 0:
		self.velocity.y = JUMP_VELOCITY
		jump_counter -= 1
	
	if is_on_floor():
		_handle_ground_physics(delta)
	else:
		_handle_air_physics(delta)
	
	
	_handle_controller_look_input(delta)
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	%Weapons_Manager.set_is_on_floor(is_on_floor())
	%Weapons_Manager.set_speed(velocity.length())
	%Weapons_Manager.set_location(position)
	move_and_slide()

func process(delta):
	pass



func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ) * BOB_AMP
	return pos
