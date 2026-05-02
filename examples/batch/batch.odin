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

    vl.create_window(800, 600, "Batch renderer")
    defer vl.shutdown()

    vl.set_vsync(true)
    vl.hide_cursor()

    pos: vl.Vec2 

    mouse_texture := vl.load_texture("assets/mouse_hand.png")

    for !vl.should_close() {
        vl.poll_events()
        if vl.key_is_pressed(.Escape) do vl.close_window()

        pos := vl.mouse_position()

        vl.render_begin()
        {
            vl.clear_color(vl.VALKYRIE_BLUE)
            // row 1: filled shapes
            vl.draw_rectangle({110, 140, 80, 80}, vl.RED)
            vl.draw_circle({400, 180}, 40, vl.GREEN)
            vl.draw_rectangle_rounded({610, 140, 80, 80}, vl.BLUE, 0.4)
            // row 2: line shapes
            vl.draw_rectangle_lines({110, 380, 80, 80}, vl.YELLOW, 4)
            vl.draw_circle_lines({400, 420}, 40, vl.CYAN, 4)
            vl.draw_rectangle_lines_rounded({610, 380, 80, 80}, vl.VIOLET, 0.4, 4)
            vl.draw_texture_pos(mouse_texture, pos)
        }
        vl.render_end()

        free_all(context.temp_allocator)
    }
}