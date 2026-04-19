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

import "core:fmt"
import "core:log"
import "core:os"
import "core:strings"

import gl "vendor:OpenGL"
import sdl "vendor:sdl3"

Window :: struct {
	width:   int,
	height:  int,
	title:   string,
	handle:  rawptr,
	gl_ctx:  rawptr,
	running: bool,
}

Shader :: struct {
	id: u32,
}

Texture :: struct {
	id:     u32,
	width:  int,
	height: int,
}

Vec2 :: [2]f64
Vec3 :: [3]f64
Vec4 :: [4]f64
Rect :: [4]f64
Color :: Vec4

create_window :: proc(width, height: int, title: string) -> Window {
	assert(sdl.Init({.VIDEO}))
	window := sdl.CreateWindow(fmt.ctprint(title), i32(width), i32(height), {.OPENGL})
	gl_ctx := sdl.GL_CreateContext(window)
	sdl.GL_MakeCurrent(window, gl_ctx)
	gl.load_up_to(3, 3, sdl.gl_set_proc_address)

	return {width, height, title, rawptr(window), rawptr(gl_ctx), true}
}

poll_events :: proc(window: ^Window) {
	event: sdl.Event
	for sdl.PollEvent(&event) {
		#partial switch event.type {
		case .QUIT:
			close_window(window)
		case .KEY_DOWN:
			#partial switch event.key.scancode {
			case .ESCAPE:
				close_window(window)
			}
		}
	}
}

should_close :: proc(window: Window) -> bool {
	return !window.running
}

close_window :: proc(window: ^Window) {
	window.running = false
}

render_begin :: proc(window: Window) {
	gl.Viewport(0, 0, i32(window.width), i32(window.height))
	gl.Clear(gl.COLOR_BUFFER_BIT)
}

clear_color :: proc(color: [4]f32) {
	gl.ClearColor(color.r, color.g, color.b, color.a)
}

render_end :: proc(window: Window) {
	sdl.GL_SwapWindow(cast(^sdl.Window)(window.handle))
}

shutdown :: proc(window: Window) {

	sdl.DestroyWindow(cast(^sdl.Window)window.handle)
	gl_ctx := cast(^sdl.GLContext)(window.gl_ctx)
	sdl.GL_DestroyContext(gl_ctx^)
	sdl.Quit()
}

load_shader :: proc(vertex_path, fragment_path: string) -> (Shader, bool) {
	vertex_shader, vertex_err := os.read_entire_file(vertex_path, context.temp_allocator)
	fragment_shader, fragment_err := os.read_entire_file(fragment_path, context.temp_allocator)

	if vertex_err != os.General_Error.None {
		log.error("vertex shader file loading failed:", vertex_err, "path:", vertex_path)
		return {}, false
	}
	if fragment_err != os.General_Error.None {
		log.error("fragment shader file loading failed:", fragment_err, "path:", fragment_path)
		return {}, false
	}

	vertex_src := strings.clone_from_bytes(vertex_shader, context.temp_allocator)
	fragment_src := strings.clone_from_bytes(fragment_shader, context.temp_allocator)

	// TODO: Improve shader error output

	id, ok := gl.load_shaders_source(vertex_src, fragment_src, false)

	if !ok {
		log.error("shader file error")
	}
	return Shader{id = id}, ok
}

shader_use :: proc(s: Shader) {
	gl.UseProgram(s.id)
}

setup_triangle :: proc() {
	
}


draw_texture :: proc(
	texture: Texture,
	position: Vec2 = {0, 0},
	region: Maybe(Rect) = nil,
	dest: Maybe(Rect) = nil,
	origin: Vec2 = {0, 0},
    scale: Vec2 = {1,1},
	rotation: f64 = 0,
	tint: Color = {0, 0, 0, 1},
) {
    
}
