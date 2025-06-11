extends Node3D

signal Weapon_Changed
signal Update_Ammo
signal Update_Weapon_Stack

var Current_Weapon: Weapons_Resource = null

var Weapon_Stack = []

var Debug_Bullet = preload("res://player/weapons_resources/debugtarget.tscn")

var Weapon_Indicator = 0

var Next_Weapon: String

var Weapon_List = {}

enum {IDLE,WALK,SPRINT,AIM,AIMSHOOT,SHOOT,EQUIP,UNEQUIP,JUMP, RELOAD}
enum {NULL, HITSCAN, PROJECTILE, GRENADE}
var curr_anim = null

@export var _weapon_resources: Array[Weapons_Resource]
@export var Start_Weapons: Array[String]

@export var cur_speed = 0.0
@export var is_on_floor = false
@export var location = 0

@onready var Bullet_Point = get_node("%Bullet_Point")

func set_speed(speed):
	cur_speed = speed

func set_is_on_floor(floor):
	is_on_floor = floor

func set_location(pos):
	location = pos

func get_is_on_floor():
	return is_on_floor
	
func get_speed():
	return cur_speed
	
func get_location():
	return location

func _ready():
	Initialize(Start_Weapons) #enter state machine
	
func _physics_process(delta):
	if get_is_on_floor() == false:
		await get_tree().create_timer(%AdsTimer.get_time_left()).timeout
		curr_anim = JUMP
		handle_animations()
	elif Input.is_action_pressed("ads"):
		await get_tree().create_timer(%AdsTimer.get_time_left()).timeout
		curr_anim = AIM
		handle_animations()
		%AdsTimer.start()
	elif get_speed() > 3.2 and Input.is_action_pressed("dash"):
		await get_tree().create_timer(%AdsTimer.get_time_left()).timeout
		curr_anim = SPRINT
		handle_animations()
	elif get_speed() > 3.2:
		await get_tree().create_timer(%AdsTimer.get_time_left()).timeout
		curr_anim = WALK
		handle_animations()
	else:
		await get_tree().create_timer(%AdsTimer.get_time_left()).timeout
		curr_anim = IDLE
		handle_animations()
	
	#Autofire
	if Current_Weapon.Autofire == true and Input.is_action_pressed("shoot") and is_shot == false and (curr_anim == AIM or curr_anim == AIMSHOOT) and curr_anim != SPRINT:
		aimshoot()
	elif Current_Weapon.Autofire == true and Input.is_action_pressed("shoot") and !curr_anim == AIM and curr_anim != SPRINT:
		shoot()
	
func Is_Aiming():
	if curr_anim == AIM or curr_anim == AIMSHOOT:
		return true
	else:
		return false

func _input(event):
	if Input.is_action_just_pressed("shoot") and Is_Aiming() and curr_anim != SPRINT:
		aimshoot()
	elif Input.is_action_just_pressed("shoot") and curr_anim != SPRINT and !Is_Aiming():
		shoot()
	elif Input.is_action_just_pressed("reload") and curr_anim != SPRINT and curr_anim != EQUIP and curr_anim != UNEQUIP:
		reload()
	if Input.is_action_just_pressed("switch weapon up"):
		Weapon_Indicator = min(Weapon_Indicator+1, Weapon_Stack.size()-1)
		exit(Weapon_Stack[Weapon_Indicator])
	if Input.is_action_just_pressed("switch weapon down"):
		Weapon_Indicator = max(Weapon_Indicator-1, 0)
		exit(Weapon_Stack[Weapon_Indicator])

func handle_animations():
	match curr_anim:
		IDLE:
			%AnimationTree.set(Current_Weapon.Weapon_Transition,Current_Weapon.Idle_Anim)
		WALK:
			%AnimationTree.set(Current_Weapon.Weapon_Transition , Current_Weapon.Walk_Anim)
		SPRINT:
			%AnimationTree.set(Current_Weapon.Weapon_Transition , Current_Weapon.Sprint_Anim)
		AIM:
			%AnimationTree.set(Current_Weapon.Weapon_Transition , Current_Weapon.Aim_Anim)
		AIMSHOOT:
			%AnimationTree.set(Current_Weapon.Weapon_Aimer, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		SHOOT:
			%AnimationTree.set(Current_Weapon.Weapon_Shoot, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		EQUIP:
			%AnimationTree.set(Current_Weapon.Weapon_Equip, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		UNEQUIP:
			%AnimationTree.set(Current_Weapon.Unequip_Anim, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		JUMP:
			%AnimationTree.set(Current_Weapon.Weapon_Transition , Current_Weapon.Jump_Anim)
		RELOAD:
			%AnimationTree.set(Current_Weapon.Weapon_Reload, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func Initialize(_start_weapons: Array):
	#create dictionary to refer to weapons
	for weapon in _weapon_resources:
		Weapon_List[weapon.Weapon_Name] = weapon
		
	
	for i in _start_weapons:
		Weapon_Stack.push_back(i) #Add out start weapons
		
	Current_Weapon = Weapon_List[Weapon_Stack[0]] #set first weapon in stack to current
	emit_signal("Update_Weapon_Stack", Weapon_Stack)
	enter()
	

func enter():
	%AnimationTree.set("parameters/Main_Transition/transition_request", Current_Weapon.Weapon_Name)
	curr_anim = EQUIP
	emit_signal("Weapon_Changed", Current_Weapon.Weapon_Name)
	emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
	handle_animations()

func exit(_next_weapon: String):
	if _next_weapon != Current_Weapon.Weapon_Name and is_reloading == false:
		if curr_anim != UNEQUIP:
			curr_anim = UNEQUIP
			handle_animations()
			Next_Weapon = _next_weapon
			switch_animation()

func switch_animation():
	await get_tree().create_timer(0.2).timeout
	Change_Weapon(Next_Weapon)

func Change_Weapon(weapon_name: String):
	Current_Weapon = Weapon_List[weapon_name]
	Next_Weapon = ""
	enter()

var is_shot = false
func aimshoot():
	if Current_Weapon.Current_Ammo > 0:
		if is_reloading == false and is_shot == false:
			is_shot = true
			%AnimTimer.wait_time = Current_Weapon.Fire_Rate
			await get_tree().create_timer(%AnimTimer.get_time_left()).timeout
			
			for n in Current_Weapon.Num_Shots: #For Shotguns
				var Camera_Collision = Get_Camera_Collision()
			
				match Current_Weapon.Type:
					NULL:
						print("Weapon Type Not Chosen")
					PROJECTILE:
						Launch_Projectile(Camera_Collision)
					HITSCAN:
						if Current_Weapon.Autofire == true and not Input.is_action_pressed("shoot"):
							pass
						else:
							Current_Weapon.Current_Ammo -= 1
							curr_anim = AIMSHOOT
							Hit_Scan_Collision(Camera_Collision)
							handle_animations()
							if is_reloading == false:
								emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
					GRENADE:
						return
			
			%AnimTimer.start()
			is_shot = false

func shoot():
	if Current_Weapon.Current_Ammo > 0:
		if is_reloading == false and is_shot == false:
			is_shot = true
			
			await get_tree().create_timer(%AnimTimer.get_time_left()).timeout
			
			for n in Current_Weapon.Num_Shots: #For Shotguns
				var Camera_Collision = Get_Camera_Collision()
			
				match Current_Weapon.Type:
					NULL:
						print("Weapon Type Not Chosen")
					PROJECTILE:
						Launch_Projectile(Camera_Collision)
					HITSCAN:
						if Current_Weapon.Autofire == true and not Input.is_action_pressed("shoot"):
							pass
						else:
							Current_Weapon.Current_Ammo -= 1
							curr_anim = SHOOT
							handle_animations()	
							Hit_Scan_Collision(Camera_Collision)
							if is_reloading == false:
								emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
					GRENADE:
						return
			%AnimTimer.wait_time = Current_Weapon.Fire_Rate
			%AnimTimer.start()
			is_shot = false
	
var is_reloading = false
func reload():
	if Current_Weapon.Current_Ammo == Current_Weapon.Magazine:
		return
	elif curr_anim != RELOAD and is_reloading == false:
		if Current_Weapon.Reserve_Ammo != 0:
			is_reloading = true
			var Reload_Amount = min(Current_Weapon.Magazine - Current_Weapon.Current_Ammo, Current_Weapon.Magazine, Current_Weapon.Reserve_Ammo)
			Current_Weapon.Current_Ammo = Current_Weapon.Current_Ammo + Reload_Amount
			Current_Weapon.Reserve_Ammo = Current_Weapon.Reserve_Ammo - Reload_Amount
			curr_anim = RELOAD
			handle_animations()
			
			#Timer For Reload Animation
			%AnimTimer.wait_time = Current_Weapon.Reload_Time
			%AnimTimer.start()
			await get_tree().create_timer(%AnimTimer.get_time_left()).timeout
			emit_signal("Update_Ammo", [Current_Weapon.Current_Ammo, Current_Weapon.Reserve_Ammo])
			is_reloading = false
		else:
			return
			#Put sound here in the future
			

func Launch_Projectile(Point: Vector3):
	var Direction = (Point - Bullet_Point.get_global_transform().origin).normalized()
	var Projectile = Current_Weapon.Projectile_To_Load.instantiate()
	
	Bullet_Point.add_child(Projectile)
	Projectile.position = Bullet_Point.global_position
	Projectile.look_at(Point)
	Projectile.Damage = Current_Weapon.Damage
	Projectile.set_linear_velocity(Direction*Current_Weapon.Projectile_Velocity)

func Calculate_Inaccuracy():
	var Inaccuracy = Current_Weapon.Base_Inaccuracy + (Current_Weapon.Movement_Inaccuracy * get_speed())
	if Is_Aiming():
		Inaccuracy = Inaccuracy * Current_Weapon.Aim_Inaccuracy 
	if get_is_on_floor() == false:
		Inaccuracy = Inaccuracy * Current_Weapon.Jump_Inaccuracy 
	return Inaccuracy

var Falloff = 0
func Get_Camera_Collision()->Vector3:
	var camera = get_viewport().get_camera_3d()
	var viewport= get_viewport().get_size()
	
	var Ray_Origin = camera.project_ray_origin(viewport/2)
	var Ray_End = Ray_Origin + camera.project_ray_normal(viewport/2)*Current_Weapon.Weapon_Range
	
	#Apply Inaccuracy
	Ray_End.x  = Ray_End.x + randf_range(-Calculate_Inaccuracy(), Calculate_Inaccuracy())
	Ray_End.y = Ray_End.y + randf_range(-Calculate_Inaccuracy(), Calculate_Inaccuracy())
	
	var New_Intersection = PhysicsRayQueryParameters3D.create(Ray_Origin, Ray_End)
	var intersection = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if not intersection.is_empty():
		var Col_Point = intersection.position 
		
		#Calculate Distance Falloff
		Falloff = floor((get_location().distance_to(Col_Point)) * Current_Weapon.Damage_Falloff)
		if Falloff >= Current_Weapon.Damage_Falloff_Floor:
			Falloff = Current_Weapon.Damage_Falloff_Floor
			
		return Col_Point
	else:
		return Ray_End

func Hit_Scan_Collision(Collision_Point):
	var Bullet_Direction = (Collision_Point - Bullet_Point.get_global_transform().origin).normalized() 
	var New_Intersection = PhysicsRayQueryParameters3D.create(Bullet_Point.get_global_transform().origin, Collision_Point + Bullet_Direction*2)
	
	var Bullet_Collision = get_world_3d().direct_space_state.intersect_ray(New_Intersection) 
	if Bullet_Collision:
		var Hit_Indicator = Debug_Bullet.instantiate()
		var world = get_tree().get_root()
		world.add_child(Hit_Indicator)
		Hit_Indicator.global_translate(Bullet_Collision.position)
		
		Hit_Scan_Damage(Bullet_Collision.collider)

func Hit_Scan_Damage(Collider):
	if Collider.is_in_group("Target") and Collider.has_method("Hit_Successful"):
		Collider.Hit_Successful(Current_Weapon.Damage - Falloff)
