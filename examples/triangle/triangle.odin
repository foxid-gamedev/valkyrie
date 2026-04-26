/******************************************************************************/
/* triangle.odin                                                              */
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

package main

import "core:log"

import val "../../valkyrie"
import gl "vendor:OpenGL"

Vertex :: struct {
	position: val.Vec2,
	color:    val.Color,
}

main :: proc() {
	context.logger = log.create_console_logger()
	val.create_window(800, 600, "My Window")
	defer val.shutdown()

	shader, shader_ok := val.load_shader("shader/triangle.vs", "shader/triangle.fs")
	vao, vbo := generate_triangle()

	for !val.should_close() {
		val.poll_events()

		val.render_begin()
		val.clear_color(val.VALKYRIE_BLUE)
		val.shader_bind(shader)
		draw_triangle(vao)
      val.render_end()
		free_all(context.temp_allocator)
	}
}

generate_triangle :: proc() -> (vao, vbo: u32) {
	gl.GenVertexArrays(1, &vao)
	gl.GenBuffers(1, &vbo)

	gl.BindVertexArray(vao)
	gl.BindBuffer(gl.ARRAY_BUFFER, vbo)

	vertices := [3]Vertex {
		{{0.0, 0.5}, {1, 0, 0, 1}},
		{{0.5, -0.5}, {0, 1, 0, 1}},
		{{-0.5, -0.5}, {0, 0, 1, 1}},
	}

	gl.BufferData(gl.ARRAY_BUFFER, len(vertices) * size_of(Vertex), &vertices[0], gl.STATIC_DRAW)
   gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, position))
   gl.EnableVertexAttribArray(0)
   gl.VertexAttribPointer(1, 4, gl.FLOAT, gl.FALSE, size_of(Vertex), offset_of(Vertex, color))
   gl.EnableVertexAttribArray(1)
   gl.BindVertexArray(0)
   
	return vao, vbo
}

draw_triangle :: proc(vao: u32) {
   gl.BindVertexArray(vao)
   gl.DrawArrays(gl.TRIANGLES, 0, 3)
}