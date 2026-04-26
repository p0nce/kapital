#pragma once
#include "world.h"
#include <stdint.h>

// One GPU vertex = stb attr_vertex uint32 + stb attr_face uint32 (interleaved by stb in mode 0).
// Uploaded as 4×GL_UNSIGNED_BYTE each (compSize=4), so the shader receives vec4 in [0,255]
// and reconstructs the uint32 via bitwise ops. This avoids glVertexAttribIPointer.
typedef struct {
    uint32_t vtx;
    uint32_t face;
} GpuVertex;

void chunk_build_mesh(Chunk *c);
void chunk_free_mesh(Chunk *c);
