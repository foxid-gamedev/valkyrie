/******************************************************************************/
/* valkyrie.odin                                                              */
/******************************************************************************/
/* License                                                                    */
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

import gl "vendor:OpenGL"
import "vendor:glfw"

Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32
Rect :: struct { x, y, w, h: f32 }
Mat4 :: lin.Matrix4f32
Shader :: u32
Color :: Vec4

VALKYRIE_BLUE :: Color{0.025, 0.025, 0.112, 1.0}

BATCH_MAX_QUADS :: 65536
VERTICES_PER_QUAD :: 4
INDICES_PER_QUAD :: 6
BATCH_MAX_VERTICES :: BATCH_MAX_QUADS * VERTICES_PER_QUAD
BATCH_MAX_INDICES :: BATCH_MAX_QUADS * INDICES_PER_QUAD

Val_State :: struct {
	width:           int,
	height:          int,
	title:           string,
	window:          glfw.WindowHandle,
	batch:           Renderer,
	projection_view: Mat4,
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
	texture:  i32,
	layer:    i32,
}

Renderer :: struct {
	vao:      u32,
	vbo:      u32,
	ebo:      u32,
	vertices: [dynamic]Vertex,
	shader:   Shader,
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
		gl.VertexAttribPointer(
			0,
			2,
			gl.FLOAT,
			gl.FALSE,
			size_of(Vertex),
			offset_of(Vertex, position),
		)
		gl.EnableVertexAttribArray(0)
		gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, uv))
		gl.EnableVertexAttribArray(1)
		gl.VertexAttribPointer(2, 4, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, tint))
		gl.EnableVertexAttribArray(2)
		gl.VertexAttribPointer(3, 1, gl.INT, gl.FALSE, size_of(Vertex), offset_of(Vertex, texture))
		gl.EnableVertexAttribArray(3)
		gl.VertexAttribPointer(4, 1, gl.INT, gl.FALSE, size_of(Vertex), offset_of(Vertex, layer))

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
}

poll_events :: proc() {
	glfw.PollEvents()
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

draw_rectangle :: proc(rect: Rect, tint: Color) {

	append(
		&s.batch.vertices,
		Vertex{position = {rect.x, rect.y}, uv = {0, 0}, tint = tint, texture = 0, layer = 0},
	)
	append(
		&s.batch.vertices,
		Vertex{position = {rect.x + rect.w, rect.y}, uv = {1.0, 0}, tint = tint, texture = 0, layer = 0},
	)
	append(
		&s.batch.vertices,
		Vertex{position = {rect.x + rect.w, rect.y + rect.h}, uv = {1.0, 1.0}, tint = tint, texture = 0, layer = 0},
	)
	append(
		&s.batch.vertices,
		Vertex{position = {rect.x, rect.y + rect.h}, uv = {0.0, 1.0}, tint = tint, texture = 0, layer = 0},
	)
}

clear_color :: proc(color: Color) {
	gl.ClearColor(color.r, color.g, color.b, color.a)
}

render_end :: proc() {
	if len(s.batch.vertices) > 0 {
		shader_bind(s.batch.shader)

		gl.UniformMatrix4fv(
			gl.GetUniformLocation(s.batch.shader, "u_proj_view"),
			1,
			gl.FALSE,
			raw_data(&s.projection_view[0]),
		)

		gl.BindVertexArray(s.batch.vao)
		gl.BindBuffer(gl.ARRAY_BUFFER, s.batch.vbo)
		gl.BufferSubData(
			gl.ARRAY_BUFFER,
			0,
			len(s.batch.vertices) * size_of(Vertex),
			&s.batch.vertices[0],
		)

		quads := len(s.batch.vertices) / 4
		gl.DrawElements(gl.TRIANGLES, i32(quads) * INDICES_PER_QUAD, gl.UNSIGNED_INT, nil)
	}
	clear(&s.batch.vertices)
	glfw.SwapBuffers(s.window)
}

shutdown :: proc() {
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