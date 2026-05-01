package main

import vl "../../valkyrie"
import "core:log"

main :: proc() {
   context.logger = log.create_console_logger()

   vl.create_window(800, 600, "Test Audio")
   defer vl.shutdown()
   vl.set_vsync(true)

   vl.audio_init()
   defer vl.audio_shutdown()

   piano_music, ok := vl.load_sound("assets/piano.wav")
   piano_pos := vl.Vec2{10, 10}
   defer vl.unload_sound(&piano_music)

   camera: vl.Camera = {
      position = {32, 32},
      offset = {400, 300},
      zoom = 1,
   }
   cam_spd: f32 = 100

   vl.audio_listener_set_position(camera.position)
   vl.play_sound_2d(piano_music, piano_pos)

   for !vl.should_close() {
      vl.poll_events()
      if vl.key_is_pressed(.Escape) do vl.close_window()

      dir := vl.input_vector(
         vl.key_is_down(.A),
         vl.key_is_down(.D),
         vl.key_is_down(.W),
         vl.key_is_down(.S),
      )

      camera.position += dir * cam_spd * vl.delta_time()
      vl.audio_listener_set_position(camera.position)

      vl.clear_color(vl.VALKYRIE_BLUE)
      vl.render_begin()
      vl.camera_begin(camera)
      vl.draw_rectangle({piano_pos.y-10, piano_pos.y-10, 20, 20}, vl.GREEN)
      vl.draw_rectangle({camera.position.x-20,camera.position.y-20,40,40}, vl.WHITE)
      vl.camera_end()

      vl.draw_fps({}, 32, vl.GRAY)
      vl.render_end()

      free_all(context.temp_allocator)
   }
}