#version 330 core
layout(location = 0) in vec2 a_pos;
layout(location = 1) in vec2 a_uv;
layout(location = 2) in vec4 a_tint;
layout(location = 3) in int  a_layer;
layout(location = 4) in int a_shape_type;
layout(location = 5) in vec4 a_shape_data;

uniform mat4 u_proj_view;

out vec2 v_uv;
out vec4 v_color;
flat out int v_shape_type;
out vec4 v_shape_data;

void main() {
   gl_Position = u_proj_view * vec4(a_pos.xy, a_layer, 1.0);
   v_uv = a_uv;
   v_color = a_tint;
   v_shape_type = a_shape_type;
   v_shape_data = a_shape_data;
}