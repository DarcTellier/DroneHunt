shader_type canvas_item;


uniform float spacing : hint_range(2.0, 200.0, 1.0) = 25.0;

uniform float animation_progress :
	hint_range(0.0, 1.0, 0.001) = 0.0;

uniform float dot_size :
	hint_range(0.0, 2.0, 0.01) = 1.0;

uniform vec4 dot_color :
	source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform float direction_degrees :
	hint_range(0.0, 360.0, 1.0) = 45.0;

uniform float transition_softness :
	hint_range(0.01, 1.0, 0.01) = 0.3;


void fragment() {
	if (animation_progress <= 0.0) {
		discard;
	}

	vec2 screen_size = vec2(1.0) / SCREEN_PIXEL_SIZE;

	vec2 grid_count = floor(
		screen_size / spacing
	);

	vec2 safe_grid_size = max(
		grid_count * spacing,
		vec2(1.0)
	);

	vec2 normalized_position = (
		UV * screen_size
	) / safe_grid_size;

	float angle_radians = radians(
		direction_degrees
	);

	vec2 direction = vec2(
		cos(angle_radians),
		sin(angle_radians)
	);

	vec2 centered_position = (
		normalized_position - vec2(0.5)
	);

	float delay = dot(
		centered_position,
		direction
	);

	/*
	The longest projection across a square is sqrt(2) / 2.

	Multiplying by sqrt(2) / 2 converts the projection
	into a useful approximate 0–1 range for every angle.
	*/
	delay = (
		delay * 0.70710678
	) + 0.5;

	delay = clamp(
		delay,
		0.0,
		1.0
	);

	float visible_threshold = (
		delay * 0.1
	) + 0.01;

	if (
		animation_progress
		< visible_threshold
	) {
		discard;
	}

	float scale = smoothstep(
		delay - transition_softness,
		delay + transition_softness,
		animation_progress
			* (1.0 + transition_softness)
	);

	if (scale < 0.005) {
		discard;
	}

	vec2 grid_position = (
		UV * screen_size / spacing
	);

	vec2 grid_center = (
		floor(grid_position) + 0.5
	) * spacing;

	float distance_from_center = length(
		UV * screen_size - grid_center
	);

	float dot_radius = (
		dot_size
		* scale
		* spacing
		* 0.8
	);

	float alpha = 1.0 - smoothstep(
		max(dot_radius - 1.5, 0.0),
		dot_radius + 1.5,
		distance_from_center
	);

	if (alpha < 0.01) {
		discard;
	}

	COLOR = vec4(
		dot_color.rgb,
		alpha * dot_color.a
	);
}