# Super-Mario-Game
Super Mario Game COAL Project
## Module 5: Frame Buffer and Block Operations
In this module, I worked on the framebuffer system for the game. The main purpose of this module is to draw everything in a separate memory area first and then display the completed frame on the screen. This helps reduce screen flickering while objects are being drawn.

### What I implemented

**1. Framebuffer Memory Allocation**
I allocated a separate 64 KB memory segment to use as an off-screen framebuffer. Instead of drawing directly on the screen, I use this memory area to prepare each frame.
The program first reduces its own memory block using DOS interrupt `21h`, function `4Ah`. It then allocates `1000h` paragraphs (64 KB) using DOS interrupt `21h`, function `48h`. The returned segment address is stored in `buffer_segment` and used as the off-screen framebuffer. VGA memory is located at segment `A000h`.

**2. Clearing the Framebuffer**
Before drawing a new frame, I clear the previous frame using the `REP STOSW` instruction. This clears the buffer so that old drawings do not remain visible in the next frame.

**3. Drawing Objects in the Buffer**
I created a test rectangle and draw it inside the framebuffer instead of drawing it directly on the screen. This helped me check whether drawing in the separate memory area was working correctly.

**4. Copying the Frame to VGA Memory**
After drawing is completed, I use `REP MOVSW` to copy the contents of the framebuffer to VGA memory at segment `A000h`. This displays the completed frame on the screen.

**5. Testing Frame Updates**
To test the framebuffer, I made the rectangle move horizontally across the screen. The buffer is cleared, the rectangle is drawn at its new position, and the completed frame is copied to the screen during each update.

### Testing Result

I tested the program in DOSBox. The rectangle moved horizontally across the screen, and I did not notice any visible flickering during the movement.
This test helped me understand how an off-screen framebuffer works and how `REP STOSW` and `REP MOVSW` are used for frame operations.