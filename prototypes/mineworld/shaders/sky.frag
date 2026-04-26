#version 330 core

in vec2 v_ndc;

uniform vec3  cam_fwd;
uniform vec3  cam_right;
uniform vec3  cam_up;
uniform float tan_half_fov;
uniform float aspect;

out vec4 frag_color;

void main() {
    vec3 dir = normalize(cam_fwd
                       + cam_right * (v_ndc.x * aspect * tan_half_fov)
                       + cam_up    * (v_ndc.y * tan_half_fov));

    float h = dir.y;

    // Sky gradient: horizon to zenith
    float t = clamp(h * 3.0 + 0.1, 0.0, 1.0);
    vec3 zenith  = vec3(0.08, 0.22, 0.58);
    vec3 horizon = vec3(0.60, 0.78, 0.98);
    vec3 sky = mix(horizon, zenith, pow(t, 0.5));

    // Horizon haze brightening
    float haze = exp(-abs(h) * 4.0);
    sky = mix(sky, vec3(0.82, 0.88, 0.98), haze * 0.45);

    // Ground tint below horizon
    if (h < 0.0)
        sky = mix(sky, vec3(0.28, 0.22, 0.16), clamp(-h * 6.0, 0.0, 1.0));

    // Sun disc + halo (matches SUN in voxel.vert)
    const vec3 SUN_DIR = normalize(vec3(0.6, 1.0, 0.4));
    float sd = max(dot(dir, SUN_DIR), 0.0);
    sky += vec3(1.00, 0.96, 0.72) * pow(sd, 512.0) * 8.0;
    sky += vec3(1.00, 0.80, 0.45) * pow(sd,  12.0) * 0.25;

    frag_color = vec4(sky, 1.0);
}
