extends RigidBody3D

var Damage: int = 10

func _on_body_entered(body):
	print_debug("body entered")
	set_linear_velocity(Vector3.ZERO)
	
	if body.is_in_group("Target") && body.has_method("Hit_Successful"):
		print_debug("is a target")
		body.Hit_Successful(Damage)

func _on_timer_timeout() -> void:
	queue_free()
