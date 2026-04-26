# Mineworld — Voxel Renderer Design

**Date:** 2026-04-25  
**Status:** Approved

## Overview

A 3D voxel world renderer written in C using raylib and stb_voxel_render.h. The goal is a fly-through renderer of a procedurally generated voxel terrain — no gameplay, no physics, just correct geometry and lighting.

## File Layout

```
mineworld/
├── src/
│   ├── main.c        — window init, game loop, render loop
│   ├── world.c/h     — chunk grid, terrain generation (stb_perlin)
│   ├── chunk.c/h     — stb_voxel_render mesh gen, GPU upload via rlgl
│   └── camera.c/h    — free-fly camera (thin wrapper around raylib Camera3D)
├── shaders/
│   ├── voxel.vert    — unpacks stb packed vertex format, applies MVP
│   └── voxel.frag    — block color lookup + AO + directional shading
├── vendor/
│   └── stb_voxel_render.h
└── build.bat
```

## Block Types

Four types, color-coded (no textures):

| ID | Name  | Color (approx)   |
|----|-------|------------------|
| 0  | AIR   | —                |
| 1  | GRASS | green            |
| 2  | DIRT  | brown            |
| 3  | STONE | grey             |

## World & Chunks

- **Chunk size:** 32 × 32 × 32 voxels of content
- **Voxel array size:** 34 × 34 × 34 — 1 voxel of padding on each face for neighbor sampling (stb_voxel_render reads neighbors to determine face visibility and AO)
- **World size:** 8 × 8 chunks generated at startup
- Border padding filled from adjacent chunks; world edges padded with AIR

## Terrain Generation

Uses `stb_perlin_noise3` (already bundled at `c:\raylib\raylib\src\external\stb_perlin.h`):

```c
for each column (x, z):
    float h = stb_perlin_noise3(x*0.03f, 0, z*0.03f, 0, 0, 0);
    int surface = 20 + (int)(h * 12);  // height in range ~8..32
    for each y:
        if y == surface:      voxel = GRASS
        else if y < surface - 3: voxel = STONE
        else if y < surface:  voxel = DIRT
        else:                 voxel = AIR
```

## stb_voxel_render Integration

Configuration: `STBVOX_CONFIG_MODE 0` (default full-terrain mode) — compact 2×uint32 per vertex, includes AO and face normals. Exact mode confirmed during implementation by reading the header.

Per-chunk mesh generation pattern:

1. Allocate a `stbvox_mesh_maker` (one per chunk, or reuse a global one)
2. Set input: the chunk's padded 34³ voxel array
3. Set output: pre-allocated vertex buffer and face buffer
4. Set chunk world origin via `stbvox_set_mesh_coordinates`
5. Call `stbvox_make_mesh()` — may need multiple calls if buffer overflows
6. Upload result to GPU via `rlgl`: create VAO + two VBOs (vertex, face)
7. Store VAO handle and vertex count in `Chunk` struct

```c
typedef struct {
    uint8_t  voxels[34*34*34];
    unsigned vao, vbo_vtx, vbo_face;
    int      vertex_count;
    bool     dirty;
} Chunk;
```

## Shader Contract

### Vertex shader inputs (from stb packed buffers)
- `attr0` (uint): packed position + face normal + AO
- `attr1` (uint): packed block type + lighting info

### Uniforms
| Name            | Type    | Source                  |
|-----------------|---------|-------------------------|
| `transform`     | mat4    | raylib camera MVP       |
| `chunk_origin`  | vec3    | chunk world position    |
| `block_colors`  | vec3[4] | CPU-side color table    |

The vertex shader unpacks position, normal, and AO from the two uint32 fields (following stb_voxel_render's example GLSL). The fragment shader multiplies block color by a directional shading term plus the AO factor.

## Camera

Thin wrapper around raylib's `Camera3D` using `UpdateCamera(&cam, CAMERA_FREE)`:
- WASD to move, mouse drag to look
- Starting position: above terrain center, looking down at an angle
- No gravity or collision

## Build Script

```bat
@echo off
set CC=c:\raylib\w64devkit\bin\gcc.exe
set RAYLIB=c:\raylib\raylib\src

%CC% src\main.c src\world.c src\chunk.c src\camera.c ^
  -I%RAYLIB% -Ivendor ^
  -L%RAYLIB% -lraylib -lopengl32 -lgdi32 -lwinmm ^
  -O1 -o mineworld.exe

if %errorlevel%==0 echo Build OK
```

## Startup Sequence

1. `InitWindow` — create window and OpenGL context
2. Load shader from `shaders/voxel.vert` + `shaders/voxel.frag`
3. Upload `block_colors` uniform table
4. Generate 8×8 chunks: fill voxel arrays using stb_perlin heightmap
5. Copy neighbor padding between adjacent chunks
6. For each chunk: run `stbvox_make_mesh` → upload VAO/VBO
7. Enter game loop:
   - `UpdateCamera` (free-fly)
   - For each chunk: set `chunk_origin` uniform, draw VAO
   - `DrawFPS` overlay
   - `EndDrawing`

## Out of Scope (for now)

- Dynamic world editing
- Chunk streaming / LOD
- Textures (color-coded blocks only)
- Gravity / collision
- Lighting beyond AO + directional
