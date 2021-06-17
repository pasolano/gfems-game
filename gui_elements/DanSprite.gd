extends Sprite

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		if get_rect().has_point(to_local(event.position)):
			PlayerData.set_sprite(PlayerData.Sprite_Name.DAN)