extends TextureRect

const resolution = Vector2(3840,2160) # 4K UHD
func render():
	show()
	yield(get_tree().create_timer(0.5),"timeout")
	texture.width = resolution.x
	texture.height = resolution.y
	texture.noise.seed = rand_range(0,100)
	print("NoiseTexture started")
	var actual_time : float = OS.get_ticks_msec() / 1000.0
	yield(texture,"changed")
	actual_time = (OS.get_ticks_msec() / 1000.0) - actual_time
	print(actual_time)
	yield(get_tree().create_timer(3.0),"timeout") # Time to see the new texture
	hide()
	return actual_time

