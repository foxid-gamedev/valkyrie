/******************************************************************************/
/* batch.odin                                                                 */
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
import vl "../../valkyrie"

main :: proc() {
    context.logger = log.create_console_logger()

    vl.create_window(800, 600, "My Window")
    defer vl.shutdown()

    vl.set_vsync(true)

    pos: vl.Vec2 
    dir: f32 = 1

    mouse_texture := vl.load_texture("assets/mouse_hand.png")

    for !vl.should_close() {
        vl.poll_events()
        if vl.key_is_pressed(.Escape) do vl.close_window()

        vl.render_begin()
        {
            vl.clear_color(vl.VALKYRIE_BLUE)
            vl.draw_rectangle({200, 40, 100, 100}, {1.0, 0.66, 0.2, 1.0})
            vl.draw_texture_pos(mouse_texture, pos)
        }
        vl.render_end()

        free_all(context.temp_allocator)
    }
}