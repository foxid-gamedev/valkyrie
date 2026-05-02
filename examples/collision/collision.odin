/******************************************************************************/
/* collision.odin                                                             */
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
/*                                                                            */
/* Layout (800 x 600)                                                         */
/*                                                                            */
/*   Row 1 — Animiert: Shapes berühren sich bei osc=0, Kollision = ORANGE    */
/*   Row 2 — Maus:     Mauszeiger als Punkt, Kollision = GRÜN                 */
/*                                                                            */
/******************************************************************************/

package main

import "core:log"
import "core:math"
import vl "../../valkyrie"


// ---- Main ------------------------------------------------------------------

main :: proc() {
	context.logger = log.create_console_logger()

	vl.create_window(800, 600, "Collision")
	defer vl.shutdown()
	vl.set_vsync(true)

	t: f32

	for !vl.should_close() {
		vl.poll_events()
		if vl.key_is_pressed(.Escape) do vl.close_window()

		t     += vl.delta_time()
		osc   := math.sin(t * 1.4) * f32(50)
		mouse := vl.mouse_position()

		vl.render_begin()
		vl.clear_color(vl.VALKYRIE_BLUE)

		draw_rect_vs_rect(osc)
		draw_circle_vs_circle(osc)
		draw_circle_vs_rect(osc)
		draw_point_in_rect(mouse)
		draw_point_in_circle(mouse)
		draw_ui(mouse)

		vl.render_end()
		free_all(context.temp_allocator)
	}
}

// ---- Row 1: Animierte Kollisionen ------------------------------------------
// osc = sin(t) * 50  →  Shapes berühren sich bei osc=0, 50 % Kollisionszeit

draw_rect_vs_rect :: proc(osc: f32) {
	ra  := vl.Rect{40, 120, 90, 70}
	rb  := vl.Rect{130 + osc, 120, 90, 70}  // bei osc=0 berühren sich ra und rb
	hit := vl.check_collision_rects(ra, rb)
	if hit {
		vl.draw_rectangle(ra, vl.fade_color(vl.ORANGE, 0.25))
		vl.draw_rectangle(rb, vl.fade_color(vl.ORANGE, 0.25))
	}
	vl.draw_rectangle_lines(ra, vl.ORANGE if hit else vl.WHITE,      3)
	vl.draw_rectangle_lines(rb, vl.ORANGE if hit else vl.LIGHT_BLUE, 3)
}

draw_circle_vs_circle :: proc(osc: f32) {
	ca, cb := vl.Vec2{360, 155}, vl.Vec2{440 + osc, 155}  // Abstand 80 = 2×r bei osc=0
	r      := f32(40)
	hit    := vl.check_collision_circles(ca, r, cb, r)
	if hit {
		vl.draw_circle(ca, r, vl.fade_color(vl.ORANGE, 0.25))
		vl.draw_circle(cb, r, vl.fade_color(vl.ORANGE, 0.25))
	}
	vl.draw_circle_lines(ca, r, vl.ORANGE if hit else vl.WHITE,   3)
	vl.draw_circle_lines(cb, r, vl.ORANGE if hit else vl.MAGENTA, 3)
}

draw_circle_vs_rect :: proc(osc: f32) {
	pos  := vl.Vec2{625 + osc, 155}      // bei osc=0: Distanz zum Rect = r
	r    := f32(35)
	rect := vl.Rect{660, 120, 90, 70}
	hit  := vl.check_collision_circle_rect(pos, r, rect)
	if hit {
		vl.draw_circle(pos, r, vl.fade_color(vl.ORANGE, 0.25))
		vl.draw_rectangle(rect, vl.fade_color(vl.ORANGE, 0.25))
	}
	vl.draw_circle_lines(pos, r,  vl.ORANGE if hit else vl.GREEN, 3)
	vl.draw_rectangle_lines(rect, vl.ORANGE if hit else vl.WHITE,  3)
}

// ---- Row 2: Maus-Kollisionen -----------------------------------------------

draw_point_in_rect :: proc(mouse: vl.Vec2) {
	rect := vl.Rect{130, 385, 180, 110}
	hit  := vl.check_collision_point_in_rect(mouse, rect)
	if hit do vl.draw_rectangle(rect, vl.fade_color(vl.GREEN, 0.25))
	vl.draw_rectangle_lines(rect, vl.GREEN if hit else vl.WHITE, 3)
}

draw_point_in_circle :: proc(mouse: vl.Vec2) {
	pos := vl.Vec2{580, 440}
	r   := f32(90)
	hit := vl.check_collision_point_in_circle(mouse, pos, r)
	if hit do vl.draw_circle(pos, r, vl.fade_color(vl.GREEN, 0.25))
	vl.draw_circle_lines(pos, r, vl.GREEN if hit else vl.WHITE, 3)
}

// ---- UI --------------------------------------------------------------------

draw_ui :: proc(mouse: vl.Vec2) {
	// Row 1: Spalten-Titel
	vl.draw_text("Rect vs. Rect",   {130, 45}, 32, vl.GRAY, .Center)
	vl.draw_text("Circle vs. Circle", {400, 45}, 32, vl.GRAY, .Center)
	vl.draw_text("Circle vs. Rect",  {665, 45}, 32, vl.GRAY, .Center)

	// Trennlinie
	vl.draw_rectangle({0, 268, 800, 1}, vl.fade_color(vl.DARK_GRAY, 0.6))

	// Row 2: Maus-Indikator + Spalten-Titel
	vl.draw_circle({10, 290}, 5, vl.YELLOW)
	vl.draw_text("Mouse:",          {22,  283}, 28, vl.YELLOW)
	vl.draw_text("Point vs. Rect", {220, 318}, 32, vl.GRAY, .Center)
	vl.draw_text("Point vs. Circle",{580, 318}, 32, vl.GRAY, .Center)

	// Mauszeiger
	vl.draw_circle(mouse, 2, vl.YELLOW)
}
