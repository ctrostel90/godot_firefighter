#[compute]
#version 450

// Work group size (8x8 = 64 threads)
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

// Input texture layers (bindings 0-9 for 10 layers)
layout(set = 0, binding = 0) uniform sampler2D input_layer_0;
layout(set = 0, binding = 1) uniform sampler2D input_layer_1;
layout(set = 0, binding = 2) uniform sampler2D input_layer_2;
layout(set = 0, binding = 3) uniform sampler2D input_layer_3;
layout(set = 0, binding = 4) uniform sampler2D input_layer_4;
layout(set = 0, binding = 5) uniform sampler2D input_layer_5;
layout(set = 0, binding = 6) uniform sampler2D input_layer_6;
layout(set = 0, binding = 7) uniform sampler2D input_layer_7;
layout(set = 0, binding = 8) uniform sampler2D input_layer_8;
layout(set = 0, binding = 9) uniform sampler2D input_layer_9;

// Output texture (binding 10)
layout(set = 0, binding = 10, r16f) uniform writeonly image2D output_layer;

// Grid dimensions (you can pass these as push constants if needed)
// For now, we get them from the image size
ivec2 grid_size;

// Helper function: Sample a specific layer at exact coordinates
float sample_layer(int layer_idx, ivec2 coords) {
	vec2 uv = (vec2(coords) + 0.5) / vec2(grid_size);
	
	// Manual layer indexing since GLSL doesn't support dynamic array access for samplers
	if (layer_idx == 0) return texture(input_layer_0, uv).r;
	if (layer_idx == 1) return texture(input_layer_1, uv).r;
	if (layer_idx == 2) return texture(input_layer_2, uv).r;
	if (layer_idx == 3) return texture(input_layer_3, uv).r;
	if (layer_idx == 4) return texture(input_layer_4, uv).r;
	if (layer_idx == 5) return texture(input_layer_5, uv).r;
	if (layer_idx == 6) return texture(input_layer_6, uv).r;
	if (layer_idx == 7) return texture(input_layer_7, uv).r;
	if (layer_idx == 8) return texture(input_layer_8, uv).r;
	if (layer_idx == 9) return texture(input_layer_9, uv).r;
	return 0.0;
}

// Helper function: Sample layer with offset from current position
float sample_layer_offset(int layer_idx, ivec2 current_pos, ivec2 offset) {
	ivec2 sample_pos = current_pos + offset;
	
	// Clamp to grid boundaries
	sample_pos = clamp(sample_pos, ivec2(0), grid_size - 1);
	
	return sample_layer(layer_idx, sample_pos);
}

// Helper function: Sample 3x3 neighborhood around current position
float[9] sample_layer_kernel3x3(int layer_idx, ivec2 current_pos) {
	float kernel[9];
	int idx = 0;
	
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			kernel[idx++] = sample_layer_offset(layer_idx, current_pos, ivec2(x, y));
		}
	}
	
	return kernel;
}

// Helper function: Sample 5x5 neighborhood
float[25] sample_layer_kernel5x5(int layer_idx, ivec2 current_pos) {
	float kernel[25];
	int idx = 0;
	
	for (int y = -2; y <= 2; y++) {
		for (int x = -2; x <= 2; x++) {
			kernel[idx++] = sample_layer_offset(layer_idx, current_pos, ivec2(x, y));
		}
	}
	
	return kernel;
}

// ============================================================================
// IMPLEMENT THIS FUNCTION IN YOUR EXTENDED SHADER
// ============================================================================
// This function is called for each cell in the grid
// Parameters:
//   - cell_pos: The current cell's position (x, y)
// Returns:
//   - The computed value for this cell
//
// Use the helper functions above to sample input layers:
//   - sample_layer(layer_index, coords)
//   - sample_layer_offset(layer_index, current_pos, offset)
//   - sample_layer_kernel3x3(layer_index, current_pos)
//   - sample_layer_kernel5x5(layer_index, current_pos)
// ============================================================================

float compute_cell(ivec2 cell_pos) {
	// EXAMPLE: Simple passthrough of layer 0
	return sample_layer(0, cell_pos);
}

// ============================================================================
// Main compute shader (DO NOT MODIFY)
// ============================================================================

void main() {
	ivec2 cell_pos = ivec2(gl_GlobalInvocationID.xy);
	grid_size = imageSize(output_layer);
	
	// Bounds check
	if (cell_pos.x >= grid_size.x || cell_pos.y >= grid_size.y) {
		return;
	}
	
	// Compute the cell value
	float result = compute_cell(cell_pos);
	
	// Write to output
	imageStore(output_layer, cell_pos, vec4(result, 0.0, 0.0, 0.0));
}
