## valkyrie (engine) is going to be an engine written in Odin.

## Warning! 
_This project is in development. Things will change a lot and may break._

## How to use Valkyrie:
Just copy the valkyrie folder into your code base, import it and in your game folder run:
 `odin run . -debug`

Example code:

```odin
package main

import "core:log"
import vl "valkyrie"

main :: proc() {
    context.logger = log.create_console_logger()

    vl.create_window(800, 600, "My Window")
    defer vl.shutdown()

    vl.set_vsync(true)

    x : f32 = 0
    dir: f32 = 1
    mouse_texture := vl.load_texture("assets/mouse_hand.png")

    for !vl.should_close() {
        vl.poll_events()
        if vl.key_escape_pressed(256) do vl.close_window()

        x += dir * 400 * vl.delta_time()
        if x >= f32(vl.window_width() - 100) {
            dir = -1
        } else if x < 0 {
            dir = 1
        }

        vl.render_begin()
        {
            vl.clear_color(vl.VALKYRIE_BLUE)
            vl.draw_rectangle({700-x, 300, 100, 100}, {1.0, 0.66, 0.2, 1.0})
            vl.draw_texture_pos(mouse_texture, {x,100})
        }
        vl.render_end()

        free_all(context.temp_allocator)
    }
}
```

## Current Roadmap:

### First simple version (OpenGL/SDL3)
- [x] Create a Window
- [x] Loading Shaders
- [x] Batch render supporting colored rectangles
- [x] Loading Textures (stb:image)
- [x] Drawing 2d Textures
- [x] Load/Render Fonts (stb:truetype)
- [x] Simple 2d Camera
- [ ] Provide Input (Keyboard)
- [ ] Make a simple game example


---

## Troubleshooting

Valkyrie currently use packages from the vendor library:

- GLFW
- OpenGL (3.3 Core)
- stb_image
- stb_truetype

### If Valkyrie doesn't compile or link correctly:
It is probably because of dependencies from the vendor library.
Usually they should just work if you have setup odin lang on your machine. 
Otherwise make sure to 
install those dependencies on your computer.

### If Valkyrie doesn't run as expected:
Make sure to run the project for instance in debug mode and see if it can't find any assets.
Usually it doesn't run like any game application if it can't load/find the shader source code.


