class_name CellularComputeGrid
extends RefCounted

var rd: RenderingDevice
var shader: RID
var pipeline: RID

var width: int
var height: int
var layer_count: int

var input_textures: Array[RID] = []
var output_texture: RID
var uniform_set: RID

var result_buffer: PackedByteArray

func _init():
	rd = RenderingServer.create_local_rendering_device()
	if not rd:
		push_error("Failed to create local rendering device")

func setup(p_width: int, p_height: int, p_layer_count: int, shader_file: RDShaderFile) -> bool:
	width = p_width
	height = p_height
	layer_count = p_layer_count
	
	var shader_spirv = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	if not shader.is_valid():
		push_error("Failed to create shader")
		return false
	
	# Create pipeline
	pipeline = rd.compute_pipeline_create(shader)
	if not pipeline.is_valid():
		push_error("Failed to create pipeline")
		return false
	
	# Create input textures (R16F format for 16-bit float)
	var format = RDTextureFormat.new()
	format.width = width
	format.height = height
	format.format = RenderingDevice.DATA_FORMAT_R16_SFLOAT
	format.usage_bits = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT | \
						RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | \
						RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
	
	input_textures.clear()
	for i in range(layer_count):
		var view = RDTextureView.new()
		var texture = rd.texture_create(format, view, [])
		if not texture.is_valid():
			push_error("Failed to create input texture %d" % i)
			return false
		input_textures.append(texture)
	
	# Create output texture
	var output_format = RDTextureFormat.new()
	output_format.width = width
	output_format.height = height
	output_format.format = RenderingDevice.DATA_FORMAT_R16_SFLOAT
	output_format.usage_bits = RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | \
								RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var output_view = RDTextureView.new()
	output_texture = rd.texture_create(output_format, output_view, [])
	if not output_texture.is_valid():
		push_error("Failed to create output texture")
		return false
	
	# Create uniform set
	_create_uniform_set()
	
	return true

func _create_uniform_set():
	var uniforms = []
	
	# Input texture uniforms (bindings 0 to layer_count-1)
	for i in range(layer_count):
		var uniform = RDUniform.new()
		uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
		uniform.binding = i
		uniform.add_id(rd.sampler_create(RDSamplerState.new()))
		uniform.add_id(input_textures[i])
		uniforms.append(uniform)
	
	# Output texture uniform (binding = layer_count)
	var output_uniform = RDUniform.new()
	output_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_uniform.binding = layer_count
	output_uniform.add_id(output_texture)
	uniforms.append(output_uniform)
	
	uniform_set = rd.uniform_set_create(uniforms, shader, 0)

func update_layer(layer_index: int, image: Image) -> bool:
	if layer_index < 0 or layer_index >= layer_count:
		push_error("Invalid layer index: %d" % layer_index)
		return false
	
	if image.get_width() != width or image.get_height() != height:
		push_error("Image dimensions don't match grid: expected %dx%d, got %dx%d" % 
				   [width, height, image.get_width(), image.get_height()])
		return false
	
	# Convert image to R16F format
	var img_copy = image.duplicate()
	img_copy.convert(Image.FORMAT_RH)  # R16F format
	
	var data = img_copy.get_data()
	rd.texture_update(input_textures[layer_index], 0, data)
	
	return true

func execute():
	var compute_list = rd.compute_list_begin()
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	
	# Dispatch compute shader (8x8 work groups)
	var group_x = ceili(width / 8.0)
	var group_y = ceili(height / 8.0)
	rd.compute_list_dispatch(compute_list, group_x, group_y, 1)
	
	rd.compute_list_end()
	rd.submit()
	rd.sync()

func get_result() -> Image:
	# Read back the output texture
	var byte_data = rd.texture_get_data(output_texture, 0)
	
	# Create image from data
	var result = Image.create_from_data(width, height, false, Image.FORMAT_RH, byte_data)
	
	return result

func cleanup():
	if uniform_set.is_valid():
		rd.free_rid(uniform_set)
	
	if output_texture.is_valid():
		rd.free_rid(output_texture)
	
	for tex in input_textures:
		if tex.is_valid():
			rd.free_rid(tex)
	
	if pipeline.is_valid():
		rd.free_rid(pipeline)
	
	if shader.is_valid():
		rd.free_rid(shader)
	
	input_textures.clear()

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		cleanup()
