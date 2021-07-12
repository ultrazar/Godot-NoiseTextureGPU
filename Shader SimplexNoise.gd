extends TextureRect

const resolution = Vector2(3840,2160) # 4K UHD

func _ready():
	texture.renderer.init() # Preparing the viewport and things to render it

const Use_gpu = true

func render():
	texture.Use_GPU = Use_gpu
	texture.size = resolution #Vector2(1280,720)
	texture._seed = rand_range(0,999)
	
	show()
	print("Shader started")
	var actual_time : float = OS.get_ticks_msec() / 1000.0
	yield(texture._render(),"completed") if Use_gpu else texture._render()
	actual_time = (OS.get_ticks_msec() / 1000.0) - actual_time
	print(actual_time)
	yield(get_tree().create_timer(5.0),"timeout") # Time to see the new texture...
	hide()
	return actual_time
