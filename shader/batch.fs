#version 330 core

in vec2 v_uv;
in vec4 v_color;

uniform sampler2D u_texture0;

out vec4 FragColor;

void main() {
   vec4 tex_color = texture(u_texture0, v_uv);
   FragColor = tex_color * v_color;
}