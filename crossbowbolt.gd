extends RigidBody3D

var Damage: int = 0

func _on_body_entered(body):
	if body.is_in_group("Target") && body.has_method("Hit_Successful"):
		body.Hit_Successful(Damage)

func _on_timer_timeout() -> void:
	queue_free()
