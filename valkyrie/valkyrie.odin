/******************************************************************************/
/* valkyrie.odin                                                              */
/******************************************************************************/
/* MIT License                                                                */
/* Copyright (c) 2026 Marcel Kübler Software.                                 */
/*                                                                            */
/* Permission is hereby granted, free of charge, to any person obtaining a    */
/* copy of this software and associated documentation files (the "Software"), */
/* to deal in the Software without restriction, including without limitation  */
/* the rights to use, copy, modify, merge, publish, distribute, sublicense,   */
/* and/or sell copies of the Software, and to permit persons to whom the      */
/* Software is furnished to do so, subject to the following conditions:       */
/*                                                                            */
/* The above copyright notice and this permission notice shall be included in */
/* all copies or substantial portions of the Software.                        */
/*                                                                            */
/******************************************************************************/
/*                                                                            */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS    */
/* OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF                 */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.     */
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY       */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT  */
/* OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE      */
/* OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                              */
/******************************************************************************/

package valkyrie

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:math"
import lin "core:math/linalg"
import "core:os"
import "core:strings"

import stbi "vendor:stb/image"
import gl "vendor:OpenGL"
import "vendor:glfw"
import fon "vendor:fontstash"

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32
Rect :: struct {
	x, y, w, h: f32,
}
Mat4 :: lin.Matrix4f32
Shader :: u32
Color :: Vec4

VALKYRIE_BLUE :: Color{0.025, 0.025, 0.112, 1.0}
WHITE :: Color{1,1,1,1}
BLACK :: Color{0,0,0,1}

BATCH_MAX_QUADS :: 65536
VERTICES_PER_QUAD :: 4
INDICES_PER_QUAD :: 6
BATCH_MAX_VERTICES :: BATCH_MAX_QUADS * VERTICES_PER_QUAD
BATCH_MAX_INDICES :: BATCH_MAX_QUADS * INDICES_PER_QUAD
FONT_ATLAS_SIZE :: 1024

Val_State :: struct {
	width:           int,
	height:          int,
	title:           string,
	window:          glfw.WindowHandle,
	batch:           Renderer,
	projection_view: Mat4,
	last_time:       f64,
	delta_time:      f32,
	font_ctx: 		  fon.FontContext,
	font_default: 	  Font,
	font_atlas:		  Texture,
}

Texture :: struct {
	id:     u32,
	width:  int,
	height: int,
}


Vertex :: struct {
	position: Vec2,
	uv:       Vec2,
	tint:     Vec4,
	layer:    i32,
}

Renderer :: struct {
	vao:      u32,
	vbo:      u32,
	ebo:      u32,
	vertices: [dynamic]Vertex,
	shader:   Shader,
	basic_texture: Texture,
	last_texture_id: u32,
}

Font :: struct {
	name: string,
	id: int,
}

@(private = "file")
s: ^Val_State

create_window :: proc(width, height: int, title: string) {
	s = new(Val_State)

	error_callback :: proc "c" (error: i32, desc: cstring) {
		context = runtime.default_context()
		fmt.printf("Error code %d:\n %s\n", error, desc)
	}
	glfw.SetErrorCallback(error_callback)

	// initialize glfw
	glfw.Init()
	glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
	glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
	glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

	s.window = glfw.CreateWindow(i32(width), i32(height), fmt.ctprint(title), nil, nil)
	s.width = width
	s.height = height
	s.title = title

	glfw.MakeContextCurrent(s.window)
	glfw.SwapInterval(0)

	// load opengl
	set_proc_address :: proc(p: rawptr, name: cstring) {
		(cast(^rawptr)p)^ = rawptr(glfw.GetProcAddress(name))
	}
	gl.load_up_to(3, 3, set_proc_address)

	// generate batch renderer
	gl.GenVertexArrays(1, &s.batch.vao)
	gl.GenBuffers(1, &s.batch.vbo)
	gl.GenBuffers(1, &s.batch.ebo)

	gl.BindVertexArray(s.batch.vao)
	defer gl.BindVertexArray(0)
	{
		// vertex buffer
		s.batch.vertices = make([dynamic]Vertex, 0, BATCH_MAX_VERTICES)

		gl.BindBuffer(gl.ARRAY_BUFFER, s.batch.vbo)
		gl.BufferData(gl.ARRAY_BUFFER, BATCH_MAX_VERTICES * size_of(Vertex), nil, gl.DYNAMIC_DRAW)
		gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, position))
		gl.EnableVertexAttribArray(0)
		gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, uv))
		gl.EnableVertexAttribArray(1)
		gl.VertexAttribPointer(2, 4, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, tint))
		gl.EnableVertexAttribArray(2)
		gl.VertexAttribPointer(3, 1, gl.INT, gl.FALSE, size_of(Vertex), offset_of(Vertex, layer))
		gl.EnableVertexAttribArray(3)

		// element buffer
		gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, s.batch.ebo)
		gl.BufferData(
			gl.ELEMENT_ARRAY_BUFFER,
			BATCH_MAX_INDICES * size_of(u32),
			nil,
			gl.STATIC_DRAW,
		)
		@(static) indices: [BATCH_MAX_INDICES]u32
		for i in 0 ..< BATCH_MAX_QUADS {
			base := u32(i * VERTICES_PER_QUAD)
			indices[i * INDICES_PER_QUAD + 0] = base + 0
			indices[i * INDICES_PER_QUAD + 1] = base + 1
			indices[i * INDICES_PER_QUAD + 2] = base + 2
			indices[i * INDICES_PER_QUAD + 3] = base + 0
			indices[i * INDICES_PER_QUAD + 4] = base + 2
			indices[i * INDICES_PER_QUAD + 5] = base + 3
		}
		gl.BufferSubData(gl.ELEMENT_ARRAY_BUFFER, 0, BATCH_MAX_INDICES * size_of(u32), &indices[0])
	}

	if shader, ok := load_shader("shader/batch.vs", "shader/batch.fs"); ok {
		s.batch.shader = shader
	}

	s.projection_view = lin.matrix_ortho3d_f32(0, f32(width), f32(height), 0, -1, 1)

	// create basic texture
	{
		pixels := [4]u8{255, 255, 255, 255}
		s.batch.basic_texture.width = 1
		s.batch.basic_texture.height = 1

		gl.GenTextures(1, &s.batch.basic_texture.id)
		gl.BindTexture(gl.TEXTURE_2D, s.batch.basic_texture.id)

		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)

		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, i32(s.batch.basic_texture.width), i32(s.batch.basic_texture.height), 0, gl.RGBA, gl.UNSIGNED_BYTE, &pixels[0])
	}

	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

	// enable fontstash
	{
		fon.Init(&s.font_ctx, FONT_ATLAS_SIZE, FONT_ATLAS_SIZE, .TOPLEFT)
		s.font_default.name = "Pangolin"
		
		data, data_ok := os.read_entire_file("assets/Pangolin-Regular.ttf", context.temp_allocator)
		if data_ok != os.General_Error.None {
			log.error("Failed to load font:", s.font_default.name, " with err:", data_ok)
		}
		
		s.font_default.id = fon.AddFontMem(&s.font_ctx, "", data, false)
		s.font_atlas.width = FONT_ATLAS_SIZE
		s.font_atlas.height = FONT_ATLAS_SIZE

		gl.GenTextures(1, &s.font_atlas.id)
		gl.BindTexture(gl.TEXTURE_2D, s.font_atlas.id)

		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

		tex_data := s.font_ctx.fonts[s.font_default.id].loadedData

		// fmt.println(tex_data)
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RED, i32(s.font_atlas.width), i32(s.font_atlas.height), 0, gl.RED, gl.UNSIGNED_BYTE, &tex_data[0])
	}
}

poll_events :: proc() {
	glfw.PollEvents()
	_update_frame_time()
}

should_close :: proc() -> bool {
	return bool(glfw.WindowShouldClose(s.window))
}

close_window :: proc() {
	glfw.SetWindowShouldClose(s.window, true)
}

render_begin :: proc() {
	gl.Viewport(0, 0, i32(s.width), i32(s.height))
	gl.Clear(gl.COLOR_BUFFER_BIT)
}

draw_rectangle :: proc(dest: Rect, tint: Color) {
	_render_object(s.batch.basic_texture, {0,0,1,1}, dest, tint, 0)
}

draw_texture_pos :: proc(texture: Texture, position: Vec2, origin: Vec2 = {}, scale: Vec2 = {1,1}, tint: Color = WHITE) {
	_render_object(
		texture, 
		{0,0,f32(texture.width),f32(texture.height)}, 
		{position.x - origin.x, position.y - origin.y, f32(texture.width) * scale.x, f32(texture.height) * scale.y}, 
		tint, 
		0,
	)
}

draw_fps :: proc(position: Vec2, font_size: f32, color: Color = WHITE) {
	fps := int(math.floor(1.0/delta_time()))
	draw_text(fmt.tprint("FPS:", fps), position, font_size, color)
}

draw_text :: proc(text: string, position: Vec2, font_size: f32, color: Color = WHITE) {
	fon.SetFont(&s.font_ctx, s.font_default.id)
	fon.SetColor(&s.font_ctx, as_color_u8(color))
	fon.SetSize(&s.font_ctx, font_size)
	iter := fon.TextIterInit(&s.font_ctx, position.x, position.y, text)

	q: fon.Quad
	@static done: bool

	state := fon.__getState(&s.font_ctx)

	state^ = {
		size = font_size,
		blur = 0,
		spacing = 0,
		font = int(s.font_default.id),
		ah = fon.AlignHorizontal(.LEFT),
		av = fon.AlignVertical(.TOP),
	}

	i: int
	for fon.TextIterNext(&s.font_ctx, &iter, &q) {
		if iter.codepoint == '\n' {
			iter.nexty += font_size
			iter.nextx = position.x
			continue
		}

		// source := Rect {
		// 	q.s0, q.t0,
		// 	q.s1 - q.s0, q.t1 - q.t0,
		// }

		source := Rect {
			q.s0, q.t0,
			q.s1, q.t1,
		}

		// source.w *= FONT_ATLAS_SIZE
		// source.h *= FONT_ATLAS_SIZE

		// source := Rect {
		// 	q.s0 * 512,
		// 	q.t0 * 512,
		// 	(q.s1 - q.s0) * 512,
		// 	(q.t1 - q.t0) * 512,
		// }

		// if !done {
		// 	if i <= 5 {
		// 		fmt.print("{", source.x, source.y, source.w, source.h, "},")
		// 	} else {
		// 		done = true
		// 	}

		// 	i += 1
		// }

		dest := Rect {
			position.x + q.x0, position.y + q.y0,
			q.x1, q.y1,
		}

		// dest := Rect {
		// 	q.x0,
		// 	q.y1,  // bottom-left für Y-up OpenGL
		// 	q.x1 - q.x0,
		// 	q.y0 - q.y1,  // positive height
		// }

		_render_object(s.font_atlas, source, dest, color, 0)
	}
}

draw_texture_part :: proc(texture: Texture, source, dest: Rect, tint: Color) {
	_render_object(texture, source, dest, tint, 0)
}

@(private="file") _render_object :: proc(texture: Texture, source, dest: Rect, tint: Color, layer: i32) {
	if s.batch.last_texture_id != texture.id {
		_draw_next_batch(s.batch.last_texture_id)
		s.batch.last_texture_id = texture.id
	}

	uv := Rect{
		x = source.x/f32(texture.width),
		y = source.y/f32(texture.height),
		w = source.w/f32(texture.width),
		h = source.h/f32(texture.height),
	}

	append(&s.batch.vertices, 
		Vertex{{dest.x, dest.y},{uv.x,uv.y}, tint, layer}, 
		Vertex{{dest.x + dest.w, dest.y},{uv.x + uv.w, uv.y}, tint, layer},
		Vertex{{dest.x + dest.w, dest.y + dest.h},{uv.x + uv.w, uv.y + uv.h}, tint, layer},
		Vertex{{dest.x, dest.y + dest.h},{uv.x,uv.y + uv.h}, tint, layer},
	)
}

clear_color :: proc(color: Color) {
	gl.ClearColor(color.r, color.g, color.b, color.a)
}

@(private="file") _draw_next_batch :: proc(texture_id: u32) {
	if len(s.batch.vertices) ==  0 do return

	// set texture
	gl.ActiveTexture(gl.TEXTURE0)
	gl.BindTexture(gl.TEXTURE_2D, texture_id)
	
	// set shader
	shader_bind(s.batch.shader)
	gl.UniformMatrix4fv(
		gl.GetUniformLocation(s.batch.shader, "u_proj_view"),
		1,
		gl.FALSE,
		raw_data(&s.projection_view[0]),
	)

	// apply dynamic vertices
	gl.BindVertexArray(s.batch.vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, s.batch.vbo)
	gl.BufferSubData(
		gl.ARRAY_BUFFER,
		0,
		len(s.batch.vertices) * size_of(Vertex),
		&s.batch.vertices[0],
	)

	// draw elements
	quads := len(s.batch.vertices) / 4
	gl.DrawElements(gl.TRIANGLES, i32(quads) * INDICES_PER_QUAD, gl.UNSIGNED_INT, nil)

	// reset vertex length
	clear(&s.batch.vertices)
}

render_end :: proc() {
	_draw_next_batch(s.batch.last_texture_id)
	glfw.SwapBuffers(s.window)
}

shutdown :: proc() {
	fon.Destroy(&s.font_ctx)
	glfw.DestroyWindow(s.window)
	glfw.Terminate()
	delete(s.batch.vertices)
	free(s)
}

load_shader :: proc(vertex_filename, fragment_filename: string) -> (Shader, bool) {
	vertex_file, vertex_file_ok := os.read_entire_file(vertex_filename, context.temp_allocator)
	load_ok: bool = true

	if vertex_file_ok != os.General_Error.None {
		log.error(
			"Shader::Vertex::File::Open::Failed:",
			vertex_filename,
			"with error:",
			vertex_file_ok,
		)
		load_ok = false
	}

	fragment_file, fragment_file_ok := os.read_entire_file(
		fragment_filename,
		context.temp_allocator,
	)

	if fragment_file_ok != os.General_Error.None {
		log.error(
			"Shader::Fragment::File::Open::Failed:",
			fragment_filename,
			"with error:",
			fragment_file_ok,
		)
		load_ok = false
	}

	vertex_source := strings.clone_to_cstring(transmute(string)vertex_file, context.temp_allocator)
	fragment_source := strings.clone_to_cstring(
		transmute(string)fragment_file,
		context.temp_allocator,
	)

	success: i32
	INFO_BUFFER_SIZE :: 1024
	info_buffer: [INFO_BUFFER_SIZE]u8

	vertex := gl.CreateShader(gl.VERTEX_SHADER)
	gl.ShaderSource(vertex, 1, &vertex_source, nil)
	gl.CompileShader(vertex)
	gl.GetShaderiv(vertex, gl.COMPILE_STATUS, &success)

	if (success == 0) {
		gl.GetShaderInfoLog(vertex, INFO_BUFFER_SIZE, nil, &info_buffer[0])
		log.error(
			"Shader::Vertex::Compilation::Failed",
			strings.clone_from_bytes(info_buffer[:], context.temp_allocator),
		)
		load_ok = false
	}

	fragment := gl.CreateShader(gl.FRAGMENT_SHADER)
	gl.ShaderSource(fragment, 1, &fragment_source, nil)
	gl.CompileShader(fragment)
	gl.GetShaderiv(fragment, gl.COMPILE_STATUS, &success)

	if (success == 0) {
		gl.GetShaderInfoLog(vertex, INFO_BUFFER_SIZE, nil, &info_buffer[0])
		log.error(
			"Shader::Fragment::Compilation::Failed",
			strings.clone_from_bytes(info_buffer[:], context.temp_allocator),
		)
		load_ok = false
	}

	shader := gl.CreateProgram()
	gl.AttachShader(shader, vertex)
	gl.AttachShader(shader, fragment)
	gl.LinkProgram(shader)

	gl.GetProgramiv(shader, gl.LINK_STATUS, &success)
	if (success == 0) {
		gl.GetProgramInfoLog(shader, INFO_BUFFER_SIZE, nil, &info_buffer[0])
		log.error(
			"Shader::Program::Linking::Failed",
			strings.clone_from_bytes(info_buffer[:], context.temp_allocator),
		)
		load_ok = false
	}

	gl.DeleteShader(vertex)
	gl.DeleteShader(fragment)
	return shader, load_ok
}

shader_bind :: proc(s: Shader) {
	gl.UseProgram(s)
}

delta_time :: proc() -> f32 {
	return s.delta_time
}

@(private = "file")
_update_frame_time :: proc() {
	current_time := glfw.GetTime()
	delta := current_time - s.last_time
	s.last_time = current_time
	s.delta_time = f32(delta)
}

window_width :: proc() -> int {
	return s.width
}

window_height :: proc() -> int {
	return s.height
}

window_title :: proc() -> string {
	return s.title
}

load_texture :: proc(file: string) -> (tex: Texture) {

	gl.GenTextures(1, &tex.id)
	gl.BindTexture(gl.TEXTURE_2D, tex.id)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	x, y, channels: i32
	data := stbi.load(fmt.ctprint(file), &x, &y, &channels, 0)
	if (data == nil) {
		log.error("Texture::File::Open::Failed:", file)
		return {}
	}

	tex.width = int(x)
	tex.height = int(y)

   format := gl.RGB
   if channels == 4 {
      format = gl.RGBA
   } else if channels == 1 {
      format = gl.RED
   }

	gl.TexImage2D(gl.TEXTURE_2D, 0, i32(format), x, y, 0, u32(format), gl.UNSIGNED_BYTE, data)
	gl.GenerateMipmap(gl.TEXTURE_2D)

	stbi.image_free(data)

	return tex
}

as_color_u8 :: proc(color: Color) -> [4]u8 {
	return {
		u8(math.round(color.r * 255.0)),
		u8(math.round(color.g * 255.0)),
		u8(math.round(color.b * 255.0)),
		u8(math.round(color.a * 255.0)),
	}
}