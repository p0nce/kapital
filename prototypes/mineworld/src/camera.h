#pragma once
#include "raylib.h"
#include "world.h"

Camera3D camera_create(void);
void     camera_update(Camera3D *cam, const World *w);
