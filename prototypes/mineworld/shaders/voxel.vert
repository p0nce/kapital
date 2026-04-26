#version 330 core

// Each uint32 uploaded as 4xGL_UNSIGNED_BYTE -> arrives as vec4 in [0,255]
layout(location = 0) in vec4 a_vtx;
layout(location = 1) in vec4 a_face;

uniform mat4 mvp;
uniform vec3 chunk_origin;

out float v_ao;
out float v_light;
out vec3  v_world_pos;
flat out uint v_btype;
flat out uint v_norm_idx;

// Normal table from stbvox_default_normals[] in stb_voxel_render.h
// RSQRT2 = 0.7071067811865, RSQRT3 = 0.5773502691896
const vec3 NORMALS[32] = vec3[32](
    vec3( 1.0,  0.0,  0.0),               // [0]  east
    vec3( 0.0,  1.0,  0.0),               // [1]  north
    vec3(-1.0,  0.0,  0.0),               // [2]  west
    vec3( 0.0, -1.0,  0.0),               // [3]  south
    vec3( 0.0,  0.0,  1.0),               // [4]  up
    vec3( 0.0,  0.0, -1.0),               // [5]  down
    vec3( 0.7071068,  0.0,  0.7071068),   // [6]  east & up
    vec3( 0.7071068,  0.0, -0.7071068),   // [7]  east & down

    vec3( 0.7071068,  0.0,  0.7071068),   // [8]  east & up
    vec3( 0.0,  0.7071068,  0.7071068),   // [9]  north & up
    vec3(-0.7071068,  0.0,  0.7071068),   // [10] west & up
    vec3( 0.0, -0.7071068,  0.7071068),   // [11] south & up
    vec3( 0.5773503,  0.5773503,  0.5773503), // [12] ne & up
    vec3( 0.5773503,  0.5773503, -0.5773503), // [13] ne & down
    vec3( 0.0,  0.7071068,  0.7071068),   // [14] north & up
    vec3( 0.0,  0.7071068, -0.7071068),   // [15] north & down

    vec3( 0.7071068,  0.0, -0.7071068),   // [16] east & down
    vec3( 0.0,  0.7071068, -0.7071068),   // [17] north & down
    vec3(-0.7071068,  0.0, -0.7071068),   // [18] west & down
    vec3( 0.0, -0.7071068, -0.7071068),   // [19] south & down
    vec3(-0.5773503,  0.5773503,  0.5773503), // [20] NW & up
    vec3(-0.5773503,  0.5773503, -0.5773503), // [21] NW & down
    vec3(-0.7071068,  0.0,  0.7071068),   // [22] west & up
    vec3(-0.7071068,  0.0, -0.7071068),   // [23] west & down

    vec3( 0.5773503,  0.5773503,  0.5773503), // [24] NE & up crossed
    vec3(-0.5773503,  0.5773503,  0.5773503), // [25] NW & up crossed
    vec3(-0.5773503, -0.5773503,  0.5773503), // [26] SW & up crossed
    vec3( 0.5773503, -0.5773503,  0.5773503), // [27] SE & up crossed
    vec3(-0.5773503, -0.5773503,  0.5773503), // [28] SW & up
    vec3(-0.5773503, -0.5773503, -0.5773503), // [29] SW & down
    vec3( 0.0, -0.7071068,  0.7071068),   // [30] south & up
    vec3( 0.0, -0.7071068, -0.7071068)    // [31] south & down
);

const vec3 SUN = normalize(vec3(0.6, 1.0, 0.4));

void main() {
    // Reconstruct uint32 from 4 byte-floats (little-endian)
    uint av = uint(a_vtx.x)  | (uint(a_vtx.y)  << 8u) | (uint(a_vtx.z)  << 16u) | (uint(a_vtx.w)  << 24u);
    uint af = uint(a_face.x) | (uint(a_face.y) << 8u) | (uint(a_face.z) << 16u) | (uint(a_face.w) << 24u);

    // Unpack position
    // STBVOX_CONFIG_PRECISION_Z defaults to 1, so z unit = 0.5
    float px = float( av        & 127u);
    float py = float((av >>  7u) & 127u);
    float pz = float((av >> 14u) & 511u) * 0.5;

    // AO: 6 bits (0=bright, 63=dark)
    float ao = float((av >> 23u) & 63u) / 63.0;
    v_ao = 1.0 - ao * 0.5;  // range [0.5, 1.0]

    // Block type from face (tex1, byte 0)
    v_btype = af & 0xFFu;

    // Face direction -> normal: face_info is byte 3 of af (bits 24-31)
    // normal_index = (face_info >> 2) & 0x1F  (bits 26-30 of af)
    uint face_info = (af >> 24u) & 0xFFu;
    uint norm_idx  = (face_info >> 2u) & 0x1Fu;

    // Directional + ambient lighting
    vec3 normal = NORMALS[norm_idx];
    v_light = clamp(dot(normal, SUN) * 0.5 + 0.6, 0.3, 1.0);

    v_norm_idx  = norm_idx;
    v_world_pos = vec3(px, py, pz) + chunk_origin;
    gl_Position = mvp * vec4(v_world_pos, 1.0);
}
