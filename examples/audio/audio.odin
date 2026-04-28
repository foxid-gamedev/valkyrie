package main

import vl "../../valkyrie"

import ma "vendor:miniaudio"
import "core:fmt"

main :: proc() {
   vl.create_window(800, 600, "Test Audio")
   vl.set_vsync(false)

   result: ma.result
   engine: ma.engine
   resource_manager_config := ma.resource_manager_config_init()
   resource_manager: ma.resource_manager

   result = ma.resource_manager_init(&resource_manager_config, &resource_manager)
   if result != .SUCCESS {
      fmt.println("error: ma_resource_maanager result:", result)
   }

   engine_config := ma.engine_config_init()
   engine_config.pResourceManager = &resource_manager
   result = ma.engine_init(&engine_config, &engine)

   if result != .SUCCESS {
      fmt.println("error: ma_engine result:", result)
   }

   piano_music: ma.sound

   result = ma.sound_init_from_file(&engine, "assets/piano.wav", {}, nil, nil, &piano_music)
   if result != .SUCCESS {
      fmt.println("error: piano_music loading result:", result)
   }

   ma.sound_start(&piano_music)
   defer ma.sound_uninit(&piano_music)

   for !vl.should_close() {
      vl.poll_events()
      if vl.key_is_pressed(.Escape) do vl.close_window()

      vl.clear_color(vl.VALKYRIE_BLUE)
      vl.render_begin()

      vl.draw_fps({0,0}, 32, vl.GREEN)

      vl.render_end()
   }
}