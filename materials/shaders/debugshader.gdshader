shader_type spatial;

uniform bool showNormals;
uniform bool showUvs;
uniform float explode = 0.1;
uniform float uvExplode = 0.0;

void vertex() {
	VERTEX += NORMAL * explode;
	VERTEX += NORMAL * UV.x * uvExplode;
	VERTEX += TANGENT * UV.y * uvExplode;
}

void fragment() {
	// Called for every pixel the material is visible on.
	if (showUvs)
		ALBEDO = vec3(UV, 0.0);
	if (showNormals)
		ALBEDO = NORMAL * .5 + .5;
}

void light() {
	// Called for every pixel for every light affecting the material.
}
