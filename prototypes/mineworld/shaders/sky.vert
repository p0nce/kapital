#version 330 core

layout(location = 0) in vec3 vertexPosition;
uniform mat4 mvp;
out vec2 v_ndc;

void main() {
    gl_Position = mvp * vec4(vertexPosition, 1.0);
    v_ndc = gl_Position.xy;  // NDC coords after raylib 2D ortho transform
}
