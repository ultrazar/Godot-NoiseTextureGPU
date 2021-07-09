extends TextureRect

onready var shader_to_image: Node2D  = $"../ShaderToImage"

const resolution = Vector2(7680 ,4320) # 8K UHDV

func render():
	var my_material = preload("res://Simplex shader.tres")
	show()
	yield(get_tree().create_timer(1.0),"timeout")
	print("Shader started")
	var actual_time : float = OS.get_ticks_msec() / 1000.0
	var image : Image = yield(shader_to_image.generate_image(my_material,resolution,1.0,{"lacunarity": rand_range(1.7,2.3)} ), "completed")
	actual_time = (OS.get_ticks_msec() / 1000.0) - actual_time
	print(actual_time)
	
	texture = ImageTexture.new()
	texture.image = image
	yield(get_tree().create_timer(3.0),"timeout")
	hide()
	return actual_time


"""

func frame():
	$Viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
	$Viewport.render_target_update_mode = Viewport.UPDATE_ONCE

signal rendered(time)
var rendering : bool
func render():
	$Viewport/ColorRect.show()
	show()
	print("shader started")
	var actual_time : float = OS.get_ticks_msec() / 1000.0
	rendering = true
	frame() #Main rendering
	actual_time = yield(self,"rendered")
	#actual_time = (OS.get_ticks_msec() / 1000.0) - actual_time
	yield(get_tree().create_timer(3.0),"timeout")
	#actual_time = yield(self,"rendered")
	print(actual_time)
	$Viewport/ColorRect.hide()
	hide()
	frame()
	return actual_time


func _process(delta): #There's 4 frames of delay using a viewport
	if rendering:
		rendering = false
		emit_signal("rendered",delta)

	if rendering == 4:
		emit_signal("rendered",delta)
	else:
		rendering += 1



var rendering : int
signal rendered(time)
func render():
	yield(get_tree().create_timer(0.5),"timeout")
	$Viewport/ColorRect.show()
	var _material : ShaderMaterial = $Viewport/ColorRect.material
	_material.set_shader_param("lacunarity",rand_range(0.2,2.0))
	rendering = 1
	print("shader started")
	var time = yield(self,"rendered")
	print(time)
	yield(get_tree().create_timer(0.5),"timeout")
	$Viewport/ColorRect.hide()
	yield(get_tree().create_timer(0.5),"timeout")
	#return time

func _process(delta): #There's 4 frames of delay using a viewport
	if rendering == 4:
		emit_signal("rendered",delta)
	else:
		rendering += 1

"""
