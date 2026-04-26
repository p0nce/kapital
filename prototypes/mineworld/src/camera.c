#include "camera.h"
#include "world.h"
#include <math.h>

#define EYE_OFFSET   2.65f
#define CHAR_HEIGHT  2.85f
#define CHAR_RADIUS  0.30f
#define CYL_MARGIN   0.001f  // expand block search range to catch exact boundary hits
#define WALK_SPEED  5.0f
#define RUN_SPEED   10.0f
#define JUMP_VEL    9.0f
#define GRAVITY     22.0f
#define MOUSE_SENS  0.003f
#define DOUBLE_TAP  0.35f

static Vector3 s_pos       = { 128.0f, 30.0f, 96.0f };
static float   s_vel_y     = 0.0f;
static float   s_yaw       = 0.0f;
static float   s_pitch     = 0.0f;
static int     s_on_ground = 0;
static int     s_running   = 0;
static double  s_last_w    = -1.0;

// Cylinder-AABB overlap test: returns 1 if the character cylinder overlaps any solid block.
// Iterates blocks within the cylinder's bounding square; for each, finds the nearest point
// in the block to the cylinder axis and tests distance < radius.
// CYL_MARGIN expands both the search range and the radius so that sample points landing
// exactly on a block boundary are caught symmetrically from all directions.
static int cyl_blocked(const World *w, float px, float py, float pz) {
    float r2  = (CHAR_RADIUS + CYL_MARGIN) * (CHAR_RADIUS + CYL_MARGIN);
    int   y0  = (int)floorf(py + 0.001f);
    int   y1  = (int)floorf(py + CHAR_HEIGHT - 0.001f);
    int   bx0 = (int)floorf(px - CHAR_RADIUS - CYL_MARGIN);
    int   bx1 = (int)floorf(px + CHAR_RADIUS + CYL_MARGIN);
    int   bz0 = (int)floorf(pz - CHAR_RADIUS - CYL_MARGIN);
    int   bz1 = (int)floorf(pz + CHAR_RADIUS + CYL_MARGIN);
    for (int bx = bx0; bx <= bx1; bx++) {
        float cx = px < (float)bx ? (float)bx : (px < (float)(bx+1) ? px : (float)(bx+1));
        float dx = px - cx;
        if (dx * dx >= r2) continue;
        for (int bz = bz0; bz <= bz1; bz++) {
            float cz = pz < (float)bz ? (float)bz : (pz < (float)(bz+1) ? pz : (float)(bz+1));
            float dz = pz - cz;
            if (dx * dx + dz * dz < r2) {
                for (int y = y0; y <= y1; y++)
                    if (world_get_block(w, bx, y, bz) != BLOCK_AIR) return 1;
            }
        }
    }
    return 0;
}

// Returns 1 if there is a solid block just below the character's feet.
static int ground_below(const World *w, float px, float py, float pz) {
    int y   = (int)floorf(py - 0.05f);
    int bx0 = (int)floorf(px - CHAR_RADIUS);
    int bx1 = (int)floorf(px + CHAR_RADIUS);
    int bz0 = (int)floorf(pz - CHAR_RADIUS);
    int bz1 = (int)floorf(pz + CHAR_RADIUS);
    for (int bx = bx0; bx <= bx1; bx++)
        for (int bz = bz0; bz <= bz1; bz++)
            if (world_get_block(w, bx, y, bz) != BLOCK_AIR) return 1;
    return 0;
}

Camera3D camera_create(void) {
    Camera3D cam = { 0 };
    cam.fovy       = 70.0f;
    cam.projection = CAMERA_PERSPECTIVE;
    cam.up         = (Vector3){ 0.0f, 1.0f, 0.0f };
    cam.position   = (Vector3){ s_pos.x, s_pos.y + EYE_OFFSET, s_pos.z };
    cam.target     = (Vector3){ s_pos.x, s_pos.y + EYE_OFFSET, s_pos.z + 1.0f };
    return cam;
}

void camera_update(Camera3D *cam, const World *w) {
    float dt = GetFrameTime();
    if (dt > 0.1f) dt = 0.1f;

    // Mouse look
    Vector2 md = GetMouseDelta();
    s_yaw   -= md.x * MOUSE_SENS;
    s_pitch -= md.y * MOUSE_SENS;
    if (s_pitch >  1.5f) s_pitch =  1.5f;
    if (s_pitch < -1.5f) s_pitch = -1.5f;

    // Double-tap W/Up → run; release W/Up → stop running
    if (IsKeyPressed(KEY_W) || IsKeyPressed(KEY_UP)) {
        double now = GetTime();
        if (now - s_last_w < (double)DOUBLE_TAP) s_running = 1;
        s_last_w = now;
    }
    if (!IsKeyDown(KEY_W) && !IsKeyDown(KEY_UP)) s_running = 0;

    // Jump
    if (IsKeyPressed(KEY_SPACE) && s_on_ground)
        s_vel_y = JUMP_VEL;

    // Gravity
    if (!s_on_ground) {
        s_vel_y -= GRAVITY * dt;
        if (s_vel_y < -40.0f) s_vel_y = -40.0f;
    }

    // Horizontal movement delta
    float fx =  sinf(s_yaw), fz = cosf(s_yaw);    // forward
    float rx = -cosf(s_yaw), rz = sinf(s_yaw);   // right (negated to match yaw convention)
    float dx = 0.0f, dz = 0.0f;
    if (IsKeyDown(KEY_W) || IsKeyDown(KEY_UP))   { dx += fx; dz += fz; }
    if (IsKeyDown(KEY_S) || IsKeyDown(KEY_DOWN)) { dx -= fx; dz -= fz; }
    if (IsKeyDown(KEY_A))                         { dx -= rx; dz -= rz; }
    if (IsKeyDown(KEY_D))                         { dx += rx; dz += rz; }
    float len = sqrtf(dx*dx + dz*dz);
    float spd = s_running ? RUN_SPEED : WALK_SPEED;
    if (len > 0.001f) { dx = dx/len * spd * dt; dz = dz/len * spd * dt; }

    // Move X — try step-up over 1-block ledges when on ground
    float nx = s_pos.x + dx;
    if (!cyl_blocked(w, nx, s_pos.y, s_pos.z)) {
        s_pos.x = nx;
    } else if (s_on_ground && !cyl_blocked(w, nx, s_pos.y + 1.0f, s_pos.z)) {
        s_pos.x = nx;
        s_pos.y += 1.0f;
        s_vel_y  = 0.0f;
    }

    // Move Z — same step-up logic
    float nz = s_pos.z + dz;
    if (!cyl_blocked(w, s_pos.x, s_pos.y, nz)) {
        s_pos.z = nz;
    } else if (s_on_ground && !cyl_blocked(w, s_pos.x, s_pos.y + 1.0f, nz)) {
        s_pos.z = nz;
        s_pos.y += 1.0f;
        s_vel_y  = 0.0f;
    }

    // Move Y (jump/fall)
    float ny = s_pos.y + s_vel_y * dt;
    if (!cyl_blocked(w, s_pos.x, ny, s_pos.z)) {
        s_pos.y = ny;
    } else if (s_vel_y < 0.0f) {
        // Snap feet to top of the block landed on; loop handles multi-block falls at low FPS
        s_pos.y = ceilf(ny);
        for (int i = 0; i < 5 && cyl_blocked(w, s_pos.x, s_pos.y, s_pos.z); i++)
            s_pos.y += 1.0f;
        s_vel_y = 0.0f;
    } else {
        s_vel_y = 0.0f;  // bonked ceiling
    }

    // Respawn if somehow fallen out of world
    if (s_pos.y < -20.0f) {
        s_pos   = (Vector3){ 128.0f, 30.0f, 96.0f };
        s_vel_y = 0.0f;
    }

    // on_ground: only true when not moving upward and solid block below
    s_on_ground = (s_vel_y <= 0.0f) && ground_below(w, s_pos.x, s_pos.y, s_pos.z);

    // Set camera from physics state
    float eye_y = s_pos.y + EYE_OFFSET;
    cam->position = (Vector3){ s_pos.x, eye_y, s_pos.z };
    cam->target   = (Vector3){
        s_pos.x + cosf(s_pitch) * sinf(s_yaw),
        eye_y   + sinf(s_pitch),
        s_pos.z + cosf(s_pitch) * cosf(s_yaw)
    };
    cam->up = (Vector3){ 0.0f, 1.0f, 0.0f };
}
