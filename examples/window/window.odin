/******************************************************************************/
/* main.odin                                                                  */
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

    x : f32 = 0
    dir: f32 = 1
    mouse_texture := vl.load_texture("assets/mouse_hand.png")

    for !vl.should_close() {
        vl.poll_events()

        x += dir * 400 * vl.delta_time()

        if x >= f32(vl.window_width() - 100) {
            dir = -1
        } else if x < 0 {
            dir = 1
        }

        vl.render_begin()
        {
            vl.clear_color(vl.VALKYRIE_BLUE)
            vl.draw_rectangle({x, 300, 100, 100}, {1.0, 0.66, 0.2, 1.0})
            vl.draw_texture_pos(mouse_texture, {x,100})

            vl.draw_fps({10, 10}, 64)
            vl.draw_text("HALLO WELT", {10, 70}, 32, {1,0,0,1})
        }
        vl.render_end()

        free_all(context.temp_allocator)
    }
}