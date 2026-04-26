#version 330 core

in  float v_ao;
in  float v_light;
in  vec3  v_world_pos;
flat in uint v_btype;
flat in uint v_norm_idx;

out vec4 frag_color;

// Simple integer hash — gives consistent per-texel noise value in [0,1)
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    // Pick two world axes as UV based on face orientation.
    // norm_idx 1=(0,1,0)up  3=(0,-1,0)down  0/2=east/west  4/5=north/south
    vec2 uv;
    if (v_norm_idx == 1u || v_norm_idx == 3u)
        uv = v_world_pos.xz;                // top/bottom: X and Z
    else if (v_norm_idx == 0u || v_norm_idx == 2u)
        uv = v_world_pos.zy;                // east/west:  Z and Y
    else
        uv = v_world_pos.xy;                // north/south: X and Y

    // 16 texels per block, consistent world-space hash per texel
    float n = (hash(floor(uv * 16.0)) - 0.5) * 0.10;

    vec3 base;
    if (v_btype == 1u) {  // GRASS
        bool is_top        = (v_norm_idx == 1u);
        bool is_grass_side = (v_norm_idx != 1u && v_norm_idx != 3u)
                             && fract(v_world_pos.y) > 0.75;
        if (is_top || is_grass_side)
            base = vec3(0.35, 0.65, 0.20) + n;
        else
            base = vec3(0.50, 0.33, 0.18) + n;  // dirt side/bottom
    } else if (v_btype == 2u) {  // DIRT
        base = vec3(0.50, 0.33, 0.18) + n;
    } else {  // STONE
        float n2 = (hash(floor(uv * 16.0) + 3.7) - 0.5) * 0.08;
        base = vec3(0.55 + n, 0.55 + n * 0.9 + n2, 0.55 + n);
    }

    frag_color = vec4(base * v_ao * v_light, 1.0);
}
