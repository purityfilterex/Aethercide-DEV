extends Resource

class_name Weapons_Resource

@export var Weapon_Name: String
@export var Weapon_Transition: String
@export var Weapon_Aimer: String
@export var Weapon_Shoot: String
@export var Weapon_Equip: String
@export var Weapon_Reload: String

@export var Equip_Anim: String
@export var Unequip_Anim: String
@export var Idle_Anim: String
@export var Shoot_Anim: String
@export var Sprint_Anim: String
@export var Aim_Anim: String
@export var Aim_Shoot_Anim: String
@export var Walk_Anim: String
@export var Jump_Anim: String

@export var Current_Ammo: int
@export var Reserve_Ammo: int
@export var Magazine: int
@export var MaxAmmo: int

@export var Autofire: bool
@export_flags("Hitscan", "Projectile") var Type
@export var Projectile_To_Load: PackedScene
@export var Projectile_Velocity: int

@export var Weapon_Range: int
@export var Damage: int
@export var Damage_Falloff: float
@export var Damage_Falloff_Floor: int

@export var Base_Inaccuracy: float
@export var Movement_Inaccuracy: float
@export var Aim_Inaccuracy: float
@export var Jump_Inaccuracy: float

@export var Fire_Rate: float
@export var Reload_Time: float

@export var Num_Shots: int
