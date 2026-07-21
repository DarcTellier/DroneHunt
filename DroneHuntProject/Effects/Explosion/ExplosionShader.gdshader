shader_type canvas_item;

uniform vec3 boom_pal1 : source_color = vec3(0.2, 0.15, 0.3);
uniform vec3 boom_pal2 : source_color = vec3(0.9, 0.15, 0.05);
uniform vec3 boom_pal3 : source_color = vec3(0.9, 0.5, 0.1);
uniform vec3 boom_pal4 : source_color = vec3(0.95, 0.95, 0.35);

uniform vec3 smoke_pal1 : source_color = vec3(0.2, 0.15, 0.3);
uniform vec3 smoke_pal2 : source_color = vec3(0.35, 0.3, 0.45);
uniform vec3 smoke_pal3 : source_color = vec3(0.5, 0.45, 0.6);

uniform float progress : hint_range(0.0, 1.0) = 0.0;

uniform float size : hint_range(0.1, 50.0, 0.1) = 5.0;
uniform float disperse : hint_range(0.1, 10.0, 0.1) = 1.0;

uniform float boom_shape : hint_range(0.1, 20.0, 0.1) = 12.0;
uniform float boom_distortion : hint_range(0.0, 10.0, 0.1) = 0.5;
uniform float boom_bubbles : hint_range(0.0, 10.0, 0.1) = 0.5;
uniform float boom_bw : hint_range(0.0, 1.0, 0.01) = 0.5;

uniform float smoke_shape : hint_range(0.1, 30.0, 0.1) = 16.0;
uniform float smoke_distortion : hint_range(0.0, 10.0, 0.1) = 1.5;
uniform float smoke_bubbles : hint_range(0.0, 10.0, 0.1) = 0.5;
uniform float smoke_bw : hint_range(0.0, 1.0, 0.01) = 0.75;

uniform vec2 displacement = vec2(0.0);
uniform float edge_softness : hint_range(0.001, 0.2, 0.001) = 0.025;


vec3 random_3d(vec3 position) {
	vec3 result = fract(
		sin(
			vec3(
				dot(position, vec3(127.1, 311.7, 371.8)),
				dot(position, vec3(269.5, 183.3, 456.1)),
				dot(position, vec3(352.5, 207.3, 198.67))
			)
		) * 43758.5453
	) * 2.0 - 1.0;

	return normalize(
		vec3(
			result.x / cos(result.x),
			result.y / cos(result.y),
			result.z / cos(result.z)
		)
	);
}


float noise_3d(vec3 position) {
	vec3 fractional = fract(position);
	vec3 integer = floor(position);

	vec3 smooth_value = fractional
		* fractional
		* fractional
		* (
			fractional
			* (
				fractional * 6.0 - 15.0
			)
			+ 10.0
		);

	return mix(
		mix(
			mix(
				dot(
					random_3d(integer + vec3(0.0, 0.0, 0.0)),
					fractional - vec3(0.0, 0.0, 0.0)
				),
				dot(
					random_3d(integer + vec3(1.0, 0.0, 0.0)),
					fractional - vec3(1.0, 0.0, 0.0)
				),
				smooth_value.x
			),
			mix(
				dot(
					random_3d(integer + vec3(0.0, 1.0, 0.0)),
					fractional - vec3(0.0, 1.0, 0.0)
				),
				dot(
					random_3d(integer + vec3(1.0, 1.0, 0.0)),
					fractional - vec3(1.0, 1.0, 0.0)
				),
				smooth_value.x
			),
			smooth_value.y
		),
		mix(
			mix(
				dot(
					random_3d(integer + vec3(0.0, 0.0, 1.0)),
					fractional - vec3(0.0, 0.0, 1.0)
				),
				dot(
					random_3d(integer + vec3(1.0, 0.0, 1.0)),
					fractional - vec3(1.0, 0.0, 1.0)
				),
				smooth_value.x
			),
			mix(
				dot(
					random_3d(integer + vec3(0.0, 1.0, 1.0)),
					fractional - vec3(0.0, 1.0, 1.0)
				),
				dot(
					random_3d(integer + vec3(1.0, 1.0, 1.0)),
					fractional - vec3(1.0, 1.0, 1.0)
				),
				smooth_value.x
			),
			smooth_value.y
		),
		smooth_value.z
	);
}


float worley(vec3 sample_position, float animation_time) {
	vec3 integer_position = floor(sample_position);
	vec3 fractional_position = fract(sample_position);

	float minimum_distance = 1.0;

	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			for (int z = -1; z <= 1; z++) {
				vec3 neighbor = vec3(
					float(x),
					float(y),
					float(z)
				);

				vec3 point = fract(
					random_3d(integer_position + neighbor)
				);

				point = 0.5 + 0.5 * sin(
					disperse * animation_time
					+ 6.2831 * point
				);

				vec3 difference = neighbor
					+ point
					- fractional_position;

				minimum_distance = min(
					minimum_distance,
					length(difference)
				);
			}
		}
	}

	return minimum_distance;
}


float boom(vec2 position, float animation_time) {
	float time_value = max(animation_time, 0.001);

	float shape = 1.0
		- pow(length(position), 2.0)
		/ (time_value * boom_shape)
		- time_value * 2.0;

	float distortion = noise_3d(
		vec3(
			position * boom_distortion,
			animation_time * 0.5
		)
	);

	float bubbles = boom_bubbles - pow(
		worley(
			vec3(
				position * 1.2,
				animation_time * 2.0
			),
			animation_time
		),
		3.0
	);

	return shape + mix(
		distortion,
		bubbles,
		boom_bw
	);
}


float smoke(vec2 position, float animation_time) {
	float time_value = max(animation_time, 0.001);

	vec2 rise_offset = vec2(0.0, 2.0)
		* pow(time_value / 1.45, 2.0)
		* 1.5;

	float shape = 1.0
		- pow(
			length(position - rise_offset),
			2.0
		)
		/ (time_value * smoke_shape)
		- sqrt(time_value * 1.5);

	float distortion = noise_3d(
		vec3(
			position * smoke_distortion - rise_offset,
			animation_time * 0.1
		)
	);

	float scaled_time = max(
		pow(time_value, 0.35),
		0.001
	);

	float bubbles = smoke_bubbles - pow(
		worley(
			vec3(
				position / scaled_time - rise_offset,
				animation_time * 0.1
			),
			animation_time
		),
		2.0
	);

	return shape + mix(
		distortion,
		bubbles,
		smoke_bw
	);
}


vec3 get_boom_color(float value) {
	float normalized = clamp(value, 0.0, 0.9999);

	if (normalized < 0.25) {
		return boom_pal1;
	}

	if (normalized < 0.5) {
		return boom_pal2;
	}

	if (normalized < 0.75) {
		return boom_pal3;
	}

	return boom_pal4;
}


vec3 get_smoke_color(float value) {
	float normalized = clamp(value, 0.0, 0.9999);

	if (normalized < 0.3333) {
		return smoke_pal1;
	}

	if (normalized < 0.6666) {
		return smoke_pal2;
	}

	return smoke_pal3;
}


void fragment() {
	vec2 position = UV - vec2(0.5);

	position.x *= TEXTURE_PIXEL_SIZE.y
		/ max(TEXTURE_PIXEL_SIZE.x, 0.00001);

	position *= size;
	position -= displacement;

	float animation_time = progress * 2.0;

	float boom_value = boom(
		position,
		animation_time
	);

	float smoke_value = smoke(
		position,
		animation_time
	);

	float boom_alpha = smoothstep(
		-edge_softness,
		edge_softness,
		boom_value
	);

	float smoke_alpha = smoothstep(
		-edge_softness,
		edge_softness,
		smoke_value
	);

	vec3 boom_color = get_boom_color(
		clamp(boom_value, 0.0, 1.0)
	);

	vec3 smoke_color = get_smoke_color(
		clamp(smoke_value, 0.0, 1.0)
	);

	float use_boom = step(
		smoke_value * 1.25,
		boom_value
	);

	vec3 final_color = mix(
		smoke_color,
		boom_color,
		use_boom
	);

	float alpha = mix(
		smoke_alpha,
		boom_alpha,
		use_boom
	);

	float lifetime_fade = 1.0 - smoothstep(
		0.72,
		1.0,
		progress
	);

	alpha *= lifetime_fade;

	COLOR = vec4(
		final_color,
		alpha
	);
}