#include "chunk.h"
#include "rlgl.h"
#include <stdlib.h>
#include <string.h>

#define STBVOX_CONFIG_MODE 0
#define STB_VOXEL_RENDER_IMPLEMENTATION
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Waggressive-loop-optimizations"
#include "stb_voxel_render.h"
#pragma GCC diagnostic pop

// Scratch buffer for stb mesh output — reused across chunks (not thread-safe)
// Mode 0: 8 bytes per vertex, 4 vertices per quad = 32 bytes/quad
static uint8_t s_mesh_buf[MAX_QUADS * 32];

void chunk_build_mesh(Chunk *c) {
    chunk_free_mesh(c);

    stbvox_mesh_maker mm;
    stbvox_init_mesh_maker(&mm);

    stbvox_input_description *desc = stbvox_get_input_description(&mm);
    desc->blocktype = c->voxels;

    // Array layout is [x][y][z] (X-slow, Z-fast/consecutive).
    // stb axis mapping: stb-X = world-X, stb-Y = world-Y (height/up), stb-Z = world-Z.
    // x_stride = CHUNK_PAD * CHUNK_PAD bytes, y_stride = CHUNK_PAD bytes.
    // Z is implicit stride-1 (consecutive in memory).
    // Note: declaration says "in_elements" but stb implementation (line 3635) treats
    // these as bytes — verified. For uint8_t arrays, bytes = elements, so no issue.
    stbvox_set_input_stride(&mm, CHUNK_PAD * CHUNK_PAD, CHUNK_PAD);

    // Mesh the inner [1..CHUNK_SIZE+1) region, skipping the 1-voxel padding border.
    stbvox_set_input_range(&mm, 1, 1, 1, CHUNK_SIZE + 1, CHUNK_SIZE + 1, CHUNK_SIZE + 1);

    // World-space offset: bakes world position into output vertex coords.
    stbvox_set_mesh_coordinates(&mm, c->cx * CHUNK_SIZE, 0, c->cz * CHUNK_SIZE);

    // Mode 0: one interleaved buffer (slot 0) holding (attr_vertex, attr_face) per vertex.
    stbvox_set_buffer(&mm, 0, 0, s_mesh_buf, sizeof(s_mesh_buf));

    // Returns 1 when done, 0 when output buffer full (call again to continue).
    while (!stbvox_make_mesh(&mm)) {}

    int nq = stbvox_get_quad_count(&mm, 0);
    if (nq == 0) return;

    // Build index buffer: two triangles (0,1,2, 0,2,3) per quad.
    // uint16_t is safe: terrain max exposed quads ≈ 6×32² = 6144, well below 16383 limit.
    uint16_t *idx = (uint16_t *)malloc(nq * 6 * sizeof(uint16_t));
    for (int q = 0; q < nq; q++) {
        idx[q*6+0] = (uint16_t)(q*4+0); idx[q*6+1] = (uint16_t)(q*4+2);
        idx[q*6+2] = (uint16_t)(q*4+1); idx[q*6+3] = (uint16_t)(q*4+0);
        idx[q*6+4] = (uint16_t)(q*4+3); idx[q*6+5] = (uint16_t)(q*4+2);
    }

    // Upload to GPU via rlgl
    c->vao = rlLoadVertexArray();
    rlEnableVertexArray(c->vao);

    // s_mesh_buf already in GpuVertex layout: (attr_vertex uint32, attr_face uint32) per vertex
    c->vbo = rlLoadVertexBuffer(s_mesh_buf, nq * 4 * (int)sizeof(GpuVertex), false);
    rlEnableVertexBuffer(c->vbo);

    // Read each uint32 as 4 bytes (GL_UNSIGNED_BYTE=0x1401, compSize=4).
    // glVertexAttribPointer converts each byte to float [0..255] — exactly representable.
    // The shader receives vec4 and reconstructs the uint32 from 4 byte-floats.
    // This avoids glVertexAttribIPointer (not wrapped by rlgl) while preserving all bits.
    rlSetVertexAttribute(0, 4, 0x1401, false, (int)sizeof(GpuVertex), 0);
    rlEnableVertexAttribute(0);
    rlSetVertexAttribute(1, 4, 0x1401, false, (int)sizeof(GpuVertex), (int)sizeof(uint32_t));
    rlEnableVertexAttribute(1);
    rlDisableVertexBuffer();

    // IBO bound inside VAO scope — automatically associated with this VAO
    c->ibo = rlLoadVertexBufferElement(idx, nq * 6 * (int)sizeof(uint16_t), false);

    rlDisableVertexArray();
    free(idx);

    c->quad_count = nq;
}

void chunk_free_mesh(Chunk *c) {
    if (c->vao) { rlUnloadVertexArray(c->vao); c->vao = 0; }
    if (c->vbo) { rlUnloadVertexBuffer(c->vbo); c->vbo = 0; }
    if (c->ibo) { rlUnloadVertexBuffer(c->ibo); c->ibo = 0; }
    c->quad_count = 0;
}
