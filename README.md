# Super-Mario-Game

Super Mario Game COAL Project



\## Module files and procedures



video.asm: SetVideoMode13, SetTextMode, PutPixel, FillRect

tiles.asm: DrawTile, DrawMap, GetTile, ResetMap

sprites.asm: DrawSprite

framebuf.asm: AllocFrameBuffer, ClearFrame, CopyFrame

camera.asm: UpdateCamera, ResetCamera

keyboard.asm: InstallKeyboard, RestoreKeyboard, KeyboardHandler

timer.asm: InstallTimer, RestoreTimer, TimerHandler, WaitTick, UpdateClock

physics.asm: UpdateMario

collide.asm: MoveHorizontal, MoveVertical, RectOverlap, CheckStompOrHurt

enemies.asm: UpdateEnemies, DrawEnemies, ResetEnemies

blocks.asm: TriggerBlock, UpdateMushroom, CollectCoins

hud.asm: AddScore, NumberToDigits, DrawNumber, DrawHUD

states.asm: StateTitle, StatePlaying, StatePaused

game.asm: StateDying, StateLifeLost, StateWinSequence, StateLevelComplete, StateGameOver, ResetLevel, NewGame



\## Stack parameters (push order, left to right)



PutPixel(x, y, colour)

FillRect(x, y, w, h, colour)

DrawSprite(x, y, address, flags)

GetTile(px, py)



\## Rules



Each member edits only their own module file.

Do not rename a procedure or change its parameters without telling everyone.

