tool
extends ImageTexture
class_name NoiseTexture_v2

class shader_renderer: 
	extends Resource
	var viewport := Viewport.new()
	var _color_rect := ColorRect.new()
	var loop : MainLoop
	var container := ViewportContainer.new() # Viewports NEED to have a viewportcontainer to work in the editor see https://github.com/godotengine/godot-proposals/issues/2139

	func init(): # With _init there's an error because main_loop in null
		loop = Engine.get_main_loop()
		if !loop:
			return ERR_CANT_RESOLVE
		loop.root.call_deferred("add_child",container)
		container.hide()
		container.self_modulate = Color(0,0,0,0)
		container.call_deferred("add_child",viewport)
		viewport.call_deferred("add_child",_color_rect)
		viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
		_color_rect.hide()
		initiated = true
		return OK
	
	var initiated : bool
	func render(material:ShaderMaterial,resolution:Vector2,arg:Dictionary):
		if !initiated:
			if init() != OK:
				return ERR_CANT_RESOLVE
		viewport.size = resolution
		_color_rect.rect_size = resolution
		for a in arg:
			material.set_shader_param(a,arg[a])
		_color_rect.set_material(material)
		
		_color_rect.show()
		viewport.UPDATE_ALWAYS
		container.show()
		yield(loop,"idle_frame")
		yield(loop,"idle_frame")
		yield(loop,"idle_frame")
		viewport.UPDATE_DISABLED
		container.hide()
		_color_rect.hide()
		var texture : Image = viewport.get_texture().get_data().duplicate()
		texture.flip_y()
		return texture
	
	func free(): # Doesn't work
		viewport.free()

class GDScript_SimplexNoise:
	extends Resource
	export var _seed : int = 1
	export var octaves : int = 1
	export var period : float = 64
	export var persistence : float = 0.5
	export var lacunarity : float = 2
	
	func get_noise2D(pos:Vector2):
		pos = pos / (period * 2.0)
		var amp := 1.0
		var mx := 1.0
		var sum : float = snoise(pos)
		for i in (octaves -1) :
			pos *= lacunarity;
			amp *= persistence;
			mx += amp;
			sum += snoise(pos) * amp;
		return 0.5 + ((sum / mx) * 0.5)
	
	# Ported by megazar21 from https://github.com/ashima/webgl-noise
	func mod289(x:Vector3) -> Vector3:
		return x - (x * (1.0 / 289.0)).floor() * 289.0

	func permute(x:Vector3) -> Vector3:
		return mod289(((x*34.0)+Vector3(_seed,_seed,_seed))*x)
	
	# There's no vector4 in GDScript, so we make 2 Vector2
	const Cxy := Vector2(0.211324865405187,  # (3.0-sqrt(3.0))/6.0
						  0.366025403784439)# 0.5*(sqrt(3.0)-1.0)
	const Czw := Vector2(-0.577350269189626,  # -1.0 + 2.0 * C.x
					  0.024390243902439)#  1.0 / 41.0
	func snoise(v:Vector2) -> float:
		# First corner
		var dot : float = v.dot( Vector2(Cxy.y,Cxy.y))
		var i : Vector2 = (v + Vector2(dot,dot) ).floor()
		dot = i.dot( Vector2(Cxy.x,Cxy.x))
		var x0 : Vector2 = v - i +  Vector2(dot,dot)
		# Other corners
		var i1 : Vector2 =  Vector2(1.0, 0.0) if (x0.x > x0.y) else Vector2(0.0, 1.0)
		var x12 := PoolRealArray([x0.x + Cxy.x , x0.y + Cxy.x , x0.x + Czw.x ,  x0.y + Czw.x])# Like a vector4: x0.xyxy + C.xxzz
		x12[0] -= i1.x
		x12[1] -= i1.y
		#Permutations
		var p : Vector3 = permute( permute( Vector3(i.y,i.y,i.y) + Vector3(0.0, i1.y, 1.0 ) )
			+ Vector3(i.x,i.x,i.x) + Vector3(0.0, i1.x, 1.0 ))
		var m : Vector3 =  Vector3(0.5,0.5,0.5) - Vector3( x0.dot(x0), Vector2(x12[0],x12[1]).dot(Vector2(x12[0],x12[1])) , Vector2(x12[2],x12[3]).dot(Vector2(x12[2],x12[3]) ) )
		m = m*m  #?
		m *= m
		# Gradients: 41 points uniformly over a line, mapped onto a diamond.
		# The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)
		p *=  Czw.y
		var x : Vector3 =  2.0 * (p - p.floor()) - Vector3(1.0,1.0,1.0) # 2.0 * fract(p * Vector3(Czw.y,Czw.y,Czw.y)) - 1.0
		var h : Vector3 = x.abs() - Vector3(0.5,0.5,0.5)
		var a0 : Vector3 = x - (x + Vector3(0.5,0.5,0.5) ).floor()
		# Normalise gradients implicitly by scaling m
		# Approximation of: m *= inversesqrt( a0*a0 + h*h );
		m *= Vector3(1.79284291400159,1.79284291400159,1.79284291400159) - 0.85373472095314 * ( a0*a0 + h*h )
		
		# Compute final noise value at P
		return 130.0 * m.dot( Vector3(a0.x  * x0.x  + h.x  * x0.y,a0.y * x12[0] + h.y * x12[1],a0.z * x12[2] + h.z * x12[3]))

var renderer := shader_renderer.new() 
var CPU_SimplexNoise :=  CPP_SimplexNoise.new() # If GDNative version doesn't work, you can use: GDScript_SimplexNoise.new() 
var main_shader : ShaderMaterial = preload("Simplex shader.tres").duplicate()

export var Use_GPU : bool = true setget set_use_GPU
func set_use_GPU(bol):
	Use_GPU = bol
	if !bol and size.length() > 1000 and Engine.editor_hint:
		var window := AcceptDialog.new()
		window.dialog_text = "Rendering High-res images using CPU could be very slow and make your PC laggy"
		window.dialog_autowrap = true
		Engine.get_main_loop().root.add_child(window)
		window.rect_size = Vector2(200,0)
		window.popup_centered()
		yield(window,"popup_hide")
		window.queue_free()
export var Threading_render : bool = true # Only for CPU render
export var _seed : int = 1 setget set_seed
func set_seed(sd):
	var _sd = int(sd)
	
	if [17,34,68,136,272,544].has(_sd): # For some reason I don't know, numbers of the power of 2, plus 1 doesn't work
		_seed = _sd + 1
	elif _sd != 0:
		_seed = sd
export var size : Vector2 = Vector2(100,100) setget set_size
func set_size(_size):
	size = _size.abs()
export var octaves : int = 1 setget set_octaves
func set_octaves(_octaves):
	octaves = clamp(_octaves,1,9)
export var period : float = 64
export var persistence : float = 0.5
export var lacunarity : float = 2

export var render : bool setget __render
func __render(p):
	if !Engine.get_main_loop():
		return
	_render()


func _render():
	yield(GPU_render(),"completed") if Use_GPU else render_with_CPU()

func render_with_CPU():
	CPU_SimplexNoise.period = period
	CPU_SimplexNoise.persistence =  persistence
	CPU_SimplexNoise.lacunarity =  lacunarity
	CPU_SimplexNoise.octaves =  octaves
	CPU_SimplexNoise._seed =  _seed
	var image := Image.new()
	image.create(size.x,size.y,false,Image.FORMAT_L8)
	if Threading_render:
		var threads := []
		var nmb_of_threads : int = OS.get_processor_count() 
		for thr in nmb_of_threads:
			var thread := Thread.new()
			threads.append(thread)
			thread.start(self,"thread_rend",{"from_y": (size.y / float(nmb_of_threads) ) * thr, "to_y": (size.y / float(nmb_of_threads) ) * (thr + 1), "x_size": size.x,"CPU_SimplexN":CPU_SimplexNoise })
		# TODO: make the rendering in the bg
		"""
		while true:
			yield(Engine.get_main_loop(),"idle_frame")# Waits a frame
			var finished : bool = true
			for thr in nmb_of_threads:
				if threads[thr].is_active():
					print("not_active")
					finished = false
			if finished:
				print("finished")
				break
		"""
		for thr in nmb_of_threads:
			threads[thr] = threads[thr].wait_to_finish()
		
		image.lock()
		for nmb in nmb_of_threads:
			var from_y = (size.y / float(nmb_of_threads) ) * nmb
			var to_y = (size.y / float(nmb_of_threads) ) * (nmb + 1)
			for _y in (to_y - from_y):
				var y = _y + from_y
				for x in size.x:
					var value : float = threads[nmb][((_y * size.x) + x) ]
					image.set_pixel(x,y,Color(value,value,value))
		image.unlock()
	else:
		#For a single thread
		image.lock()
		for x in size.x:
			for y in size.y:
				var value : float = CPU_SimplexNoise.get_noise2D(Vector2(x,y))
				image.set_pixel(x,y,Color( value, value, value))
		image.unlock()
	
	self.create_from_image(image)

func thread_rend(data:Dictionary):#For some reason, we have to pass the args of the thread as a unique variable 
	var from_y : float = data["from_y"]
	var to_y : float = data["to_y"]
	var x_size : float = data["x_size"]
	var CPU_SimplexN := CPP_SimplexNoise.new() # Workaround for this issue https://godotengine.org/qa/102107/crash-gdnative-modules-and-threading
	CPU_SimplexN._seed = data["CPU_SimplexN"]._seed
	CPU_SimplexN.lacunarity = data["CPU_SimplexN"].lacunarity
	CPU_SimplexN.octaves = data["CPU_SimplexN"].octaves
	CPU_SimplexN.period = data["CPU_SimplexN"].period
	CPU_SimplexN.persistence = data["CPU_SimplexN"].persistence
	
	var result : PoolRealArray
	for _y in  (to_y - from_y):
		var y : float = _y + from_y
		for x in x_size:
			result.append(CPU_SimplexN.get_noise2D(Vector2(x,y)))
	return result


func GPU_render():
	var rend = renderer.render(main_shader,size,{"resolution":size,"seed":_seed,"octaves":octaves,"period":period,"persistence":persistence,"lacunarity":lacunarity})
	if typeof(rend) != TYPE_OBJECT:
		return ERR_CANT_RESOLVE
	self.create_from_image(yield(rend,"completed"))

func free():
	renderer.free()

