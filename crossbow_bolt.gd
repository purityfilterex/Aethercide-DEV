extends RigidBody3D

var Damage: int = 10

func _on_body_entered(body):
	if body.is_in_group("StickyWall"):
		set_linear_velocity(Vector3.ZERO)
		gravity_scale = 0
		freeze = true
		set_collision_layer_value(2, true)
		
	if body.is_in_group("Target") && body.has_method("Hit_Successful"):
		body.Hit_Successful(Damage)
		queue_free()
		
