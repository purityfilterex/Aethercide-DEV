extends RigidBody3D

var health = 100
func Hit_Successful(Damage, _Direction:= Vector3.ZERO, _Position:= Vector3.ZERO):
	var Hit_Position = _Position - get_global_transform().origin
	health -= Damage
	print("Target Health " + str(health))
	if health <= 0:
		queue_free()
	
	if _Direction != Vector3.ZERO:
		print_debug("Hit")
		apply_impulse((_Direction*Damage),Hit_Position)
