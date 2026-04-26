/******************************************************************************/
/* valkyrie.odin                                                              */
/******************************************************************************/
/* MIT License                                                                */
/* Copyright (c) 2026 Marcel Kübler                                           */
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

import "core:encoding/hex"
import "base:runtime"
import "core:fmt"
import "core:log"
import "core:math"
import lin "core:math/linalg"
import "core:os"
import "core:strings"
import "vendor:stb/image"
import "vendor:stb/truetype"
import gl "vendor:OpenGL"
import "vendor:glfw"

///////////////////////////////////////////////////////////////////////////////////////////////////
// Types                                                                                         //
///////////////////////////////////////////////////////////////////////////////////////////////////
Vec2 :: [2]f32
Vec3 :: [3]f32
Vec4 :: [4]f32
Rect :: struct { x, y, w, h: f32 }
Mat4 :: lin.Matrix4f32
Shader :: u32
Color :: Vec4

///////////////////////////////////////////////////////////////////////////////////////////////////
// Colors                                                                                        //
///////////////////////////////////////////////////////////////////////////////////////////////////
VALKYRIE_BLUE :: Color{0.025, 0.025, 0.112, 1.0}
WHITE 		  :: Color{1,1,1,1}
GRAY			  :: Color{0.5,0.5,0.5,1}
BLACK 		  :: Color{0,0,0,1}
RED			  :: Color{1,0,0,1}
ORANGE 		  :: Color{1,0.5,0,1}
YELLOW		  :: Color{1,1,0,1}
GREEN			  :: Color{0,1,0,1}
CYAN 			  :: Color{0,1,1,1}
BLUE			  :: Color{0,0,1,1}
VIOLET		  :: Color{0.5,0,1,1}
MAGENTA		  :: Color{1,0,1,1}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Constants                                                                                     //
///////////////////////////////////////////////////////////////////////////////////////////////////
BATCH_MAX_QUADS :: 65536
VERTICES_PER_QUAD :: 4
INDICES_PER_QUAD :: 6
BATCH_MAX_VERTICES :: BATCH_MAX_QUADS * VERTICES_PER_QUAD
BATCH_MAX_INDICES :: BATCH_MAX_QUADS * INDICES_PER_QUAD

///////////////////////////////////////////////////////////////////////////////////////////////////
// Internal Valkyrie State                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////
Val_State :: struct {
	width:           int,
	height:          int,
	title:           string,
	window:          glfw.WindowHandle,
	batch:           Renderer,
	projection_view: Mat4,
	last_time:       f64,
	delta_time:      f32,
	vsync:			  bool,
	font_info: 		  truetype.fontinfo,
	font:				  Font,
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Structs                                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////
Texture :: struct {
	id:     u32,
	width:  int,
	height: int,
}

Font :: struct {
	atlas: Texture,
	pack: [dynamic]truetype.packedchar,
	size: f32,
}

Vertex :: struct {
	position: Vec2,
	uv:       Vec2,
	tint:     Vec4,
	layer:    i32,
}

Renderer :: struct {
	vao:             u32,
	vbo:             u32,
	ebo:             u32,
	vertices:        [dynamic]Vertex,
	shader:          Shader,
	basic_texture:   Texture,
	last_texture_id: u32,
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Local Variables                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////
@(private = "file") s: ^Val_State

///////////////////////////////////////////////////////////////////////////////////////////////////
// Main Functions                                                                                //
///////////////////////////////////////////////////////////////////////////////////////////////////

// Creates the window and initializes Valkyrie.
// Use this function to start your application.
create_window :: proc(width, height: int, title: string) {
	s = new(Val_State)
	_init_glfw(width, height, title)
	_load_open_gl()
	_create_default_batch_buffers()
	_gen_basic_rect_texture()
	s.batch.shader, _ = load_shader("shader/batch.vs", "shader/batch.fs")
	s.projection_view = lin.matrix_ortho3d_f32(0, f32(width), f32(height), 0, -1, 1)
	s.font = load_font("assets/Pangolin-Regular.ttf", 128, 4096)

	// Enable alpha blending
	gl.Enable(gl.BLEND)
	gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
}

// Destroys the window and frees the memory.
// Use this function to quit your application sucessfully.
shutdown :: proc() {
	glfw.DestroyWindow(s.window)
	glfw.Terminate()
	delete(s.batch.vertices)
	free(s)
}

// Receives the current input state and updates the frame time.
// Necessary to receive any input or closing the window.
poll_events :: proc() {
	glfw.PollEvents()
	_update_frame_time()
}

// Checks if the window is going to close.
// Used as game loop condition inside:
//
// `for !should_close() `
should_close :: proc() -> bool {
	return bool(glfw.WindowShouldClose(s.window))
}

// Render begin function: Make sure to use this before drawing something.
// Needs to be closed by render_end() when finished drawing.
render_begin :: proc() {
	gl.Viewport(0, 0, i32(s.width), i32(s.height))
	gl.Clear(gl.COLOR_BUFFER_BIT)
}

// Draws the final batch 
// and presents the rendering on screen (swapping buffers).
render_end :: proc() {
	_draw_next_batch(s.batch.last_texture_id)
	glfw.SwapBuffers(s.window)
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Drawing Functions                                                                             //
///////////////////////////////////////////////////////////////////////////////////////////////////

// Draw a simple colorized rectangle shape on the screen
draw_rectangle :: proc(dest: Rect, tint: Color) {
	_render_object(s.batch.basic_texture, {0,0,1,1}, dest, tint, 0)
}

// Draw a texture at position
draw_texture_pos :: proc(texture: Texture, position: Vec2, origin: Vec2 = {}, scale: Vec2 = {1,1}, tint: Color = WHITE) {
	_render_object(
		texture, 
		{0,0,f32(texture.width),f32(texture.height)}, 
		{position.x - origin.x, position.y - origin.y, f32(texture.width) * scale.x, f32(texture.height) * scale.y}, 
		tint, 
		0,
	)
}

// Draw only a section from a texture on the screen
draw_texture_part :: proc(texture: Texture, source, dest: Rect, tint: Color) {
	_render_object(texture, source, dest, tint, 0)
}

// Draw text on the screen
draw_text :: proc(text: string, position: Vec2, font_size: f32, color: Color = WHITE, font := s.font) {
	// Complex stuff I reall  don't understand but it seems to work
	pixel_scale := font_size / font.size
	ascent, descent, line_gap: i32
	truetype.GetFontVMetrics(&s.font_info, &ascent, &descent, &line_gap)
	scale := truetype.ScaleForPixelHeight(&s.font_info, font.size)
	ix0, iy0, ix1, iy1: i32
	truetype.GetCodepointBitmapBox(&s.font_info, 'H', scale, scale, &ix0, &iy0, &ix1, &iy1)
	cap_height := f32(-iy0)
	line_height := (cap_height + f32(-descent) + f32(line_gap)) * scale * 2
	x := position.x / pixel_scale
	y := position.y / pixel_scale + cap_height

	for r in text {
		if r == '\n' {
			x = position.x / pixel_scale
			y += line_height
			continue
		}

		rf := r
		if r < 32 || r > 126 {
			rf = '?'
		}

		char_index := int(rf) - 32

		q: truetype.aligned_quad
		truetype.GetPackedQuad(
			&font.pack[0],
			i32(font.atlas.width),
			i32(font.atlas.height),
			i32(char_index),
			&x,
			&y,
			&q,
			true,
		)

		source: Rect = {
			q.s0 * f32(font.atlas.width),
			q.t0 * f32(font.atlas.height),
			(q.s1 - q.s0) * f32(font.atlas.width),
			(q.t1 - q.t0) * f32(font.atlas.height),
		}

		dest: Rect = {
			q.x0 * pixel_scale,
			q.y0 * pixel_scale,
			(q.x1 - q.x0) * pixel_scale,
			(q.y1 - q.y0) * pixel_scale,
		}

		_render_object(font.atlas, source, dest, color, 0)
	}
}

// Draw fps (frames per second) on the screen
draw_fps :: proc(position: Vec2, font_size: f32, color: Color = WHITE) {
	fps := int(math.floor(1.0/delta_time()))
	draw_text(fmt.tprint("FPS:", fps), position, font_size, color)
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Common Game/Window Functions                                                                  //
///////////////////////////////////////////////////////////////////////////////////////////////////


close_window    :: proc() { glfw.SetWindowShouldClose(s.window, true) } // Close the game window
clear_color     :: proc(color: Color) { gl.ClearColor(color.r, color.g, color.b, color.a) } // Clear the background with a color
shader_bind     :: proc(s: Shader) { gl.UseProgram(s) } // Bind/use a shader
delta_time      :: proc() -> f32 { return s.delta_time } // Receive delta time (used for frame time based movement)
window_width    :: proc() -> int { return s.width } // Get window width
window_height   :: proc() -> int { return s.height } // Get window height
window_title    :: proc() -> string { return s.title } // Get window title
set_vsync       :: proc(vsync: bool) { s.vsync = vsync; if vsync do glfw.SwapInterval(1); else do glfw.SwapInterval(0) } // Enable/Disable vertical sync (monitor)
vsync			    :: proc() -> bool { return s.vsync } // Get vsync flag
set_window_size :: proc(size: Vec2) { s.width = int(size.x); s.height = int(size.y); glfw.SetWindowSize(s.window, i32(s.width), i32(s.height)); } // Update/Change the window size

///////////////////////////////////////////////////////////////////////////////////////////////////
// Loading Assets/Files                                                                          //
///////////////////////////////////////////////////////////////////////////////////////////////////


// loading a shader from file (GLSL, OpenGL3.3, Core)
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

// Loading a texture form file (.png)
load_texture :: proc(file: string) -> (tex: Texture) {
	gl.GenTextures(1, &tex.id)
	gl.BindTexture(gl.TEXTURE_2D, tex.id)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

	x, y, channels: i32
	data := image.load(fmt.ctprint(file), &x, &y, &channels, 0)
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

	image.image_free(data)

	return tex
}

// loading a font from file (.ttf)
load_font :: proc(file: string, font_size: f32, atlas_size := 1024) -> (font: Font) {
	FONT_FIRST_UNICODE_IN_RANGE :: 32
	FONT_UNICODE_RANGE :: 95

	// read from file
	data, data_ok := os.read_entire_file(file, context.allocator)
	if data_ok != os.General_Error.None {
		log.error("Failed to load font:", file," with err:", data_ok)
	}

	// load font into memory
	if ok := truetype.InitFont(&s.font_info, raw_data(data), 0); !ok {
		log.error("Failed to initialize font:", file)
	}
	
	// setup font struct
	font = {
		atlas = { width = atlas_size, height = atlas_size },
		pack = make([dynamic]truetype.packedchar, FONT_UNICODE_RANGE, context.allocator),
		size = font_size,
	}
	
	bitmap := make([]u8, font.atlas.width * font.atlas.height, context.temp_allocator)
	
	// pack bitmap texture
	{
		pc: truetype.pack_context
		if truetype.PackBegin(&pc, raw_data(bitmap), i32(font.atlas.width), i32(font.atlas.height), 0, 1, nil) == 0 {
			log.error("Failed to pack font: ", file)
		}

		truetype.PackSetOversampling(&pc, 2, 2)
		truetype.PackFontRange(&pc, raw_data(data), 0, font.size, FONT_FIRST_UNICODE_IN_RANGE, FONT_UNICODE_RANGE, &font.pack[0])
		truetype.PackEnd(&pc)
	}

	// load bitmap into video memory
	{
		gl.GenTextures(1, &font.atlas.id)
		gl.BindTexture(gl.TEXTURE_2D, font.atlas.id)
		gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
		gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)
		
		swizzle: [4]i32 = {gl.RED, gl.RED, gl.RED, gl.RED}
		gl.TexParameteriv(gl.TEXTURE_2D, gl.TEXTURE_SWIZZLE_RGBA, &swizzle[0])
		gl.TexImage2D(gl.TEXTURE_2D, 0, gl.R8, i32(font.atlas.width), i32(font.atlas.height), 0, gl.RED, gl.UNSIGNED_BYTE, &bitmap[0])
	}

	return font
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Util/Math (Helper) Functions                                                                  //
///////////////////////////////////////////////////////////////////////////////////////////////////


// TODO: Refactor keys (Define Inputs)
key_escape_pressed :: proc(key: i32) -> bool {
	return glfw.GetKey(s.window, key) == glfw.PRESS
}

// Converting/Snapping a normalized color (f32) to color (bytes/u8)
// 
// Warning: In case use you any ease/lerp with delta avoid using bytes for colors!
as_color_u8 :: proc(color: Color) -> [4]byte {
	return {
		byte(math.round(color.r * 255.0)),
		byte(math.round(color.g * 255.0)),
		byte(math.round(color.b * 255.0)),
		byte(math.round(color.a * 255.0)),
	}
}

// Converting a color (bytes/u8) to a normalized color (f32)
as_color_f32 :: proc(color: [4]byte) -> Color {
	return {
		f32(color.r) / 255.0,
		f32(color.g) / 255.0,
		f32(color.b) / 255.0,
		f32(color.a) / 255.0,
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Local Functions                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////

// Initialize glfw and glfw errors.
@(private="file") _init_glfw :: proc(width, height: int, title: string) {
	// glfw error handling
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

	// set internal state
	s.window = glfw.CreateWindow(i32(width), i32(height), fmt.ctprint(title), nil, nil)
	s.width = width
	s.height = height
	s.title = title

	// activate context
	glfw.MakeContextCurrent(s.window)
}

// Loads OpenGL 3.3
@(private="file") _load_open_gl :: proc() {
	set_proc_address :: proc(p: rawptr, name: cstring) {
		(cast(^rawptr)p)^ = rawptr(glfw.GetProcAddress(name))
	}
	gl.load_up_to(3, 3, set_proc_address)
}

// Creates the buffers for the default batch renderer
@(private="file") _create_default_batch_buffers :: proc() {
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
}

// Generates a basic white texture rectangle 1x1.
// Will be used for drawing simple colorized rectangles.
@(private="file") _gen_basic_rect_texture :: proc() {
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

// Updates the delta time 
@(private="file") _update_frame_time :: proc() {
	current_time := glfw.GetTime()
	delta := current_time - s.last_time
	s.last_time = current_time
	s.delta_time = f32(delta)
}

// Appending vertices from draw call.
// Additionally flushing the batch renderer if necessary.
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

// Rendering the current batch holding the vertex buffer
// Will clear the vertex buffer when finished
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

///////////////////////////////////////////////////////////////////////////////////////////////////