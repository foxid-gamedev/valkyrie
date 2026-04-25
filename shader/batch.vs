#version 330 core
layout(location = 0) in vec2 a_pos;
layout(location = 1) in vec2 a_uv;
layout(location = 2) in vec4 a_tint;
layout(location = 3) in int  a_texture_id;
layout(location = 4) in int  a_layer;

uniform mat4 u_proj_view;

out vec4 v_color;

void main() {
   gl_Position = u_proj_view * vec4(a_pos.xy, 0.0, 1.0);
   v_color = a_tint;
}