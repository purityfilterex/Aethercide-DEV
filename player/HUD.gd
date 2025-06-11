extends CanvasLayer

@onready var Current_Weapon_Label = $"VBoxContainer/HBoxContainer/Current Weapon"
@onready var Current_Ammo_Label = $"VBoxContainer/HBoxContainer2/Current Ammo"
@onready var Weapon_Stack_Label = $"VBoxContainer/HBoxContainer3/Weapon Stack"


func _on_weapons_manager_update_ammo(Ammo):
	Current_Ammo_Label.set_text(str(Ammo[0]) + " / " + str(Ammo[1]))

func _on_weapons_manager_update_weapon_stack(Weapon_Stack):
	Weapon_Stack_Label.set_text("")
	for i in Weapon_Stack:
		Weapon_Stack_Label.text += "\n"+i

func _on_weapons_manager_weapon_changed(Weapon_Name):
	Current_Weapon_Label.set_text(Weapon_Name)
