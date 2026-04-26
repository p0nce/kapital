#include "world.h"
#include <stdlib.h>
#include <string.h>

// STB_PERLIN_IMPLEMENTATION is already compiled into libraylib.a — do NOT redefine.
#include "stb_perlin.h"

static void fill_chunk(Chunk *c) {
    int wx = c->cx * CHUNK_SIZE;
    int wz = c->cz * CHUNK_SIZE;

    for (int lx = 0; lx < CHUNK_SIZE; lx++) {
        for (int lz = 0; lz < CHUNK_SIZE; lz++) {
            float h = stb_perlin_noise3((wx + lx) * 0.03f, 0.0f, (wz + lz) * 0.03f, 0, 0, 0);
            int surface = 16 + (int)(h * 10.0f);

            for (int ly = 0; ly < CHUNK_SIZE; ly++) {
                uint8_t b;
                if      (ly > surface)      b = BLOCK_AIR;
                else if (ly == surface)     b = BLOCK_GRASS;
                else if (ly >= surface - 3) b = BLOCK_DIRT;
                else                        b = BLOCK_STONE;
                c->voxels[chunk_idx(lx, ly, lz)] = b;
            }
        }
    }
}

// Copy face-neighbor border voxels into the padding of each chunk so
// stb_voxel_render can correctly cull and shade faces at chunk boundaries.
static void copy_neighbors(World *w) {
    for (int cz = 0; cz < WORLD_D; cz++) {
        for (int cx = 0; cx < WORLD_W; cx++) {
            Chunk *c = &w->chunks[cz][cx];

            // +X neighbor: fill x=CHUNK_SIZE+1 padding column
            if (cx + 1 < WORLD_W) {
                Chunk *nx = &w->chunks[cz][cx + 1];
                for (int lz = 0; lz < CHUNK_SIZE; lz++)
                    for (int ly = 0; ly < CHUNK_SIZE; ly++)
                        c->voxels[vox_idx(CHUNK_SIZE + 1, ly + 1, lz + 1)] =
                            nx->voxels[chunk_idx(0, ly, lz)];
            }
            // -X neighbor: fill x=0 padding column
            if (cx - 1 >= 0) {
                Chunk *nx = &w->chunks[cz][cx - 1];
                for (int lz = 0; lz < CHUNK_SIZE; lz++)
                    for (int ly = 0; ly < CHUNK_SIZE; ly++)
                        c->voxels[vox_idx(0, ly + 1, lz + 1)] =
                            nx->voxels[chunk_idx(CHUNK_SIZE - 1, ly, lz)];
            }
            // +Z neighbor: fill z=CHUNK_SIZE+1 padding column
            if (cz + 1 < WORLD_D) {
                Chunk *nz = &w->chunks[cz + 1][cx];
                for (int lx = 0; lx < CHUNK_SIZE; lx++)
                    for (int ly = 0; ly < CHUNK_SIZE; ly++)
                        c->voxels[vox_idx(lx + 1, ly + 1, CHUNK_SIZE + 1)] =
                            nz->voxels[chunk_idx(lx, ly, 0)];
            }
            // -Z neighbor: fill z=0 padding column
            if (cz - 1 >= 0) {
                Chunk *nz = &w->chunks[cz - 1][cx];
                for (int lx = 0; lx < CHUNK_SIZE; lx++)
                    for (int ly = 0; ly < CHUNK_SIZE; ly++)
                        c->voxels[vox_idx(lx + 1, ly + 1, 0)] =
                            nz->voxels[chunk_idx(lx, ly, CHUNK_SIZE - 1)];
            }
            // Y borders: left as zero (AIR) — open sky top, solid implied at bottom
        }
    }
}

World *world_create(void) {
    World *w = (World *)calloc(1, sizeof(World));
    for (int cz = 0; cz < WORLD_D; cz++)
        for (int cx = 0; cx < WORLD_W; cx++) {
            w->chunks[cz][cx].cx = cx;
            w->chunks[cz][cx].cz = cz;
            fill_chunk(&w->chunks[cz][cx]);
        }
    copy_neighbors(w);
    return w;
}

void world_destroy(World *w) {
    free(w);
}

uint8_t world_get_block(const World *w, int wx, int wy, int wz) {
    if (wy < 0) return BLOCK_STONE;
    if (wy >= CHUNK_SIZE) return BLOCK_AIR;
    if (wx < 0 || wz < 0 || wx >= WORLD_W * CHUNK_SIZE || wz >= WORLD_D * CHUNK_SIZE)
        return BLOCK_AIR;
    int cx = wx / CHUNK_SIZE, cz = wz / CHUNK_SIZE;
    return w->chunks[cz][cx].voxels[chunk_idx(wx % CHUNK_SIZE, wy, wz % CHUNK_SIZE)];
}
