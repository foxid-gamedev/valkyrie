# Valkyrie

Valkyrie is a lightweight game development library written in Odin, currently centered around 2D rendering and core game framework features.  
It is being developed as a reusable foundation for future game projects and is open source under the MIT License.

Valkyrie primarily developed for learning new stuff and also future game projects, so some features are added specifically to support those needs. At least thats the main reason why I'm building this.

## Warning

> This project is currently in active development.  
> Expect changes, breaking APIs, and incomplete features.  


## Usage

To use Valkyrie, copy the `valkyrie` folder into your codebase, import it, and run your game project with:

```bash
odin run . -debug
```

## Example

```odin
package main

import "core:log"
import vl "valkyrie"

main :: proc() {
	context.logger = log.create_console_logger()

	vl.create_window(800, 600, "My Window")
	defer vl.shutdown()

	vl.set_vsync(true)

	x: f32 = 0
	dir: f32 = 1
	mouse_texture := vl.load_texture("assets/mouse_hand.png")

	for !vl.should_close() {
		vl.poll_events()
		if vl.key_is_pressed(.Escape) do vl.close_window()

		x += dir * 400 * vl.delta_time()
		if x >= f32(vl.window_width() - 100) {
			dir = -1
		} else if x < 0 {
			dir = 1
		}

		vl.render_begin()
		{
			vl.clear_color(vl.VALKYRIE_BLUE)
			vl.draw_rectangle({700 - x, 300, 100, 100}, {1.0, 0.66, 0.2, 1.0})
			vl.draw_texture_pos(mouse_texture, {x, 100})
		}
		vl.render_end()

		free_all(context.temp_allocator)
	}
}
```

## Roadmap

### First version (OpenGL)

- [x] Create a window
- [x] Load shaders
- [x] Batch rendering for colored rectangles
- [x] Load textures (`stb_image`)
- [x] Draw 2D textures
- [x] Load and render fonts (`stb_truetype`)
- [x] Batch rendering for textures and even fonts
- [x] Simple 2D camera
- [x] Keyboard input
- [ ] Audio support (`.wav`, `.mp3`)
- [ ] Font/UI text alignment
- [ ] Font/UI word wrapping
- [ ] Create a simple example game

---

## Dependencies

Valkyrie currently depends on libraries from Odin's vendor collection:

- GLFW
- OpenGL 3.3 Core
- `stb_image`
- `stb_truetype`

## Troubleshooting

### Valkyrie does not compile or link

Because Valkyrie uses dependencies from the vendor libraries, you may need to install the required system dependencies on your machine.

In many cases, it is enough to install Odin correctly and make sure its path is available in your environment variables.

### Valkyrie does not run as expected

Run the project in debug mode and check whether any assets or shaders are missing.