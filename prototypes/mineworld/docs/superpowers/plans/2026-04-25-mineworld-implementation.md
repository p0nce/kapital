# Mineworld Voxel Renderer — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a 3D voxel world renderer in C using raylib and stb_voxel_render, with stb_perlin procedural terrain and a free-fly camera.

**Architecture:** stb_voxel_render generates packed quad geometry from a 34³ padded voxel array per chunk; the output is interleaved (vtx+face uint32 per vertex) and uploaded via rlgl to a VAO+VBO; a custom GLSL shader unpacks the bit-packed vertex format and shades by block color × AO × directional light. raylib's Camera3D handles free-fly input.

**Tech Stack:** C11, raylib 5.x (headers+lib at `c:\raylib\raylib\src`), stb_voxel_render.h (to download), stb_perlin.h (bundled at `c:\raylib\raylib\src\external\stb_perlin.h`), w64devkit gcc (`c:\raylib\w64devkit\bin\gcc.exe`).

---

## File Map

| File | Responsibility |
|------|----------------|
| `src/main.c` | Window init, game loop, render loop |
| `src/world.h` | Block type enum, `Chunk` struct, `World` struct, voxel index helpers |
| `src/world.c` | Terrain generation (stb_perlin), neighbor padding, alloc/free |
| `src/chunk.h` | `GpuVertex` layout, `chunk_build_mesh` / `chunk_free_mesh` declarations |
| `src/chunk.c` | stb_voxel_render integration, interleave vtx+face, rlgl VAO/VBO/IBO upload |
| `src/camera.h` | `camera_create` / `camera_update` declarations |
| `src/camera.c` | Thin wrapper around raylib `Camera3D` + `UpdateCamera(CAMERA_FREE)` |
| `shaders/voxel.vert` | Unpack stb packed vertex bits, compute world pos + lighting |
| `shaders/voxel.frag` | Block color table lookup, AO × light shading |
| `vendor/stb_voxel_render.h` | External header — mesh geometry generator |
| `build.bat` | Compile script using w64devkit gcc |

---

### Task 1: Project scaffold + working window

**Files:**
- Create: `src/main.c`, `src/world.c` (stub), `src/chunk.c` (stub), `src/camera.c` (stub)
- Create: `build.bat`

- [ ] Create directory structure (run from `D:\kapital\mineworld`):
  ```bat
  mkdir src shaders vendor docs\superpowers\plans docs\superpowers\specs
  ```

- [ ] Create `build.bat`:
  ```bat
  @echo off
  set CC=c:\raylib\w64devkit\bin\gcc.exe
  set RAYLIB=c:\raylib\raylib\src

  %CC% src\main.c src\world.c src\chunk.c src\camera.c ^
    -I%RAYLIB% -I%RAYLIB%\external -Ivendor -Isrc ^
    -L%RAYLIB% -lraylib -lopengl32 -lgdi32 -lwinmm ^
    -O1 -o mineworld.exe 2>&1

  if %errorlevel%==0 (echo Build OK) else (echo Build FAILED && exit /b 1)
  ```

- [ ] Create `src/main.c`:
  ```c
  #include "raylib.h"

  int main(void) {
      InitWindow(1280, 720, "mineworld");
      SetTargetFPS(60);
      while (!WindowShouldClose()) {
          BeginDrawing();
          ClearBackground(SKYBLUE);
          DrawFPS(10, 10);
          EndDrawing();
      }
      CloseWindow();
      return 0;
  }
  ```

- [ ] Create empty stub files so the compiler doesn't fail:
  ```c
  // src/world.c  — one line: #include "world.h"
  // src/chunk.c  — one line: #include "chunk.h"
  // src/camera.c — one line: #include "camera.h"
  ```
  Also create minimal headers they reference:
  ```c
  // src/world.h  — #pragma once
  // src/chunk.h  — #pragma once
  // src/camera.h — #pragma once
  ```

- [ ] Run `build.bat`. Expected output: `Build OK`. Launch `mineworld.exe` — sky-blue window with FPS counter.

- [ ] Commit:
  ```
  git add src/ shaders/ vendor/ build.bat
  git commit -m "feat: project scaffold, working window"
  ```

---

### Task 2: Acquire stb_voxel_render.h and study its API

**Files:**
- Create: `vendor/stb_voxel_render.h`

- [ ] Download stb_voxel_render.h into `vendor/`:
  ```bat
  c:\raylib\w64devkit\bin\curl.exe -Lo vendor\stb_voxel_render.h ^
    https://raw.githubusercontent.com/nothings/stb/master/stb_voxel_render.h
  ```

- [ ] Open `vendor/stb_voxel_render.h` and find and note these specific details (they affect Tasks 5 and 6):

  1. **Config mode** — search `STBVOX_CONFIG_MODE`. Find what value gives a simple terrain mode with AO and face normals. Mode `0` is the default full-terrain mode — confirm it is defined and what it enables.

  2. **stbvox_set_input_stride signature** — search `stbvox_set_input_stride`. Note the parameter names and what "x stride" and "z stride" mean (number of array elements to skip per axis step).

  3. **stbvox_set_buffer** — search `stbvox_set_buffer`. Note how buffer index 0 vs 1 maps to vertex vs face output.

  4. **stbvox_make_mesh return value** — search `stbvox_make_mesh`. Note: does it return 0 when incomplete (buffer full) and non-zero when done, or the reverse?

  5. **Vertex bit layout** — search the header for GLSL shader examples or bit-field documentation. Find where `attr0` and `attr1` bits are defined (position bits, AO bits, face direction bits, block-type bits). Note the exact bit positions — you will need these in Task 6.

- [ ] Commit:
  ```
  git add vendor/stb_voxel_render.h
  git commit -m "vendor: add stb_voxel_render.h"
  ```

---

### Task 3: Block types and world/chunk structs (world.h)

**Files:**
- Modify: `src/world.h`

- [ ] Replace `src/world.h` with:
  ```c
  #pragma once
  #include <stdint.h>
  #include <stdbool.h>

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
      // Padded voxel array [CHUNK_PAD³], layout [z][y][x]
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

  // Flat array index for padded array, coords in [0, CHUNK_PAD)
  static inline int vox_idx(int x, int y, int z) {
      return z * CHUNK_PAD * CHUNK_PAD + y * CHUNK_PAD + x;
  }

  // Index for chunk-local coords in [0, CHUNK_SIZE), shifted by the 1-voxel padding
  static inline int chunk_idx(int x, int y, int z) {
      return vox_idx(x + 1, y + 1, z + 1);
  }

  World *world_create(void);
  void   world_destroy(World *w);
  ```

- [ ] Verify build still compiles:
  ```
  build.bat
  ```

- [ ] Commit:
  ```
  git add src/world.h
  git commit -m "feat: block types, Chunk and World structs"
  ```

---

### Task 4: Terrain generation (world.c)

**Files:**
- Modify: `src/world.c`

- [ ] Replace `src/world.c` with:
  ```c
  #include "world.h"
  #include <stdlib.h>
  #include <string.h>

  #define STB_PERLIN_IMPLEMENTATION
  #include "stb_perlin.h"

  static void fill_chunk(Chunk *c) {
      int wx = c->cx * CHUNK_SIZE;
      int wz = c->cz * CHUNK_SIZE;

      for (int lz = 0; lz < CHUNK_SIZE; lz++) {
          for (int lx = 0; lx < CHUNK_SIZE; lx++) {
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

  // Copy the face-neighbor borders between adjacent chunks so stb_voxel_render
  // can correctly cull and shade faces at chunk boundaries.
  static void copy_neighbors(World *w) {
      for (int cz = 0; cz < WORLD_D; cz++) {
          for (int cx = 0; cx < WORLD_W; cx++) {
              Chunk *c = &w->chunks[cz][cx];

              // +X face: padding column at x = CHUNK_SIZE+1
              if (cx + 1 < WORLD_W) {
                  Chunk *nx = &w->chunks[cz][cx + 1];
                  for (int lz = 0; lz < CHUNK_SIZE; lz++)
                      for (int ly = 0; ly < CHUNK_SIZE; ly++)
                          c->voxels[vox_idx(CHUNK_SIZE + 1, ly + 1, lz + 1)] =
                              nx->voxels[chunk_idx(0, ly, lz)];
              }
              // -X face: padding column at x = 0
              if (cx - 1 >= 0) {
                  Chunk *nx = &w->chunks[cz][cx - 1];
                  for (int lz = 0; lz < CHUNK_SIZE; lz++)
                      for (int ly = 0; ly < CHUNK_SIZE; ly++)
                          c->voxels[vox_idx(0, ly + 1, lz + 1)] =
                              nx->voxels[chunk_idx(CHUNK_SIZE - 1, ly, lz)];
              }
              // +Z face
              if (cz + 1 < WORLD_D) {
                  Chunk *nz = &w->chunks[cz + 1][cx];
                  for (int lx = 0; lx < CHUNK_SIZE; lx++)
                      for (int ly = 0; ly < CHUNK_SIZE; ly++)
                          c->voxels[vox_idx(lx + 1, ly + 1, CHUNK_SIZE + 1)] =
                              nz->voxels[chunk_idx(lx, ly, 0)];
              }
              // -Z face
              if (cz - 1 >= 0) {
                  Chunk *nz = &w->chunks[cz - 1][cx];
                  for (int lx = 0; lx < CHUNK_SIZE; lx++)
                      for (int ly = 0; ly < CHUNK_SIZE; ly++)
                          c->voxels[vox_idx(lx + 1, ly + 1, 0)] =
                              nz->voxels[chunk_idx(lx, ly, CHUNK_SIZE - 1)];
              }
              // Y borders: leave as AIR (open sky top, solid implied at bottom)
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
  ```

- [ ] Build and verify no compile errors:
  ```
  build.bat
  ```

- [ ] Commit:
  ```
  git add src/world.c
  git commit -m "feat: terrain generation with stb_perlin, neighbor padding"
  ```

---

### Task 5: Chunk mesh generation and GPU upload (chunk.h + chunk.c)

**Files:**
- Modify: `src/chunk.h`
- Modify: `src/chunk.c`

**Prerequisite:** You read the stb_voxel_render.h API in Task 2. Confirm the exact signatures of `stbvox_set_input_stride`, `stbvox_set_buffer`, and `stbvox_make_mesh` before writing this task.

- [ ] Replace `src/chunk.h`:
  ```c
  #pragma once
  #include "world.h"
  #include <stdint.h>

  // One GPU vertex = stb vertex uint32 + stb face uint32 (face replicated 4× per quad)
  typedef struct {
      uint32_t vtx;
      uint32_t face;
  } GpuVertex;

  void chunk_build_mesh(Chunk *c);
  void chunk_free_mesh(Chunk *c);
  ```

- [ ] Replace `src/chunk.c`:
  ```c
  #include "chunk.h"
  #include "rlgl.h"
  #include <stdlib.h>
  #include <string.h>

  #define STB_VOXEL_RENDER_IMPLEMENTATION
  #include "stb_voxel_render.h"

  // Static scratch buffers — reused per chunk build (not thread-safe)
  static uint32_t  s_vtx_buf[MAX_QUADS * 4];
  static uint32_t  s_face_buf[MAX_QUADS];
  static GpuVertex s_gpu[MAX_QUADS * 4];

  void chunk_build_mesh(Chunk *c) {
      chunk_free_mesh(c);

      stbvox_mesh_maker mm;
      stbvox_init_mesh_maker(&mm);

      stbvox_input_description *desc = stbvox_get_input_description(&mm);
      desc->blocktype = c->voxels;

      // x-stride = 1, z-stride = CHUNK_PAD*CHUNK_PAD for layout [z][y][x]
      // Verify these match the stb header's stride convention before building.
      stbvox_set_input_stride(&mm, 1, CHUNK_PAD * CHUNK_PAD);

      // Mesh the inner region [1, CHUNK_SIZE+1) — excludes the padding border
      stbvox_set_input_range(&mm, 1, 1, 1, CHUNK_SIZE + 1, CHUNK_SIZE + 1, CHUNK_SIZE + 1);

      // World-space offset so positions are absolute, not chunk-local
      stbvox_set_mesh_coordinates(&mm, c->cx * CHUNK_SIZE, 0, c->cz * CHUNK_SIZE);

      // Buffer 0 = vertex output, buffer 1 = face output
      // Verify buffer indices with the stb header.
      stbvox_set_buffer(&mm, 0, 0, s_vtx_buf,  sizeof(s_vtx_buf));
      stbvox_set_buffer(&mm, 0, 1, s_face_buf, sizeof(s_face_buf));

      // Returns 0 while buffers full (shouldn't happen with our MAX_QUADS),
      // non-zero when complete. Verify return-value semantics in stb header.
      while (!stbvox_make_mesh(&mm)) {}

      int nq = stbvox_get_quad_count(&mm, 0);
      if (nq == 0) return;

      // Interleave: replicate the per-face uint32 across all 4 vertices of each quad
      for (int q = 0; q < nq; q++)
          for (int v = 0; v < 4; v++) {
              s_gpu[q * 4 + v].vtx  = s_vtx_buf[q * 4 + v];
              s_gpu[q * 4 + v].face = s_face_buf[q];
          }

      // Index buffer: two triangles per quad (0,1,2, 0,2,3)
      uint16_t *idx = (uint16_t *)malloc(nq * 6 * sizeof(uint16_t));
      for (int q = 0; q < nq; q++) {
          idx[q*6+0] = (uint16_t)(q*4+0); idx[q*6+1] = (uint16_t)(q*4+1);
          idx[q*6+2] = (uint16_t)(q*4+2); idx[q*6+3] = (uint16_t)(q*4+0);
          idx[q*6+4] = (uint16_t)(q*4+2); idx[q*6+5] = (uint16_t)(q*4+3);
      }

      // Upload to GPU
      c->vao = rlLoadVertexArray();
      rlEnableVertexArray(c->vao);

      c->vbo = rlLoadVertexBuffer(s_gpu, nq * 4 * (int)sizeof(GpuVertex), false);
      rlEnableVertexBuffer(c->vbo);

      // attr location 0: vtx (1× uint32), attr location 1: face (1× uint32)
      // GL_UNSIGNED_INT = 0x1405
      rlSetVertexAttribute(0, 1, 0x1405, false, (int)sizeof(GpuVertex), 0);
      rlEnableVertexAttribute(0);
      rlSetVertexAttribute(1, 1, 0x1405, false, (int)sizeof(GpuVertex), (int)sizeof(uint32_t));
      rlEnableVertexAttribute(1);
      rlDisableVertexBuffer();

      // IBO bound inside VAO scope → automatically part of this VAO's state
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
  ```

- [ ] Build — expect compile success:
  ```
  build.bat
  ```

- [ ] Commit:
  ```
  git add src/chunk.h src/chunk.c
  git commit -m "feat: chunk mesh build via stb_voxel_render, rlgl GPU upload"
  ```

---

### Task 6: Voxel shaders

**Files:**
- Create: `shaders/voxel.vert`
- Create: `shaders/voxel.frag`

**Prerequisite:** In Task 2 you noted the exact bit layout for `attr0` and `attr1` from the stb header. Use those values here. The bit positions below are a starting point — adjust them if the header disagrees.

- [ ] Create `shaders/voxel.vert`:
  ```glsl
  #version 330 core

  // attr0: packed vertex — position within face, AO
  // attr1: packed face  — face direction, block type
  // (bit layout from stb_voxel_render.h — verify and adjust if needed)
  layout(location = 0) in uint attr0;
  layout(location = 1) in uint attr1;

  uniform mat4  mvp;
  uniform vec3  chunk_origin;  // set to vec3(0) when mesh_coordinates are world-absolute

  out float v_ao;
  out float v_light;
  flat out uint  v_btype;

  // Face direction → normal (stb face indices: 0=+x,1=-x,2=+y,3=-y,4=+z,5=-z)
  const vec3 NORMALS[6] = vec3[6](
      vec3( 1, 0, 0), vec3(-1, 0, 0),
      vec3( 0, 1, 0), vec3( 0,-1, 0),
      vec3( 0, 0, 1), vec3( 0, 0,-1)
  );

  void main() {
      // Extract world position from attr0 — verify bit ranges from stb header
      float px = float( attr0        & 0x7Fu);   // bits  0-6
      float py = float((attr0 >>  7u) & 0x7Fu);  // bits  7-13
      float pz = float((attr0 >> 14u) & 0x7Fu);  // bits 14-20

      // AO: 2 bits
      uint ao_bits = (attr0 >> 21u) & 0x3u;
      v_ao = 1.0 - float(ao_bits) * 0.25;

      // Face direction: bits 0-2 of attr1
      uint face_dir = attr1 & 0x7u;

      // Block type: bits 3-10 of attr1
      v_btype = (attr1 >> 3u) & 0xFFu;

      // Simple directional light
      vec3 norm  = NORMALS[min(face_dir, 5u)];
      v_light    = clamp(dot(norm, normalize(vec3(0.6, 1.0, 0.4))) * 0.4 + 0.7, 0.2, 1.0);

      gl_Position = mvp * vec4(vec3(px, py, pz) + chunk_origin, 1.0);
  }
  ```

- [ ] Create `shaders/voxel.frag`:
  ```glsl
  #version 330 core

  in  float v_ao;
  in  float v_light;
  flat in uint  v_btype;
  out vec4  frag_color;

  // Index matches BlockType enum: 0=AIR(unused), 1=GRASS, 2=DIRT, 3=STONE
  const vec3 COLORS[4] = vec3[4](
      vec3(0.00, 0.00, 0.00),
      vec3(0.35, 0.65, 0.20),
      vec3(0.50, 0.33, 0.18),
      vec3(0.55, 0.55, 0.55)
  );

  void main() {
      vec3 base = COLORS[min(v_btype, 3u)];
      frag_color = vec4(base * v_ao * v_light, 1.0);
  }
  ```

- [ ] Commit:
  ```
  git add shaders/
  git commit -m "feat: voxel vertex and fragment shaders"
  ```

---

### Task 7: Free-fly camera (camera.h + camera.c)

**Files:**
- Modify: `src/camera.h`
- Modify: `src/camera.c`

- [ ] Replace `src/camera.h`:
  ```c
  #pragma once
  #include "raylib.h"

  Camera3D camera_create(void);
  void      camera_update(Camera3D *cam);
  ```

- [ ] Replace `src/camera.c`:
  ```c
  #include "camera.h"

  Camera3D camera_create(void) {
      Camera3D cam = { 0 };
      cam.position   = (Vector3){ 128.0f, 50.0f, 128.0f };
      cam.target     = (Vector3){ 148.0f, 40.0f, 148.0f };
      cam.up         = (Vector3){   0.0f,  1.0f,   0.0f };
      cam.fovy       = 70.0f;
      cam.projection = CAMERA_PERSPECTIVE;
      return cam;
  }

  void camera_update(Camera3D *cam) {
      UpdateCamera(cam, CAMERA_FREE);
  }
  ```

- [ ] Build:
  ```
  build.bat
  ```

- [ ] Commit:
  ```
  git add src/camera.h src/camera.c
  git commit -m "feat: free-fly camera wrapper"
  ```

---

### Task 8: Render loop — tie it all together (main.c)

**Files:**
- Modify: `src/main.c`

- [ ] Replace `src/main.c` with the full render loop:
  ```c
  #include "raylib.h"
  #include "raymath.h"
  #include "rlgl.h"
  #include "world.h"
  #include "chunk.h"
  #include "camera.h"

  int main(void) {
      InitWindow(1280, 720, "mineworld");
      SetTargetFPS(60);
      DisableCursor();

      Shader shader    = LoadShader("shaders/voxel.vert", "shaders/voxel.frag");
      int loc_mvp      = GetShaderLocation(shader, "mvp");
      int loc_origin   = GetShaderLocation(shader, "chunk_origin");

      World *world = world_create();
      for (int cz = 0; cz < WORLD_D; cz++)
          for (int cx = 0; cx < WORLD_W; cx++)
              chunk_build_mesh(&world->chunks[cz][cx]);

      Camera3D cam = camera_create();

      while (!WindowShouldClose()) {
          camera_update(&cam);

          Matrix view = GetCameraMatrix(cam);
          Matrix proj = MatrixPerspective(
              cam.fovy * DEG2RAD,
              (double)GetScreenWidth() / GetScreenHeight(),
              0.1, 2000.0);
          Matrix mvp = MatrixMultiply(view, proj);

          BeginDrawing();
          ClearBackground((Color){135, 206, 235, 255});

          BeginShaderMode(shader);
          SetShaderValueMatrix(shader, loc_mvp, mvp);

          for (int cz = 0; cz < WORLD_D; cz++) {
              for (int cx = 0; cx < WORLD_W; cx++) {
                  Chunk *c = &world->chunks[cz][cx];
                  if (c->quad_count == 0) continue;

                  // chunk_origin is vec3(0) because stbvox_set_mesh_coordinates
                  // already baked world offset into vertex positions.
                  float origin[3] = { 0.0f, 0.0f, 0.0f };
                  SetShaderValue(shader, loc_origin, origin, SHADER_UNIFORM_VEC3);

                  rlEnableVertexArray(c->vao);
                  rlDrawVertexArrayElements(0, c->quad_count * 6, 0);
                  rlDisableVertexArray();
              }
          }

          EndShaderMode();
          DrawFPS(10, 10);
          EndDrawing();
      }

      for (int cz = 0; cz < WORLD_D; cz++)
          for (int cx = 0; cx < WORLD_W; cx++)
              chunk_free_mesh(&world->chunks[cz][cx]);
      world_destroy(world);
      UnloadShader(shader);
      CloseWindow();
      return 0;
  }
  ```

- [ ] Run `build.bat`. Fix any compile errors.

- [ ] Launch `mineworld.exe`. Expected: procedural voxel terrain visible, WASD + mouse to fly, FPS shown.

  **If geometry is garbled (wrong positions):** The vertex shader bit positions are wrong. Open `vendor/stb_voxel_render.h` and find the exact bit packing documentation for the configured mode. Fix the `px/py/pz` extraction and the `face_dir`/`v_btype` extraction in `shaders/voxel.vert` to match.

  **If nothing renders (black screen):** Check shader compilation errors with `TraceLog` or add `printf` after `LoadShader` — call `IsShaderValid(shader)` and log if false. Common issue: attribute location mismatch. The vertex shader's `attr0`/`attr1` must be at locations 0 and 1 respectively; add `layout(location = 0) in uint attr0;` etc. in the GLSL if needed.

  **If faces are culled inward:** Disable face culling temporarily with `rlDisableBackfaceCulling()` to diagnose winding order, then fix by reversing quad vertex order in chunk.c (swap index pattern to `0,2,1, 0,3,2`).

- [ ] Commit:
  ```
  git add src/main.c
  git commit -m "feat: full voxel renderer working — flythrough of procedural terrain"
  ```
