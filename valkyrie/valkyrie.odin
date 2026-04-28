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

import "base:runtime"

import "core:encoding/hex"
import "core:os"
import "core:log"
import "core:fmt"
import "core:slice"
import "core:strings"
import "core:math"
import lin "core:math/linalg"

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
MAX_GAMEPADS :: 8

///////////////////////////////////////////////////////////////////////////////////////////////////
// Internal Valkyrie State                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////


InputState :: enum {
	Up,
	Pressed,
	Down,
	Released,
}

MouseButton :: enum {
	Left    = glfw.MOUSE_BUTTON_1,
	Right   = glfw.MOUSE_BUTTON_2,
	Middle  = glfw.MOUSE_BUTTON_3,
	Back    = glfw.MOUSE_BUTTON_4,
	Forward = glfw.MOUSE_BUTTON_5,
	Extra1  = glfw.MOUSE_BUTTON_6,
	Extra2  = glfw.MOUSE_BUTTON_7,
	Extra3  = glfw.MOUSE_BUTTON_8,
}


Key :: enum int {
	Space        = glfw.KEY_SPACE,
	Apostrophe   = glfw.KEY_APOSTROPHE,
	Comma        = glfw.KEY_COMMA,
	Minus        = glfw.KEY_MINUS,
	Period       = glfw.KEY_PERIOD,
	Slash        = glfw.KEY_SLASH,
	Semicolon    = glfw.KEY_SEMICOLON,
	Equal        = glfw.KEY_EQUAL,
	LeftBracket  = glfw.KEY_LEFT_BRACKET,
	Backslash    = glfw.KEY_BACKSLASH,
	RightBracket = glfw.KEY_RIGHT_BRACKET,
	GraveAccent  = glfw.KEY_GRAVE_ACCENT,
	World1       = glfw.KEY_WORLD_1,
	World2       = glfw.KEY_WORLD_2,

	Key0 = glfw.KEY_0,
	Key1 = glfw.KEY_1,
	Key2 = glfw.KEY_2,
	Key3 = glfw.KEY_3,
	Key4 = glfw.KEY_4,
	Key5 = glfw.KEY_5,
	Key6 = glfw.KEY_6,
	Key7 = glfw.KEY_7,
	Key8 = glfw.KEY_8,
	Key9 = glfw.KEY_9,

	A = glfw.KEY_A,
	B = glfw.KEY_B,
	C = glfw.KEY_C,
	D = glfw.KEY_D,
	E = glfw.KEY_E,
	F = glfw.KEY_F,
	G = glfw.KEY_G,
	H = glfw.KEY_H,
	I = glfw.KEY_I,
	J = glfw.KEY_J,
	K = glfw.KEY_K,
	L = glfw.KEY_L,
	M = glfw.KEY_M,
	N = glfw.KEY_N,
	O = glfw.KEY_O,
	P = glfw.KEY_P,
	Q = glfw.KEY_Q,
	R = glfw.KEY_R,
	S = glfw.KEY_S,
	T = glfw.KEY_T,
	U = glfw.KEY_U,
	V = glfw.KEY_V,
	W = glfw.KEY_W,
	X = glfw.KEY_X,
	Y = glfw.KEY_Y,
	Z = glfw.KEY_Z,

	Escape      = glfw.KEY_ESCAPE,
	Enter       = glfw.KEY_ENTER,
	Tab         = glfw.KEY_TAB,
	Backspace   = glfw.KEY_BACKSPACE,
	Insert      = glfw.KEY_INSERT,
	Delete      = glfw.KEY_DELETE,
	Right       = glfw.KEY_RIGHT,
	Left        = glfw.KEY_LEFT,
	Down        = glfw.KEY_DOWN,
	Up          = glfw.KEY_UP,
	PageUp      = glfw.KEY_PAGE_UP,
	PageDown    = glfw.KEY_PAGE_DOWN,
	Home        = glfw.KEY_HOME,
	End         = glfw.KEY_END,
	CapsLock    = glfw.KEY_CAPS_LOCK,
	ScrollLock  = glfw.KEY_SCROLL_LOCK,
	NumLock     = glfw.KEY_NUM_LOCK,
	PrintScreen = glfw.KEY_PRINT_SCREEN,
	Pause       = glfw.KEY_PAUSE,

	F1  = glfw.KEY_F1,
	F2  = glfw.KEY_F2,
	F3  = glfw.KEY_F3,
	F4  = glfw.KEY_F4,
	F5  = glfw.KEY_F5,
	F6  = glfw.KEY_F6,
	F7  = glfw.KEY_F7,
	F8  = glfw.KEY_F8,
	F9  = glfw.KEY_F9,
	F10 = glfw.KEY_F10,
	F11 = glfw.KEY_F11,
	F12 = glfw.KEY_F12,
	F13 = glfw.KEY_F13,
	F14 = glfw.KEY_F14,
	F15 = glfw.KEY_F15,
	F16 = glfw.KEY_F16,
	F17 = glfw.KEY_F17,
	F18 = glfw.KEY_F18,
	F19 = glfw.KEY_F19,
	F20 = glfw.KEY_F20,
	F21 = glfw.KEY_F21,
	F22 = glfw.KEY_F22,
	F23 = glfw.KEY_F23,
	F24 = glfw.KEY_F24,
	F25 = glfw.KEY_F25,

	Kp0        = glfw.KEY_KP_0,
	Kp1        = glfw.KEY_KP_1,
	Kp2        = glfw.KEY_KP_2,
	Kp3        = glfw.KEY_KP_3,
	Kp4        = glfw.KEY_KP_4,
	Kp5        = glfw.KEY_KP_5,
	Kp6        = glfw.KEY_KP_6,
	Kp7        = glfw.KEY_KP_7,
	Kp8        = glfw.KEY_KP_8,
	Kp9        = glfw.KEY_KP_9,
	KpDecimal  = glfw.KEY_KP_DECIMAL,
	KpDivide   = glfw.KEY_KP_DIVIDE,
	KpMultiply = glfw.KEY_KP_MULTIPLY,
	KpSubtract = glfw.KEY_KP_SUBTRACT,
	KpAdd      = glfw.KEY_KP_ADD,
	KpEnter    = glfw.KEY_KP_ENTER,
	KpEqual    = glfw.KEY_KP_EQUAL,

	LeftShift    = glfw.KEY_LEFT_SHIFT,
	LeftControl  = glfw.KEY_LEFT_CONTROL,
	LeftAlt      = glfw.KEY_LEFT_ALT,
	LeftSuper    = glfw.KEY_LEFT_SUPER,
	RightShift   = glfw.KEY_RIGHT_SHIFT,
	RightControl = glfw.KEY_RIGHT_CONTROL,
	RightAlt     = glfw.KEY_RIGHT_ALT,
	RightSuper   = glfw.KEY_RIGHT_SUPER,
	Menu         = glfw.KEY_MENU,
}

GamepadButton :: enum int {
	A           = glfw.GAMEPAD_BUTTON_A,
	B           = glfw.GAMEPAD_BUTTON_B,
	X           = glfw.GAMEPAD_BUTTON_X,
	Y           = glfw.GAMEPAD_BUTTON_Y,
	LeftBumper  = glfw.GAMEPAD_BUTTON_LEFT_BUMPER,
	RightBumper = glfw.GAMEPAD_BUTTON_RIGHT_BUMPER,
	Back        = glfw.GAMEPAD_BUTTON_BACK,
	Start       = glfw.GAMEPAD_BUTTON_START,
	Guide       = glfw.GAMEPAD_BUTTON_GUIDE,
	LeftThumb   = glfw.GAMEPAD_BUTTON_LEFT_THUMB,
	RightThumb  = glfw.GAMEPAD_BUTTON_RIGHT_THUMB,
	DpadUp      = glfw.GAMEPAD_BUTTON_DPAD_UP,
	DpadRight   = glfw.GAMEPAD_BUTTON_DPAD_RIGHT,
	DpadDown    = glfw.GAMEPAD_BUTTON_DPAD_DOWN,
	DpadLeft    = glfw.GAMEPAD_BUTTON_DPAD_LEFT,
}

GamepadAxis :: enum int {
	LeftX        = glfw.GAMEPAD_AXIS_LEFT_X,
	LeftY        = glfw.GAMEPAD_AXIS_LEFT_Y,
	RightX       = glfw.GAMEPAD_AXIS_RIGHT_X,
	RightY       = glfw.GAMEPAD_AXIS_RIGHT_Y,
	LeftTrigger  = glfw.GAMEPAD_AXIS_LEFT_TRIGGER,
	RightTrigger = glfw.GAMEPAD_AXIS_RIGHT_TRIGGER,
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Internal Valkyrie State                                                                       //
///////////////////////////////////////////////////////////////////////////////////////////////////


Val_State :: struct {
	width:                       int,
	height:                      int,
	title:                       string,
	window:                      glfw.WindowHandle,
	batch:                       Renderer,
	projection_view:             Mat4,
	last_time:                   f64,
	delta_time:                  f32,
	vsync:			              bool,
	font_info: 		              truetype.fontinfo,
	font:				              Font,
	input_key_states:            #sparse [Key]InputState,
	input_gamepad_button_states: [MAX_GAMEPADS][GamepadButton]InputState,
	input_gamepad_axis_values:   [MAX_GAMEPADS][GamepadAxis]f32,
	input_active_gamepad:        int,
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

Camera :: struct {
	position: Vec2,
	offset: Vec2,
	zoom: f32,
	rotation: f32,
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
	s.projection_view = _get_ortho_matrix()
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
	_update_key_states()
	_update_gamepad_states()
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



camera_begin :: proc(camera: Camera) {
	cam_matrix :=
		lin.matrix4_translate_f32({camera.offset.x, camera.offset.y, 0}) *
		lin.matrix4_scale_f32({camera.zoom, camera.zoom, 1}) *
		lin.matrix4_rotate_f32(camera.rotation, {0, 0, 1}) *
		lin.matrix4_translate_f32({-camera.position.x, -camera.position.y, 0})
	s.projection_view = _get_ortho_matrix() * cam_matrix
}

camera_end :: proc() {
	_draw_next_batch(s.batch.last_texture_id)
	s.projection_view = _get_ortho_matrix()
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
bind_shader     :: proc(s: Shader) { gl.UseProgram(s) } // Bind/use a shader
delta_time      :: proc() -> f32 { return s.delta_time } // Receive delta time (used for frame time based movement)
window_width    :: proc() -> int { return s.width } // Get window width
window_height   :: proc() -> int { return s.height } // Get window height
window_title    :: proc() -> string { return s.title } // Get window title
set_vsync       :: proc(vsync: bool) { s.vsync = vsync; if vsync do glfw.SwapInterval(1); else do glfw.SwapInterval(0) } // Enable/Disable vertical sync (monitor)
vsync			    :: proc() -> bool { return s.vsync } // Get vsync flag
set_window_size :: proc(size: Vec2) { s.width = int(size.x); s.height = int(size.y); glfw.SetWindowSize(s.window, i32(s.width), i32(s.height)); } // Update/Change the window size

set_uniform_mat4 :: proc(shader: Shader, location: string, value: ^Mat4) {
	// TODO: make different set uniform functions
	// TODO: Load uniform locations once 

	gl.UniformMatrix4fv(
		gl.GetUniformLocation(shader, fmt.ctprint(location)),
		1,
		gl.FALSE,
		raw_data(&value[0]),
	)
} 

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
// Input Functions                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


key_is_up       :: proc(key: Key) -> bool { state := s.input_key_states[key]; return state == .Up || state == .Released }  // Key is up (hold)
key_is_pressed  :: proc(key: Key) -> bool { return s.input_key_states[key] == .Pressed }                                   // Key is pressed (one-time)
key_is_down     :: proc(key: Key) -> bool { state := s.input_key_states[key]; return state == .Down || state == .Pressed } // Key is down (hold)
key_is_released :: proc(key: Key) -> bool { return s.input_key_states[key] == .Released }                                  // Key is released (one-time)
key_get_state   :: proc(key: Key) -> InputState { return s.input_key_states[key] }                                         // Return key input state

gamepad_is_up       :: proc(button: GamepadButton, device := -1) -> bool { return _gamepad_check_game_state(button, {.Up, .Released}, device) }  // Gamepad button is up (hold)
gamepad_is_pressed  :: proc(button: GamepadButton, device := -1) -> bool { return _gamepad_check_game_state(button, {.Pressed}, device) }        // Gamepad button is pressed (one-time) | device = -1 means take the active gamepad
gamepad_is_down     :: proc(button: GamepadButton, device := -1) -> bool { return _gamepad_check_game_state(button, {.Down, .Pressed}, device) } // Gamepad button is down (hold) | device = -1 means any gamepad
gamepad_is_released :: proc(button: GamepadButton, device := -1) -> bool { return _gamepad_check_game_state(button, {.Released}, device) }       // Gamepad button is released (one-time) | device = -1 means any gamepad 
gamepad_get_state   :: proc(button: GamepadButton, device := -1) -> InputState { return _gamepad_get_game_state(button, device) }                // Return gamepad button input state

// Returns axis value (-1.0 to 1.0). With device=-1 returns the axis of the active/focused gamepad 
gamepad_axis :: proc(axis: GamepadAxis, device := -1) -> f32 {
	assert(device >= -1 && device < MAX_GAMEPADS)
	device := math.clamp(device, -1, MAX_GAMEPADS)
	
	if device == -1 {
 		return s.input_gamepad_axis_values[s.input_active_gamepad][axis]
	} else {
		return s.input_gamepad_axis_values[device][axis]
	}
}

// Returns -1, 0 or 1 from two opposing inputs (e.g. left/right keys or analog values)
input_axis      :: proc {input_axis_bool, input_axis_f32}
input_axis_bool :: proc(negative, positive: bool) -> f32 { return f32(int(positive)) - f32(int(negative)) }
input_axis_f32  :: proc(negative, positive: f32)  -> f32 { return positive - negative }

// Returns a 2D direction vector from four opposing inputs
input_vector      :: proc{input_vector_bool, input_vector_f32}
input_vector_bool :: proc(left, right, up, down: bool) -> Vec2 { return { f32(int(right)) - f32(int(left)), f32(int(down)) - f32(int(up)) } }
input_vector_f32  :: proc(left, right, up, down: f32)  -> Vec2 { return { right - left, down - up } }

///////////////////////////////////////////////////////////////////////////////////////////////////
// Util/Math (Helper) Functions                                                                  //
///////////////////////////////////////////////////////////////////////////////////////////////////


// Converting/Snapping a normalized color (f32) to color (bytes/u8)
// 
// Warning: In case you ease/lerp your color with delta, avoid the use of byte-colors entirely!
// Otherwise you will lose every frame some delta precicion of any fraction smaller than 1/256
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
	bind_shader(s.batch.shader)
	set_uniform_mat4(s.batch.shader, "u_proj_view", &s.projection_view)

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

// Get the orthogonal matrix of the current screen size
@(private="file") _get_ortho_matrix :: proc() -> Mat4 {
	return lin.matrix_ortho3d_f32(0, f32(s.width), f32(s.height), 0, -1, 1)
}

// Updates all key states
@(private="file") _update_key_states :: proc() {
	for &key_state, key in s.input_key_states {
		glfw_key_state := glfw.GetKey(s.window, i32(key))

		switch key_state {
		case .Up:
			if glfw_key_state == glfw.PRESS do key_state = .Pressed 
		case .Pressed:
			if glfw_key_state == glfw.PRESS do key_state = .Down 
			else if glfw_key_state == glfw.RELEASE do key_state = .Released
		case .Down:
			if glfw_key_state == glfw.RELEASE do key_state = .Released 
		case .Released:
			if glfw_key_state == glfw.PRESS do key_state = .Pressed 
			else if glfw_key_state == glfw.RELEASE do key_state = .Up 
		}
	}
}

// Updates all gamepad states
@(private="file") _update_gamepad_states :: proc() {
	ACTIVE_AXIS_THRESHOLD :: 0.66

	for i in 0 ..< MAX_GAMEPADS {

		if !glfw.JoystickIsGamepad(i32(i)) {
			s.input_gamepad_button_states[i] = {}
			continue
		}

		glfw_state: glfw.GamepadState
		if !glfw.GetGamepadState(i32(i), &glfw_state) {
			s.input_gamepad_button_states[i] = {}
			continue
		}

		for &state, button in s.input_gamepad_button_states[i] {
			pressed := glfw_state.buttons[int(button)] == glfw.PRESS

			switch state {
			case .Up:
				if pressed {
					s.input_active_gamepad = i
					state = .Pressed
				}
			case .Pressed:
				if pressed do state = .Down
				else do state = .Released
			case .Down:
				if !pressed do state = .Released
			case .Released:
				if pressed do state = .Pressed
				else do state = .Up
			}
		}
		
		for &value, axis in s.input_gamepad_axis_values[i] {
			value = glfw_state.axes[int(axis)]

			if math.abs(value) >= ACTIVE_AXIS_THRESHOLD {
				s.input_active_gamepad = i
			}
		}
	}
}

// Checks an input gamepad state to expected
@(private="file") _gamepad_check_game_state :: #force_inline proc(button: GamepadButton, any_expected: []InputState, device := -1) -> bool {
	assert(device >= -1 && device < MAX_GAMEPADS)
	device := clamp(device, -1, MAX_GAMEPADS)

	gamepad := device
	if device == -1 {
		gamepad = s.input_active_gamepad
	}

	state := s.input_gamepad_button_states[gamepad][button]

	for expected in any_expected {
		if state == expected {
			return true
		}
	}
	return false
}

// Returns the gamepad input state from any device: 1-8
_gamepad_get_game_state :: #force_inline proc(button: GamepadButton, device := -1) -> InputState {
	assert(device >= -1 && device < MAX_GAMEPADS)
	device := clamp(device, -1, MAX_GAMEPADS)

	if device == -1 {
		return s.input_gamepad_button_states[s.input_active_gamepad][button]
	} else {
		return s.input_gamepad_button_states[device][button]
	}
}

///////////////////////////////////////////////////////////////////////////////////////////////////