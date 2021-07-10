extends Control

var benchmarking : bool
func _input(event):
	if event.is_action_pressed("ui_accept") and !benchmarking:
		benchmarking = true
		$Label.hide()
		var shader_time = yield($Shader.render(),"completed")
		var resource_time = yield($NoiseTexture.render(),"completed")
		$Label.text = "Shader_time: %s      |      NoiseTexture_time: %s" % [shader_time,resource_time]
		$Label.text += "\n Press enter to start a new benchmark"
		$Label.show()
		print("\nBenchmark finished")
		benchmarking = false
	
