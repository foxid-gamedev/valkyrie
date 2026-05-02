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

///////////////////////////////////////////////////////////////////////////////////////////////////
// TODO:                                                                                         //
//                                                                                               //
// - Enhance performance input states                                                            //
// - Add uniform locations                                                                       //
// - Add more uniform functions                                                                  //
// - Use persistent camera matrix (efficiency)                                                   //
//                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////

package valkyrie

import "core:mem"
import "base:runtime"

import "core:os"
import "core:log"
import "core:fmt"
import "core:strings"
import "core:math"
import lin "core:math/linalg"

import "vendor:stb/image"
import "vendor:stb/truetype"
import gl "vendor:OpenGL"
import "vendor:glfw"
import ma "vendor:miniaudio"

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
TRANSPARENT   :: Color{0.00, 0.00, 0.00, 0.0}

// Grays
WHITE         :: Color{1.00, 1.00, 1.00, 1}
LIGHT_GRAY    :: Color{0.78, 0.78, 0.78, 1}
GRAY          :: Color{0.50, 0.50, 0.50, 1}
DARK_GRAY     :: Color{0.25, 0.25, 0.25, 1}
BLACK         :: Color{0.00, 0.00, 0.00, 1}

// Red
PINK          :: Color{1.00, 0.43, 0.76, 1}
LIGHT_RED     :: Color{1.00, 0.47, 0.47, 1}
RED           :: Color{0.90, 0.16, 0.22, 1}
DARK_RED      :: Color{0.55, 0.07, 0.07, 1}
MAROON        :: Color{0.75, 0.13, 0.22, 1}

// Orange / Yellow
LIGHT_ORANGE  :: Color{1.00, 0.75, 0.40, 1}
ORANGE        :: Color{1.00, 0.63, 0.00, 1}
DARK_ORANGE   :: Color{0.65, 0.35, 0.00, 1}
GOLD          :: Color{1.00, 0.80, 0.00, 1}
YELLOW        :: Color{1.00, 1.00, 0.00, 1}

// Green
LIGHT_GREEN   :: Color{0.50, 1.00, 0.50, 1}
GREEN         :: Color{0.00, 0.89, 0.19, 1}
DARK_GREEN    :: Color{0.00, 0.46, 0.17, 1}
LIME          :: Color{0.50, 1.00, 0.00, 1}

// Cyan / Blue
CYAN          :: Color{0.00, 1.00, 1.00, 1}
TEAL          :: Color{0.00, 0.50, 0.50, 1}
LIGHT_BLUE    :: Color{0.40, 0.75, 1.00, 1}
BLUE          :: Color{0.00, 0.47, 0.95, 1}
DARK_BLUE     :: Color{0.00, 0.32, 0.67, 1}
NAVY          :: Color{0.00, 0.12, 0.40, 1}

// Violet / Purple
LIGHT_VIOLET  :: Color{0.78, 0.48, 1.00, 1}
VIOLET        :: Color{0.53, 0.24, 0.75, 1}
DARK_VIOLET   :: Color{0.30, 0.08, 0.50, 1}
MAGENTA       :: Color{1.00, 0.00, 1.00, 1}
PURPLE        :: Color{0.44, 0.12, 0.49, 1}

// Misc
BROWN         :: Color{0.50, 0.30, 0.10, 1}
BEIGE         :: Color{0.83, 0.69, 0.51, 1}

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

Alighnment        :: enum { Left, Center, Right }
VerticalAlignment :: enum { Top, Center, Bottom }

AttenuationType :: enum { Inverse, Linear, Exponential }

SHAPE_TYPE_TEXTURED :: 0
SHAPE_TYPE_SDF      :: 1

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

	audio : struct {
		engine_config:        ma.engine_config,
		engine:               ma.engine,
		res_manager_config:   ma.resource_manager_config,
		res_manager:          ma.resource_manager,
		master: 				    AudioBus,
		initialized:          bool,
		spatial_min_distance: f32,
		spatial_max_distance: f32,
		attenuation: 			 AttenuationType,
	},
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
	pack:  [dynamic]truetype.packedchar,
	size:  f32,
}

Sound :: struct {
	handle: rawptr,
	_alloc: mem.Allocator,
}

AudioBus :: struct {
	handle: rawptr,
	_alloc: mem.Allocator,
}


Vertex :: struct {
	position: Vec2,   // pos
	uv:       Vec2,   // tex-coords
	tint:     Vec4,   // modulate color
	layer:    i32,    // z-layer
	shape: 	 i32,    // shape enum type
	data:     [4]f32, // shape parameters
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

// Destroys the window and frees all internal memory. Call via defer right after create_window().
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

// Returns true when the window has been requested to close.
// Typical usage: for !vl.should_close() { ... }
should_close :: proc() -> bool {
	return bool(glfw.WindowShouldClose(s.window))
}

// Clears the screen and starts a new frame. Must be paired with render_end().
render_begin :: proc() {
	gl.Viewport(0, 0, i32(s.width), i32(s.height))
	gl.Clear(gl.COLOR_BUFFER_BIT)
}

// Flushes the draw batch and presents the frame on screen (buffer swap). Pair with render_begin().
render_end :: proc() {
	_draw_next_batch(s.batch.last_texture_id)
	glfw.SwapBuffers(s.window)
}



// Applies a camera transform (position, zoom, rotation, offset) to all subsequent draw calls.
// Must be closed with camera_end(). Flushes the current batch before applying the new transform.
camera_begin :: proc(camera: Camera) {
	cam_matrix :=
		lin.matrix4_translate_f32({camera.offset.x, camera.offset.y, 0}) *
		lin.matrix4_scale_f32({camera.zoom, camera.zoom, 1}) *
		lin.matrix4_rotate_f32(camera.rotation, {0, 0, 1}) *
		lin.matrix4_translate_f32({-camera.position.x, -camera.position.y, 0})
	s.projection_view = _get_ortho_matrix() * cam_matrix
}

// Restores the default screen-space projection after camera_begin().
camera_end :: proc() {
	_draw_next_batch(s.batch.last_texture_id)
	s.projection_view = _get_ortho_matrix()
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Drawing Functions                                                                             //
///////////////////////////////////////////////////////////////////////////////////////////////////

// Draws a filled rectangle. dest = {x, y, width, height}.
draw_rectangle :: proc(dest: Rect, tint: Color) {
	_render_object(s.batch.basic_texture, {0,0,1,1}, dest, tint, 0)
}

// Draws an unfilled rectangle outline. thickness is centered on the rect edge (default: 1px).
draw_rectangle_lines :: proc(dest: Rect, tint: Color, thickness: f32 = 1) {
	assert(thickness > 0, "drawing thickness shouldn't be <= 0")
	hf := max(0.01, thickness) * 0.5
	hw := dest.w * 0.5 + hf
	hh := dest.h * 0.5 + hf
	expanded := Rect{dest.x - hf, dest.y - hf, dest.w + thickness, dest.h + thickness}
	_render_object(s.batch.basic_texture, {0,0,1,1}, expanded, tint, 0, SHAPE_TYPE_SDF, {hw, hh, 0, hf})
}

// Draws a filled rectangle with rounded corners. roundness: 0 = sharp, 1 = fully rounded.
draw_rectangle_rounded :: proc(dest: Rect, tint: Color, roundness: f32) {
	hw := dest.w * 0.5
	hh := dest.h * 0.5
	r  := min(hw, hh) * clamp(roundness, 0, 1)
	_render_object(s.batch.basic_texture, {0,0,1,1}, dest, tint, 0, SHAPE_TYPE_SDF, {hw, hh, r, 0})
}

// Draws an unfilled rectangle outline with rounded corners. roundness: 0 = sharp, 1 = fully rounded.
draw_rectangle_lines_rounded :: proc(dest: Rect, tint: Color, roundness: f32, thickness: f32 = 1) {
	assert(thickness > 0, "drawing thickness shouldn't be <= 0")
	hf := max(0.01, thickness) * 0.5
	hw := dest.w * 0.5 + hf
	hh := dest.h * 0.5 + hf
	r  := min(dest.w * 0.5, dest.h * 0.5) * clamp(roundness, 0, 1)
	expanded := Rect{dest.x - hf, dest.y - hf, dest.w + thickness, dest.h + thickness}
	_render_object(s.batch.basic_texture, {0,0,1,1}, expanded, tint, 0, SHAPE_TYPE_SDF, {hw, hh, r, hf})
}

// Draws a filled circle at the given center position.
draw_circle :: proc(position: Vec2, radius: f32, tint: Color) {
	_render_object(
		s.batch.basic_texture,
		{0, 0, 1, 1},
		{position.x - radius, position.y - radius, 2 * radius, 2 * radius},
		tint,
		0,
		SHAPE_TYPE_SDF,
		{radius, radius, radius, 0},
	)
}

// Draws a circle outline. thickness is centered on the circle edge (default: 1px).
draw_circle_lines :: proc(position: Vec2, radius: f32, tint: Color, thickness: f32 = 1) {
	hf      := max(0.01, thickness) * 0.5
	outer_r := radius + hf
	_render_object(
		s.batch.basic_texture,
		{0, 0, 1, 1},
		{position.x - outer_r, position.y - outer_r, 2 * outer_r, 2 * outer_r},
		tint,
		0,
		SHAPE_TYPE_SDF,
		{outer_r, outer_r, outer_r, hf},
	)
}


// Draws a texture at position. origin shifts the anchor point (default: top-left). scale and tint are optional.
draw_texture_pos :: proc(texture: Texture, position: Vec2, origin: Vec2 = {}, scale: Vec2 = {1,1}, tint: Color = WHITE) {
	_render_object(
		texture, 
		{0,0,f32(texture.width),f32(texture.height)}, 
		{position.x - origin.x, position.y - origin.y, f32(texture.width) * scale.x, f32(texture.height) * scale.y}, 
		tint, 
		0,
	)
}

// Draws a sub-region of a texture. source = pixel rect in the texture, dest = screen rect.
draw_texture_part :: proc(texture: Texture, source, dest: Rect, tint: Color) {
	_render_object(texture, source, dest, tint, 0)
}

// Draws text at position with the given font size. Supports horizontal and vertical alignment.
// Alignment is relative to position: .Left = position is the left edge, .Center = centered on position, etc.
draw_text :: proc(
	text: string, 
	position: Vec2, 
	font_size: f32, 
	color: Color = WHITE, 
	alignment := Alighnment.Left,
	vertical_alignment := VerticalAlignment.Top,
	font := s.font,
) {
	// Complex stuff I reall don't understand but it seems to work
	position := position

	pixel_scale := font_size / font.size
	ascent, descent, line_gap: i32
	truetype.GetFontVMetrics(&s.font_info, &ascent, &descent, &line_gap)
	scale := truetype.ScaleForPixelHeight(&s.font_info, font.size)
	ix0, iy0, ix1, iy1: i32
	truetype.GetCodepointBitmapBox(&s.font_info, 'H', scale, scale, &ix0, &iy0, &ix1, &iy1)
	cap_height := f32(-iy0)
	line_height := (cap_height + f32(-descent) + f32(line_gap)) * scale * 2
	
	// horizontal alignment
	if alignment != .Left {
		max_length: f32
		lines := strings.split_lines(text, context.temp_allocator)

		for line in lines {
			max_length = max(max_length, measure_text(line, font_size))
		}
		
		if alignment == .Center {
			max_length *= 0.5
		}

		position.x -= max_length
	}

	// vertical alignment
	if vertical_alignment != .Top {
		line_count : int = strings.count(text, "\n") + 1
		offset := line_height * f32(line_count) 

		if vertical_alignment == .Center {
			offset *= 0.5
		}
		position.y -= offset * pixel_scale
	}

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

// Draws text word-wrapped to fit inside rect. Long lines break automatically at word boundaries.
draw_text_wrapped :: proc(
	text: string, 
	rect: Rect,
	font_size: f32,
	color: Color = WHITE,
	alignment := Alighnment.Left,
	vertical_alignment := VerticalAlignment.Top,
	font := s.font,
) {
	space_width := measure_text(" ", font_size, font)
	builder := strings.builder_make(context.temp_allocator)
	lines := strings.split_lines(text, context.temp_allocator)
	
	loop: for line, l in lines {
		if l > 0 {
			strings.write_byte(&builder, '\n')
		}
		words := strings.split(line, " ", context.temp_allocator)
		current_width: f32
		current_height: f32

		for word, w in words {
			word_width := measure_text(word, font_size, font)
			if w == 0 {
				strings.write_string(&builder, word)
				current_width = word_width
			} else if current_width + space_width + word_width <= rect.w {
				strings.write_byte(&builder, ' ')
				strings.write_string(&builder, word)
				current_width += space_width + word_width
			} else {
				strings.write_byte(&builder, '\n')
				strings.write_string(&builder, word)
				current_width = word_width
			}
		}
	}
	draw_text(strings.to_string(builder), {rect.x, rect.y}, font_size, color, alignment, vertical_alignment, font)
}

// Draw fps (frames per second) on the screen
draw_fps :: proc(position: Vec2, font_size: f32, color: Color = WHITE) {
	fps := int(math.floor(1.0/delta_time()))
	draw_text(fmt.tprint("FPS:", fps), position, font_size, color)
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Common Game/Window Functions                                                                  //
///////////////////////////////////////////////////////////////////////////////////////////////////


close_window       :: proc() { glfw.SetWindowShouldClose(s.window, true) } // Close the game window
clear_color        :: proc(color: Color) { gl.ClearColor(color.r, color.g, color.b, color.a) } // Clear the background with a color
bind_shader        :: proc(s: Shader) { gl.UseProgram(s) } // Bind/use a shader
delta_time         :: proc() -> f32 { return s.delta_time } // Receive delta time (used for frame time based movement)
window_width       :: proc() -> int { return s.width } // Get window width
window_height      :: proc() -> int { return s.height } // Get window height
window_title       :: proc() -> string { return s.title } // Get window title
set_vsync          :: proc(vsync: bool) { s.vsync = vsync; if vsync do glfw.SwapInterval(1); else do glfw.SwapInterval(0) } // Enable/Disable vertical sync (monitor)
vsync			       :: proc() -> bool { return s.vsync } // Get vsync flag
set_window_size    :: proc(size: Vec2) { s.width = int(size.x); s.height = int(size.y); glfw.SetWindowSize(s.window, i32(s.width), i32(s.height)); } // Update/Change the window size
set_mouse_position :: proc(pos: Vec2) {glfw.SetCursorPos(s.window, f64(int(pos.x)), f64(int(pos.y))) } // Moves the mouse cursor to a position in screen coordinates
mouse_position     :: proc() -> Vec2 { x, y := glfw.GetCursorPos(s.window); return {f32(int(x)), f32(int(y))} } // Returns the current mouse cursor position in screen coordinates
show_cursor        :: proc() { glfw.SetInputMode(s.window, glfw.CURSOR, glfw.CURSOR_NORMAL) } // Show mouse cursor
hide_cursor        :: proc() { glfw.SetInputMode(s.window, glfw.CURSOR, glfw.CURSOR_HIDDEN) } // Hide mouse cursor 

// Uploads a Mat4 uniform to a shader by name. The shader must be bound with bind_shader() first.
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


// Loads and compiles a GLSL shader from vertex and fragment source files (OpenGL 3.3 Core).
// Returns the shader handle and false if compilation or linking fails.
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

// Loads a texture from file (.png, .jpg, etc.) into GPU memory. Returns a zero Texture on failure.
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

// Loads a TrueType font and bakes it into a GPU texture atlas at the given size.
// atlas_size controls the atlas resolution — increase it for large font sizes or many glyphs.
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

// Loads a sound from file (.wav, .mp3, .ogg). Optionally assigns it to a bus and sets initial volume, pitch and looping.
// audio_init() must be called before loading sounds. Returns the sound handle and false on failure.
load_sound :: proc(
	filename: string,
	bus := s.audio.master,
	volume: f32 = 1.0,
	pitch: f32 = 1.0,
	loop := false,
	allocator := context.allocator,
) -> (snd: Sound, ok: bool) {
	assert(s.audio.initialized, "audio needs to be initialized with audio_init() before loading sound files")

	snd.handle = new(ma.sound, allocator)
	snd._alloc = allocator
	result := ma.sound_init_from_file(&s.audio.engine, fmt.ctprint(filename), {}, _ma_group(bus), nil, cast(^ma.sound)(snd.handle))
	if result != .SUCCESS {
		free(snd.handle)
		return {nil, {}}, false
	}

	sound_set_volume(snd, volume)
	sound_set_pitch(snd, pitch)
	sound_set_looping(snd, loop)

	return snd, true
}

// Frees a sound's resources. The sound handle becomes invalid after this call.
unload_sound :: proc(sound: ^Sound) -> bool {
	assert(sound.handle != nil, "free_sound failed, sound handle was nil")
	result := free(sound.handle, sound._alloc)
	sound.handle = nil
	return result == .None
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
// Audio Functions                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////


// Initializes the audio engine and creates the master bus. 
audio_init :: proc() -> bool {
	assert(!s.audio.initialized, "audio system has already been initialized")

	result: ma.result
	
	s.audio.res_manager_config = ma.resource_manager_config_init()

	result = ma.resource_manager_init(&s.audio.res_manager_config, &s.audio.res_manager)
	if ( result != .SUCCESS) {
		log.error("AUDIO::INIT::FAILED::RESOURCE_MANAGER_INIT")
		return false
	}

	s.audio.engine_config = ma.engine_config_init()
	s.audio.engine_config.pResourceManager = &s.audio.res_manager

	result = ma.engine_init(&s.audio.engine_config, &s.audio.engine)
	if ( result != .SUCCESS ) {
		log.error("AUDIO::INIT::FAILED::ENGINE_INIT")
		return false
	}
	master_ok: bool
	s.audio.master, master_ok = audio_create_bus()
	if ( !master_ok ) {
		log.error("AUDIO::INIT::FAILED::CREATED_MASTER_BUS")
		return false
	}

	s.audio.initialized = true
	return true
}
 
// Shuts down the audio engine and releases all audio resources.
audio_shutdown :: proc() {
	assert(s.audio.initialized, "audio system has already been destroyed")
	audio_destroy_bus(&s.audio.master)
	ma.resource_manager_uninit(&s.audio.res_manager)
	ma.engine_uninit(&s.audio.engine)
	s.audio.initialized = false
}


// Sets the default attenuation model and distance range used by play_sound_2d().
// min_distance: full volume up to here. max_distance: silent beyond this. Distances in screen units.
audio_set_spatial_defaults :: proc (attenuation: AttenuationType, min_distance, max_distance: f32) {
	s.audio.attenuation = attenuation
	s.audio.spatial_min_distance = min_distance
	s.audio.spatial_max_distance = max_distance
}

// Creates an audio bus for grouping sounds (e.g. separate music and sfx buses).
// Assign sounds to it via the bus parameter in load_sound(). Returns false on failure.
audio_create_bus :: proc(allocator := context.allocator) -> (bus: AudioBus, ok: bool) {
	group := new(ma.sound_group, allocator)
	result := ma.sound_group_init(&s.audio.engine, {}, nil, group)
	if result != .SUCCESS {
		free(group, allocator)
		return {nil, {}}, false
	}

	bus = { rawptr(group), allocator }
	audio_set_spatial_defaults(.Linear, 150, 800)

	return bus, true
}


// Destroys an audio bus and frees its memory. All sounds assigned to it stop playing.
audio_destroy_bus :: proc(bus: ^AudioBus) -> bool {
	assert(bus.handle != nil, "audio_destroy_bus failed, bus handle was nil")
	ma.sound_group_uninit(_ma_group(bus^))
	result := free(bus.handle, bus._alloc)	
	return result == .None
}

// Sets the volume of all sounds on this bus. 0 = silent, 1 = full volume.
audio_bus_set_volume :: proc(bus: AudioBus, volume: f32) {
	ma.sound_group_set_volume(_ma_group(bus), volume)
}

// Returns the current volume of this bus (0..1+).
audio_bus_volume :: proc(bus: AudioBus) -> f32 {
	return ma.sound_group_get_volume(_ma_group(bus))
}

// Sets the pitch multiplier of all sounds on this bus. 1 = normal speed, 2 = double speed.
audio_bus_set_pitch :: proc(bus: AudioBus, pitch: f32) {
	ma.sound_group_set_pitch(_ma_group(bus), pitch)
}

// Returns the current pitch multiplier of this bus.
audio_bus_pitch :: proc(bus: AudioBus) -> f32 {
	return ma.sound_group_get_pitch(_ma_group(bus))
}

// Returns the master bus. All sounds route through it unless assigned to a different bus.
audio_bus_master :: proc() -> AudioBus { return s.audio.master }


// Smoothly fades the bus volume from its current level to 'to' over duration_ms milliseconds.
audio_bus_fade :: proc(bus: AudioBus, to: f32, duration_ms: u64) {
	ma.sound_group_set_fade_in_milliseconds(_ma_group(bus), audio_bus_volume(bus), to, duration_ms)
}


// Sets the listener position for spatial audio (typically the camera or player position).
// Determines the reference point from which 2D sound distances are calculated.
audio_listener_set_position :: proc(position: Vec2) {
	lpos := position * 0.001
	ma.engine_listener_set_position(&s.audio.engine, 0, lpos.x, lpos.y, 0)
}

// Returns the current listener position.
audio_listener_position :: proc() -> Vec2 {
	lpos := ma.engine_listener_get_position(&s.audio.engine, 0)
	return {lpos.x, lpos.y}
}

// Sets the playback volume of a sound. 0 = silent, 1 = full volume.
sound_set_volume :: proc(sound: Sound, volume: f32) {
	ma.sound_set_volume(_ma_sound(sound), volume)
}

// Sets the pitch multiplier of a sound. 1 = normal speed, 0.5 = half speed, 2 = double speed.
sound_set_pitch :: proc(sound: Sound, pitch: f32) {
	ma.sound_set_pitch(_ma_sound(sound), pitch)
}

// Sets whether the sound restarts automatically when it reaches the end.
sound_set_looping :: proc(sound: Sound, loop: bool) {
	ma.sound_set_looping(_ma_sound(sound), b32(loop))
}

// Returns the current volume of a sound (0..1+).
sound_volume :: proc(sound: Sound) -> f32 {
	return ma.sound_get_volume(_ma_sound(sound))
}

// Returns the current pitch multiplier of a sound.
sound_pitch :: proc(sound: Sound) -> f32 {
	return ma.sound_get_pitch(_ma_sound(sound))
}

// Returns true if the sound is set to loop.
sound_is_looping :: proc(sound: Sound) -> bool {
	return bool(ma.sound_is_looping(_ma_sound(sound)))
}

// Plays a sound without any spatial positioning (non-directional, full volume).
play_sound :: proc(sound: Sound) {
	assert(s.audio.initialized, "audio system needs to be initialized with audio_init() before playing any sound")
	handle := _ma_sound(sound)
	result := ma.sound_start(handle)
	assert(result == .SUCCESS, "starting sound failed")
}

// Plays a sound at a 2D world position. Volume attenuates with distance from the listener.
// Uses the default range set with audio_set_spatial_defaults().
play_sound_2d :: proc(sound: Sound , pos: Vec2) {
	assert(s.audio.initialized, "audio system needs to be initialized with audio_init() before playing any sound")
	handle := _ma_sound(sound)
	lpos := pos * 0.001
	ma.sound_set_position(handle, lpos.x, lpos.y, 0)

	am : ma.attenuation_model
	switch s.audio.attenuation {
	case .Inverse: am = .inverse
	case .Linear: am = .linear
	case .Exponential: am = .exponential
	}

	ma.sound_set_attenuation_model(handle, am)
	ma.sound_set_min_distance(handle, s.audio.spatial_min_distance * 0.001)
	ma.sound_set_max_distance(handle, s.audio.spatial_max_distance * 0.001)
	result := ma.sound_start(handle)
	assert(result == .SUCCESS, "starting 2d sound failed")
}

// Plays a 2D positional sound with explicit distance range and attenuation model.
// min_distance: full volume up to here. max_distance: silent beyond this.
play_sound_2d_range :: proc(sound: Sound, pos: Vec2, min_distance: f32, max_distance: f32, attenuation := AttenuationType.Linear) {
	assert(s.audio.initialized, "audio system needs to be initialized with audio_init() before playing any sound")
	handle := _ma_sound(sound)
	lpos := pos * 0.001
	ma.sound_set_position(handle, lpos.x, lpos.y, 0)

	am : ma.attenuation_model
	switch attenuation {
	case .Inverse: am = .inverse
	case .Linear: am = .linear
	case .Exponential: am = .exponential
	}

	ma.sound_set_attenuation_model(handle, am)
	ma.sound_set_min_distance(handle, min_distance * 0.001)
	ma.sound_set_max_distance(handle, max_distance * 0.001)
	result := ma.sound_start(handle)
	assert(result == .SUCCESS, "starting 2d ranged sound failed")
}

// Stops a currently playing sound. Call play_sound() again to restart it.
stop_sound :: proc(sound: Sound) {
	ma.sound_stop(_ma_sound(sound))
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Collision Functions                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////


// Returns true if two axis-aligned rectangles overlap (AABB test).
check_collision_rects :: proc(rect_a, rect_b: Rect) -> bool {
	w := ((rect_a.x + rect_a.w) >= rect_b.x) && (rect_a.x <= (rect_b.x + rect_b.w))
	h := ((rect_a.y + rect_a.h) >= rect_b.y) && (rect_a.y <= (rect_b.y + rect_b.h))
	return w && h
}

// Returns true if a point lies inside a rectangle (inclusive edges).
check_collision_point_in_rect :: proc(point: Vec2, rect: Rect) -> bool {
	w := (point.x >= rect.x) && (point.x <= rect.x + rect.w)
	h := (point.y >= rect.y) && (point.y <= rect.y + rect.h)
	return w && h
}

// Returns true if two circles overlap. Uses squared distance to avoid sqrt.
check_collision_circles :: proc(circle_a_pos: Vec2, circle_a_radius: f32, circle_b_pos: Vec2, circle_b_radius: f32) -> bool {
	dist       := circle_b_pos - circle_a_pos
	sum_radius := circle_a_radius + circle_b_radius
	return (dist.x * dist.x) + (dist.y * dist.y) <= (sum_radius * sum_radius)
}

// Returns true if a point lies inside a circle (inclusive edges).
check_collision_point_in_circle :: proc(point: Vec2, circle_pos: Vec2, circle_radius: f32) -> bool {
	dist := point - circle_pos
	return  (dist.x * dist.x) + (dist.y * dist.y) <= (circle_radius * circle_radius)
}

// Returns true if a circle overlap a rectangle. Used squared distance to avoid sqrt.
check_collision_circle_rect :: proc(circle_pos: Vec2, circle_radius: f32, rect: Rect) -> bool {
	nearest := Vec2{
		clamp(circle_pos.x, rect.x, rect.x + rect.w),
		clamp(circle_pos.y, rect.y, rect.y + rect.h),
	}
	dist := circle_pos - nearest
	return (dist.x * dist.x) + (dist.y * dist.y) <= (circle_radius * circle_radius)
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Util/Math (Helper) Functions                                                                  //
///////////////////////////////////////////////////////////////////////////////////////////////////


// Converts a normalized float color (0..1) to a byte color (0..255).
// Warning: avoid for lerped/eased values — precision below 1/256 is lost on every frame.
as_color_u8 :: proc(color: Color) -> [4]byte {
	return {
		byte(math.round(color.r * 255.0)),
		byte(math.round(color.g * 255.0)),
		byte(math.round(color.b * 255.0)),
		byte(math.round(color.a * 255.0)),
	}
}

// Converts a byte color (0..255) to a normalized float color (0..1).
as_color_f32 :: proc(color: [4]byte) -> Color {
	return {
		f32(color.r) / 255.0,
		f32(color.g) / 255.0,
		f32(color.b) / 255.0,
		f32(color.a) / 255.0,
	}
}

// Returns the color with its alpha multiplied by the given factor. Useful for transparency effects.
fade_color :: proc(color: Color, alpha: f32) -> Color {
	return {
		color.r,
		color.g,
		color.b,
		color.a * alpha,
	}
}


// Returns the rendered pixel width of a text string at the given font size. Useful for manual layout and centering.
measure_text :: proc(text: string, font_size: f32, font := s.font) -> f32 {
	scale := truetype.ScaleForPixelHeight(&s.font_info, font.size)
	pixel_scale := font_size / font.size
	width: f32
	for r in text {
		rune_width, bearing: i32
		truetype.GetCodepointHMetrics(&s.font_info, r, &rune_width, &bearing)
		width += f32(rune_width) * scale
	}
	return width * pixel_scale
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Local Functions                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////

// Creates the window, sets up an OpenGL 3.3 Core context and registers the GLFW error callback.
@private _init_glfw :: proc(width, height: int, title: string) {
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

// Loads all OpenGL 3.3 function pointers via GLFW's proc address resolver.
@private _load_open_gl :: proc() {
	set_proc_address :: proc(p: rawptr, name: cstring) {
		(cast(^rawptr)p)^ = rawptr(glfw.GetProcAddress(name))
	}
	gl.load_up_to(3, 3, set_proc_address)
}

// Allocates the VAO, VBO and EBO for the batch renderer and pre-bakes the full index buffer.
// Indices follow the pattern [0,1,2, 0,2,3] per quad (two CCW triangles).
@private _create_default_batch_buffers :: proc() {
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
		gl.VertexAttribIPointer(3, 1, gl.INT, size_of(Vertex), offset_of(Vertex, layer))
		gl.EnableVertexAttribArray(3)
		gl.VertexAttribIPointer(4, 1, gl.INT, size_of(Vertex), offset_of(Vertex, shape))
		gl.EnableVertexAttribArray(4)
		gl.VertexAttribPointer(5, 4, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, data))
		gl.EnableVertexAttribArray(5)

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

// Creates a 1×1 white RGBA texture used as the default for all solid-color shape draws.
@private _gen_basic_rect_texture :: proc() {
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

// Measures elapsed time since the last frame and stores it in s.delta_time.
@private _update_frame_time :: proc() {
	current_time := glfw.GetTime()
	delta := current_time - s.last_time
	s.last_time = current_time
	s.delta_time = f32(delta)
}

// Appends four vertices (one quad) to the batch buffer.
// Flushes the current batch first if the texture changes, to maintain correct draw order.
@private _render_object :: proc(texture: Texture, source, dest: Rect, tint: Color, layer: i32, shape_type: i32 = SHAPE_TYPE_TEXTURED, shape_data: [4]f32 = {}) {
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
		Vertex{{dest.x, dest.y},{uv.x,uv.y}, tint, layer, shape_type, shape_data}, 
		Vertex{{dest.x + dest.w, dest.y},{uv.x + uv.w, uv.y}, tint, layer, shape_type, shape_data},
		Vertex{{dest.x + dest.w, dest.y + dest.h},{uv.x + uv.w, uv.y + uv.h}, tint, layer, shape_type, shape_data},
		Vertex{{dest.x, dest.y + dest.h},{uv.x,uv.y + uv.h}, tint, layer, shape_type, shape_data},
	)
}

// Uploads the accumulated vertex buffer to the GPU and issues one indexed draw call, then clears the buffer.
@private _draw_next_batch :: proc(texture_id: u32) {
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

// Returns a 2D orthographic projection matrix for the current window size with a top-left origin.
@private _get_ortho_matrix :: proc() -> Mat4 {
	return lin.matrix_ortho3d_f32(0, f32(s.width), f32(s.height), 0, -1, 1)
}

// Advances every keyboard key through the Up → Pressed → Down → Released state machine each frame.
@private _update_key_states :: proc() {
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

// Advances all connected gamepad button and axis states each frame.
// Tracks input_active_gamepad — the last gamepad with input above the axis threshold.
@private _update_gamepad_states :: proc() {
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

// Returns true if the button's current state matches any value in any_expected.
// device=-1 uses the active gamepad (last one with input).
@private _gamepad_check_game_state :: #force_inline proc(button: GamepadButton, any_expected: []InputState, device := -1) -> bool {
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

// Returns the raw InputState of a button on the given gamepad. device=-1 uses the active gamepad.
@private _gamepad_get_game_state :: #force_inline proc(button: GamepadButton, device := -1) -> InputState {
	assert(device >= -1 && device < MAX_GAMEPADS)
	device := clamp(device, -1, MAX_GAMEPADS)

	if device == -1 {
		return s.input_gamepad_button_states[s.input_active_gamepad][button]
	} else {
		return s.input_gamepad_button_states[device][button]
	}
}

// Casts the opaque Sound handle to a typed miniaudio ma.sound pointer.
@private _ma_sound :: #force_inline proc(sound: Sound) -> ^ma.sound {
	return cast(^ma.sound)sound.handle
}

// Casts the opaque AudioBus handle to a typed miniaudio ma.sound_group pointer.
@private _ma_group :: #force_inline proc(bus: AudioBus) -> ^ma.sound_group {
	return cast(^ma.sound_group)bus.handle
}

///////////////////////////////////////////////////////////////////////////////////////////////////