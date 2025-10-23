class_name CellularComputer
extends Node

signal TerrainGenerated

@export var terrain_gen:TerrainGenerator

var compute_grid: CellularComputeGrid
var grid_width = 256
var grid_height = 256
var step_count = 0

const DIFFUSION_EXAMPLE:RDShaderFile = preload("uid://boxnwu2i18uhc")

func _ready():
	terrain_gen.connect('TerrainGenerated',new_image_map)
	# Initialize the compute grid
	compute_grid = CellularComputeGrid.new()
	
	# Setup with 10 layers, using the diffusion shader
	var success = compute_grid.setup(
		grid_width, 
		grid_height, 
		10,
		DIFFUSION_EXAMPLE
	)
	
	if not success:
		push_error("Failed to setup compute grid")
		return

func _process(_delta):
	# Run simulation step when spacebar is pressed
	if Input.is_action_just_pressed("RunSimulation"):
		for i in range(50):
			run_simulation_step()
			await get_tree().create_timer(0.05).timeout  # Small delay to see animation

func new_image_map(image:Image)-> void:
	compute_grid.update_layer(0,image)
	display_result(image)

func run_simulation_step():
	if not compute_grid:
		return
	
	# Execute the compute shader
	compute_grid.execute()
	
	# Get the result
	var result = compute_grid.get_result()
	
	# Feedback: Copy result back to layer 0 for next iteration
	compute_grid.update_layer(0, result)
	
	# Display the result
	display_result(result)
	
	step_count += 1
	print("Step %d completed" % step_count)

func display_result(result: Image):
	# Convert from R16F to RGB8 for display
	var display_img = result.duplicate()
	
	# Normalize for better visualization
	# Find max value for scaling
	var max_val = 0.0
	for y in range(display_img.get_height()):
		for x in range(display_img.get_width()):
			var pixel = display_img.get_pixel(x, y)
			max_val = max(max_val, pixel.r)
	
	# Scale values for visibility
	if max_val > 0:
		for y in range(display_img.get_height()):
			for x in range(display_img.get_width()):
				var pixel = display_img.get_pixel(x, y)
				var scaled = pixel.r / max_val
				display_img.set_pixel(x, y, Color(scaled, scaled, scaled, 1.0))
	
	display_img.convert(Image.FORMAT_RGB8)
	
	var texture = ImageTexture.create_from_image(display_img)
	TerrainGenerated.emit(texture)

func _on_step_button_pressed():
	run_simulation_step()

func _on_run_button_pressed():
	for i in range(10):
		run_simulation_step()
		await get_tree().create_timer(0.05).timeout  # Small delay to see animation

func _exit_tree():
	if compute_grid:
		compute_grid.cleanup()
