/******************************************************************************/
/* fonts.odin                                                                 */
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

import vl "../../valkyrie"

main :: proc() {
   vl.create_window(800, 600, "Window Example")
defer vl.shutdown()
   vl.set_vsync(true)

   for !vl.should_close() {
      vl.poll_events()
      vl.render_begin()
      vl.clear_color(vl.VALKYRIE_BLUE)

      // draw lines
      vl.draw_rectangle({0,300-1,800, 2}, vl.GREEN)
      vl.draw_rectangle({400-1, 0, 2, 600}, vl.GREEN)

      // left side: top, center, bottom
      vl.draw_text("Left-Top\nLeft-Top 2", {0, 0}, 32, vl.WHITE, .Left, .Top)
      vl.draw_text("Left-Center\nLeft-Center 2", {0, 300}, 32, vl.WHITE, .Left, .Center)
      vl.draw_text("Left-Bottom\nLeft-Bottom, 2", {0, 600}, 32, vl.WHITE, .Left, .Bottom)

      // center: top, center, bottom
      vl.draw_text("Center-Top\nCenter-Top 2", {400, 0}, 32, vl.WHITE, .Center, .Top)
      vl.draw_text("Center-Center\nCenter-Center 2\nCenter-Center 3", {400, 300}, 32, vl.WHITE, .Center, .Center)
      vl.draw_text("Center-Bottom\nCenter-Bottom, 2", {400, 600}, 32, vl.WHITE, .Center, .Bottom)

      // right side: top, center, bottom
      vl.draw_text("Right-Top\nRight-Top 2", {800, 0}, 32, vl.WHITE, .Right, .Top)
      vl.draw_text("Right-Center\nRight-Center 2", {800, 300}, 32, vl.WHITE, .Right, .Center)
      vl.draw_text("Right-Bottom\nRight-Bottom, 2", {800, 600}, 32, vl.WHITE, .Right, .Bottom)

      text_rect := vl.Rect{ 64, 64, 400-128, 300-128}
      text := "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua."

      vl.draw_rectangle_lines(text_rect, vl.GRAY, 1)
      vl.draw_text_wrapped(text, text_rect, 32)

      vl.render_end()
      free_all(context.temp_allocator)
   }
}