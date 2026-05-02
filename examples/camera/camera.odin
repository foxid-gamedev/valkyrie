/******************************************************************************/
/* camera.odin                                                                */
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

import "core:math"
import vl "../../valkyrie"

main :: proc() {
   vl.create_window(800, 600, "Camera")
   defer vl.shutdown()
   vl.set_vsync(true)

   camera: vl.Camera = {
      position = {0,0},
      offset = {400,300},
      zoom = 2,
      rotation = 0,
   }

   pos: vl.Vec2
   time: f32

   for !vl.should_close() {
      vl.poll_events()
      vl.render_begin()
         vl.clear_color(vl.VALKYRIE_BLUE)

         time += vl.delta_time()
         camera.position = pos
         camera.rotation += 3.14 * vl.delta_time()
         camera.zoom = 3 * (2 + math.sin(time)) 

         vl.camera_begin(camera)
            vl.draw_rectangle({pos.x - 16, pos.y - 16, 32, 32}, {1,0,0,1})
         vl.camera_end()

         vl.render_end()
      free_all(context.temp_allocator)
   }
}