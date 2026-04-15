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

import sdl "vendor:sdl3"
import gl "vendor:OpenGL"


create_window :: proc(width, height: int, title: string) {
    assert(sdl.Init({.VIDEO}))
    window := sdl.CreateWindow(fmt.ctprint(title), i32(width), i32(height), {.OPENGL})
    gtxt := sdl.GL_CreateContext(window)

    gl.load_up_to(3, 3, sdl.gl_set_proc_address)
    running := true

    for running {
        event: sdl.Event
        for sdl.PollEvent(&event) {
            #partial switch event.type {
            case .QUIT:
                running = false
            case .KEY_DOWN:
                #partial switch event.key.scancode {
                case .ESCAPE:
                    running = false
                }
            }
        }

        gl.Viewport(0,0, i32(width), i32(height))
        gl.ClearColor(0.2, 0.2, 0.8, 1.0)
        gl.Clear(gl.COLOR_BUFFER_BIT)

        sdl.GL_SwapWindow(window)

        free_all(context.temp_allocator)
    }
}