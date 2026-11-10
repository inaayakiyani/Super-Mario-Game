org 100h
jmp start

; ---------- Constants ----------

SCREEN_WIDTH        equ 320
SCREEN_HEIGHT       equ 200
TILE_SIZE           equ 16
MARIO_WIDTH         equ 16
MARIO_HEIGHT        equ 32
VISIBLE_COLUMNS     equ 20
VISIBLE_ROWS        equ 12
TRANSPARENT_COLOR   equ 0
VIDEO_SEGMENT       equ 0A000h

KEY_LEFT            equ 4Bh
KEY_RIGHT           equ 4Dh
KEY_UP              equ 48h
KEY_DOWN            equ 50h
KEY_SPACE           equ 39h
KEY_SHIFT           equ 2Ah
KEY_PAUSE           equ 19h
KEY_ENTER           equ 1Ch
KEY_ESC             equ 01h

START_LIVES         equ 3
MAX_LIVES           equ 99
SMALL_HP            equ 1
SUPER_HP            equ 2
LEVEL_TIME          equ 300
MAX_SCORE           equ 999999
MAX_ENEMIES         equ 8

; Default VGA palette indices
COLOR_BLACK         equ 0
COLOR_BLUE          equ 1
COLOR_GREEN         equ 2
COLOR_CYAN          equ 3
COLOR_RED           equ 4
COLOR_MAGENTA       equ 5
COLOR_BROWN         equ 6
COLOR_LIGHT_GRAY    equ 7
COLOR_DARK_GRAY     equ 8
COLOR_LIGHT_BLUE    equ 9
COLOR_LIGHT_GREEN   equ 10
COLOR_LIGHT_CYAN    equ 11
COLOR_LIGHT_RED     equ 12
COLOR_LIGHT_MAGENTA equ 13
COLOR_YELLOW        equ 14
COLOR_WHITE         equ 15

; Colour roles used by the game
COLOR_SKY           equ COLOR_LIGHT_BLUE
COLOR_GROUND        equ COLOR_GREEN
COLOR_BRICK         equ COLOR_RED
COLOR_PIPE          equ COLOR_LIGHT_GREEN
COLOR_HERO          equ COLOR_LIGHT_RED
COLOR_ENEMY         equ COLOR_BROWN
COLOR_TEXT          equ COLOR_WHITE
COLOR_HUD           equ COLOR_BLACK
COLOR_COIN          equ COLOR_YELLOW

; ---------- Variables ----------

hero_x              dw 32
hero_y              dw 144
hero_hp             db SMALL_HP
hero_lives          db START_LIVES

enemy_x             dw 0
enemy_y             dw 0
enemy_count         db 0

score               dd 0
coins               dw 0

game_time           dw LEVEL_TIME
game_ticks          dw 0

key_pressed         db 0
key_scan_code       db 0

; ---------- Module 2: Video Mode and Colours ----------

; Macro: RECT x, y, w, h, colour
; Pushes the five arguments left to right and calls FillRect.
%macro RECT 5
    push word %1
    push word %2
    push word %3
    push word %4
    push word %5
    call FillRect
%endmacro

SetVideoMode13:
    push ax
    mov ax, 0013h
    int 10h
    pop ax
    ret

SetTextMode:
    push ax
    mov ax, 0003h
    int 10h
    pop ax
    ret

PutPixel:
    push bp
    mov bp, sp
    push ax
    push bx
    push di
    push es

    mov bx, [bp+8]
    cmp bx, SCREEN_WIDTH
    jae .done
    mov ax, [bp+6]
    cmp ax, SCREEN_HEIGHT
    jae .done

    mov di, ax
    shl di, 8
    shl ax, 6
    add di, ax
    add di, bx

    mov ax, VIDEO_SEGMENT
    mov es, ax
    mov al, [bp+4]
    mov [es:di], al
.done:
    pop es
    pop di
    pop bx
    pop ax
    pop bp
    ret 6

FillRect:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov bx, [bp+12]
    mov dx, [bp+10]
    cmp bx, SCREEN_WIDTH
    jae .done
    cmp dx, SCREEN_HEIGHT
    jae .done

    mov cx, [bp+8]
    mov ax, SCREEN_WIDTH
    sub ax, bx
    cmp cx, ax
    jbe .width_ok
    mov cx, ax
.width_ok:
    mov si, [bp+6]
    mov ax, SCREEN_HEIGHT
    sub ax, dx
    cmp si, ax
    jbe .height_ok
    mov si, ax
.height_ok:
    test cx, cx
    jz .done
    test si, si
    jz .done

    mov di, dx
    shl di, 8
    mov ax, dx
    shl ax, 6
    add di, ax
    add di, bx

    mov ax, VIDEO_SEGMENT
    mov es, ax
    mov al, [bp+4]
    mov dx, cx
    cld
.row_loop:
    mov cx, dx
    push di
    rep stosb
    pop di
    add di, SCREEN_WIDTH
    dec si
    jnz .row_loop
.done:
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 10

DrawTestScreen:
    push ax
    push bx
    push cx
    push dx

    ; Background, HUD strip and black bottom strip
    RECT 0, 0, 320, 192, COLOR_SKY
    RECT 0, 0, 320, 16, COLOR_HUD
    RECT 0, 192, 320, 8, COLOR_BLACK

    ; One swatch per game colour (first one has a white frame)
    RECT  10, 30, 32, 32, COLOR_TEXT
    RECT  11, 31, 30, 30, COLOR_SKY
    RECT  48, 30, 32, 32, COLOR_GROUND
    RECT  86, 30, 32, 32, COLOR_BRICK
    RECT 124, 30, 32, 32, COLOR_PIPE
    RECT 162, 30, 32, 32, COLOR_HERO
    RECT 200, 30, 32, 32, COLOR_ENEMY
    RECT 238, 30, 32, 32, COLOR_COIN
    RECT 276, 30, 32, 32, COLOR_TEXT
    RECT 276, 70, 32, 4,  COLOR_HUD

    ; Full 16-colour palette row
    xor bx, bx
    mov dx, 10
.palette_loop:
    push dx
    push word 100
    push word 18
    push word 20
    push bx
    call FillRect
    add dx, 20
    inc bx
    cmp bx, 16
    jb .palette_loop

    ; PutPixel: horizontal line
    mov cx, 100
    mov dx, 110
.line_loop:
    push dx
    push word 140
    push word COLOR_TEXT
    call PutPixel
    inc dx
    loop .line_loop

    ; PutPixel: corners of the play area
    push word 0
    push word 17
    push word COLOR_TEXT
    call PutPixel
    push word 319
    push word 17
    push word COLOR_TEXT
    call PutPixel
    push word 0
    push word 191
    push word COLOR_TEXT
    call PutPixel
    push word 319
    push word 191
    push word COLOR_TEXT
    call PutPixel

    ; Clipping tests: nothing may wrap around or corrupt memory
    push word 400
    push word 150
    push word COLOR_RED
    call PutPixel
    push word 50
    push word 300
    push word COLOR_RED
    call PutPixel
    RECT 300, 150, 60, 30, COLOR_COIN
    RECT 20, 170, 30, 60, COLOR_BRICK

    pop dx
    pop cx
    pop bx
    pop ax
    ret

;Main program 
start:
    call SetVideoMode13
    call DrawTestScreen

    xor ax, ax
    int 16h

    call SetTextMode
    mov ax, 4C00h
    int 21h