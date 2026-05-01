#version 330 core

in vec2 v_uv;
in vec4 v_color;
flat in int v_shape_type;
in vec4 v_shape_data;

uniform sampler2D u_texture0;

out vec4 FragColor;

float sdf_circle(vec2 p) {
   return length(p) - 1.0;
}

void main() {
   switch (v_shape_type) {
   case 0: { // rectangle/texture
      vec4 tex_color = texture(u_texture0, v_uv);
      FragColor = tex_color * v_color;
      break;
   } case 1: {// circle (filled)
      vec2 p = v_uv * 2.0 - 1.0;
      float d = sdf_circle(p);
      float edge = fwidth(d);
      float alpha = 1.0 - smoothstep(-edge, edge, d);
      FragColor = vec4(v_color.rgb, v_color.a * alpha);
      break;
   } case 2: { // circle-lines (with thickness)
      vec2 p = v_uv * 2.0 - 1.0;
      float d = length(p);
      float e = fwidth(d);
      float a = 1.0 - smoothstep(v_shape_data[0] - e, v_shape_data[0] + e, d);
      float b = smoothstep(v_shape_data[1] - e, v_shape_data[1] + e, d);
      FragColor = vec4(v_color.rgb, v_color.a * a * b);
      break;
   } }
}