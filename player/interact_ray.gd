extends RayCast3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		add_exception(owner)

func _physics_process(delta):
	%InteractionHUD.text = ""
	if is_colliding():
		if get_collider().is_in_group("Pickup_Weapons"):
			%InteractionHUD.text = get_collider().Weapon_Name
		
