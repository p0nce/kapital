#include "raylib.h"
#include "raymath.h"
#include "rlgl.h"
#include "world.h"
#include "chunk.h"
#include "camera.h"
#include <math.h>

int main(void) {
    InitWindow(1280, 720, "mineworld");
    SetTargetFPS(60);
    DisableCursor();

    Shader shader = LoadShader("shaders/voxel.vert", "shaders/voxel.frag");
    int loc_mvp    = GetShaderLocation(shader, "mvp");
    int loc_origin = GetShaderLocation(shader, "chunk_origin");

    Shader sky = LoadShader("shaders/sky.vert", "shaders/sky.frag");
    int sky_mvp    = GetShaderLocation(sky, "mvp");
    int sky_fwd    = GetShaderLocation(sky, "cam_fwd");
    int sky_right  = GetShaderLocation(sky, "cam_right");
    int sky_up     = GetShaderLocation(sky, "cam_up");
    int sky_thfov  = GetShaderLocation(sky, "tan_half_fov");
    int sky_aspect = GetShaderLocation(sky, "aspect");

    World *world = world_create();
    for (int cz = 0; cz < WORLD_D; cz++)
        for (int cx = 0; cx < WORLD_W; cx++)
            chunk_build_mesh(&world->chunks[cz][cx]);

    Camera3D cam = camera_create();

    while (!WindowShouldClose()) {
        if (IsKeyPressed(KEY_F11) ||
            ((IsKeyDown(KEY_LEFT_ALT) || IsKeyDown(KEY_RIGHT_ALT)) && IsKeyPressed(KEY_ENTER)))
            ToggleFullscreen();

        camera_update(&cam, world);

        Matrix view = GetCameraMatrix(cam);
        Matrix proj = MatrixPerspective(
            cam.fovy * DEG2RAD,
            (double)GetScreenWidth() / GetScreenHeight(),
            0.1, 2000.0);
        Matrix mvp = MatrixMultiply(view, proj);

        // Reconstruct camera basis for sky shader
        Vector3 fwd   = Vector3Normalize(Vector3Subtract(cam.target, cam.position));
        Vector3 right = Vector3Normalize(Vector3CrossProduct(cam.up, fwd));
        Vector3 up    = Vector3CrossProduct(fwd, right);
        float thfov   = tanf(cam.fovy * DEG2RAD * 0.5f);
        float aspect  = (float)GetScreenWidth() / (float)GetScreenHeight();

        BeginDrawing();
        ClearBackground(BLACK);
        rlEnableDepthTest();

        // Sky pass — no depth writes, full-screen quad via raylib 2D
        BeginShaderMode(sky);
        {
            Matrix ortho = MatrixOrtho(0, GetScreenWidth(), GetScreenHeight(), 0, -1, 1);
            SetShaderValueMatrix(sky, sky_mvp, ortho);
            SetShaderValue(sky, sky_fwd,    &fwd,    SHADER_UNIFORM_VEC3);
            SetShaderValue(sky, sky_right,  &right,  SHADER_UNIFORM_VEC3);
            SetShaderValue(sky, sky_up,     &up,     SHADER_UNIFORM_VEC3);
            SetShaderValue(sky, sky_thfov,  &thfov,  SHADER_UNIFORM_FLOAT);
            SetShaderValue(sky, sky_aspect, &aspect, SHADER_UNIFORM_FLOAT);
            rlDisableDepthMask();
            DrawRectangle(0, 0, GetScreenWidth(), GetScreenHeight(), WHITE);
            rlEnableDepthMask();
        }
        EndShaderMode();

        // Voxel pass
        BeginShaderMode(shader);
        SetShaderValueMatrix(shader, loc_mvp, mvp);

        for (int cz = 0; cz < WORLD_D; cz++) {
            for (int cx = 0; cx < WORLD_W; cx++) {
                Chunk *c = &world->chunks[cz][cx];
                if (c->quad_count == 0) continue;
                float origin[3] = { (float)(cx * CHUNK_SIZE), 0.0f, (float)(cz * CHUNK_SIZE) };
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
    UnloadShader(sky);
    CloseWindow();
    return 0;
}
