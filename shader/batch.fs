#version 330 core

in vec2 v_uv;
in vec4 v_color;
flat in int v_shape_type;
in vec4 v_shape_data;

uniform sampler2D u_texture0;

out vec4 FragColor;

float sdf_rounded_box(vec2 p, vec2 b, float r) {
   vec2 q = abs(p) - b + r;
   return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
   switch (v_shape_type) {
   case 0: { // textured quad (rectangles, sprites, glyphs)
      vec4 tex_color = texture(u_texture0, v_uv);
      FragColor = tex_color * v_color;
      break;
   } case 1: { // sdf shape (circle, rounded box, outlines)
      vec2  p  = (v_uv - 0.5) * v_shape_data.xy * 2.0;
      float r  = v_shape_data.z;
      float hf = v_shape_data.w;
      float d  = sdf_rounded_box(p, v_shape_data.xy, r);
      float e  = fwidth(d);
      float ao = 1.0 - smoothstep(-e, e, d);
      float ai = 1.0;
      if (hf > 0.0) {
         float ri = max(0.0, r - hf);
         float di = sdf_rounded_box(p, v_shape_data.xy - hf * 2.0, ri);
         ai = smoothstep(-fwidth(di), fwidth(di), di);
      }
      FragColor = vec4(v_color.rgb, v_color.a * ao * ai);
      break;
   } }
}