#pragma once
#include <stdint.h>

#define CHUNK_SIZE  32
#define CHUNK_PAD   (CHUNK_SIZE + 2)   // 34 = +1 padding each face for neighbor sampling
#define WORLD_W     8                   // chunks along X
#define WORLD_D     8                   // chunks along Z
#define MAX_QUADS   (CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE * 3)  // safe upper bound

typedef enum {
    BLOCK_AIR   = 0,
    BLOCK_GRASS = 1,
    BLOCK_DIRT  = 2,
    BLOCK_STONE = 3,
} BlockType;

typedef struct {
    // Padded voxel array layout: [x][y][z], dimensions CHUNK_PAD each axis.
    // Layout is X-slowest, Z-fastest (Z consecutive in memory).
    // This matches stb_voxel_render's stride convention where Z is the implicit fast axis.
    uint8_t voxels[CHUNK_PAD * CHUNK_PAD * CHUNK_PAD];

    // GPU handles (0 = not uploaded)
    unsigned int vao;
    unsigned int vbo;
    unsigned int ibo;
    int quad_count;

    int cx, cz;  // chunk grid position
} Chunk;

typedef struct {
    Chunk chunks[WORLD_D][WORLD_W];  // [cz][cx]
} World;

// Flat index for padded array with layout [x][y][z].
// coords x, y, z in range [0, CHUNK_PAD)
static inline int vox_idx(int x, int y, int z) {
    return x * CHUNK_PAD * CHUNK_PAD + y * CHUNK_PAD + z;
}

// Index for chunk-local coords [0, CHUNK_SIZE), shifted +1 for the padding border.
static inline int chunk_idx(int x, int y, int z) {
    return vox_idx(x + 1, y + 1, z + 1);
}

World  *world_create(void);
void    world_destroy(World *w);
uint8_t world_get_block(const World *w, int wx, int wy, int wz);
