
org 100h
jmp start

; Display Constants

SCREEN_WIDTH equ 320
SCREEN_HEIGHT equ 200
TILE_SIZE equ 16
MARIO_WIDTH equ 16
MARIO_HEIGHT equ 32
VISIBLE_COLUMNS equ 20
VISIBLE_ROWS equ 12
TRANSPARENT_COLOR equ 0

; Keyboard Scan Codes

KEY_LEFT equ 4Bh
KEY_RIGHT equ 4Dh
KEY_UP equ 48h
KEY_DOWN equ 50h
KEY_SPACE equ 39h
KEY_SHIFT equ 2Ah
KEY_PAUSE equ 19h
KEY_ENTER equ 1Ch
KEY_ESC equ 01h

; Game Limits

START_LIVES equ 3
MAX_LIVES equ 99
SMALL_HP equ 1
SUPER_HP equ 2
LEVEL_TIME equ 300
MAX_SCORE equ 999999
MAX_ENEMIES equ 8

; Colour Constants

COLOR_BLACK equ 0
COLOR_BLUE equ 1
COLOR_GREEN equ 2
COLOR_RED equ 4
COLOR_BROWN equ 6
COLOR_WHITE equ 15

; Hero Variables

hero_x dw 32
hero_y dw 144
hero_hp db SMALL_HP
hero_lives db START_LIVES

; Enemy Variables

enemy_x dw 0
enemy_y dw 0
enemy_count db 0

; Score Variables

score dd 0
coins dw 0

; Clock Variables

game_time dw LEVEL_TIME
game_ticks dw 0
clock_fraction dw 0

old_int1c:
    dw 0, 0

; Keyboard Variables

key_pressed db 0
key_scan_code db 0
buffer_segment dw 0

; Module 5 Variables

test_x dw 50
last_tick dw 0

; Timer Display Variables

digit_hundreds db 0
digit_tens db 0
digit_ones db 0

glyph_index db 0
glyph_x dw 0
glyph_y dw 0
glyph_pattern db 0

start:

    ; Set up our own stack

    cli
    mov ax, cs
    mov ss, ax
    mov sp, stack_top
    sti

    ; Resize program memory block

    mov bx, program_end
    add bx, 15
    shr bx, 1
    shr bx, 1
    shr bx, 1
    shr bx, 1

    mov ax, cs
    mov es, ax
    mov ah, 4Ah
    int 21h

    jnc resize_success
    jmp memory_error

resize_success:

    ; Allocate 64 KB for frame buffer

    mov bx, 1000h
    mov ah, 48h
    int 21h

    jnc buffer_allocated
    jmp memory_error

buffer_allocated:

    mov [buffer_segment], ax

    ; Save the original INT 1Ch handler

    mov ah, 35h
    mov al, 1Ch
    int 21h

    mov [old_int1c], bx
    mov [old_int1c+2], es

    ; Install our new INT 1Ch handler

    push cs
    pop ds

    mov dx, TimerHandler
    mov ax, 251Ch
    int 21h

    ; Switch to VGA graphics mode

    mov ax, 0013h
    int 10h

    ; Get initial game timer tick

    mov ax, [game_ticks]
    mov [last_tick], ax


; Main frame loop

moving_loop:

    ; Wait for the next timer tick

wait_tick:

    mov ax, [game_ticks]
    mov bx, ax

    ; Calculate how many ticks have passed

    sub ax, [last_tick]
    mov [last_tick], bx

    ; If no tick passed, keep waiting

    cmp ax, 0
    je wait_tick

    ; Process all elapsed ticks

    mov cx, ax

update_clock:

    add word [clock_fraction], 10

    cmp word [clock_fraction], 182
    jb next_tick

    sub word [clock_fraction], 182

    ; Prevent game time from going below zero

    cmp word [game_time], 0
    je next_tick

    dec word [game_time]

next_tick:

    loop update_clock

    ; Check if the timer has reached zero

    cmp word [game_time], 0
    je exit_game

    ; Check for ESC key

    mov ah, 01h
    int 16h

    jz no_key

    mov ah, 00h
    int 16h

    cmp ah, KEY_ESC
    je exit_game

no_key:

    ; Draw the next frame

    call ClearBuffer
    call DrawTestRectangle
    call DrawTimer
    call CopyBuffer

    ; Move rectangle to the right

    inc word [test_x]

    cmp word [test_x], 270
    jbe moving_loop

    ; Reset rectangle position

    mov word [test_x], 50

    jmp moving_loop


; Exit game

exit_game:

    ; Return to text mode

    mov ax, 0003h
    int 10h

    ; Restore the original INT 1Ch handler

    push ds

    mov dx, [old_int1c]
    mov ax, [old_int1c+2]
    mov ds, ax

    mov ax, 251Ch
    int 21h

    pop ds

    ; Display exit message

    mov dx, exit_message
    mov ah, 09h
    int 21h

    mov ax, 4C00h
    int 21h


memory_error:

    mov dx, allocation_failed
    mov ah, 09h
    int 21h

    mov ax, 4C01h
    int 21h


; ==========================================
; TimerHandler
; Counts every timer interrupt.
; ==========================================

TimerHandler:

    pushf
    push ax

    inc word [cs:game_ticks]

    pop ax
    popf

    jmp far [cs:old_int1c]


; ==========================================
; DrawTimer
; Converts game_time into three digits.
; Displays TIME and the remaining seconds.
; ==========================================

DrawTimer:

    push ax
    push bx
    push cx
    push dx

    ; Get hundreds digit

    mov ax, [game_time]
    xor dx, dx
    mov bx, 100
    div bx

    mov [digit_hundreds], al

    ; Get tens and ones digits

    mov ax, dx
    xor dx, dx
    mov bx, 10
    div bx

    mov [digit_tens], al
    mov [digit_ones], dl

    ; Draw TIME

    mov al, 10
    mov bx, 110
    mov dx, 10
    call DrawGlyph

    mov al, 11
    mov bx, 118
    mov dx, 10
    call DrawGlyph

    mov al, 12
    mov bx, 126
    mov dx, 10
    call DrawGlyph

    mov al, 13
    mov bx, 134
    mov dx, 10
    call DrawGlyph

    ; Draw hundreds digit

    mov al, [digit_hundreds]
    mov bx, 158
    mov dx, 10
    call DrawGlyph

    ; Draw tens digit

    mov al, [digit_tens]
    mov bx, 166
    mov dx, 10
    call DrawGlyph

    ; Draw ones digit

    mov al, [digit_ones]
    mov bx, 174
    mov dx, 10
    call DrawGlyph

    pop dx
    pop cx
    pop bx
    pop ax

    ret


; ==========================================
; DrawGlyph
; Draws one 5x7 bitmap character.
; AL = character index
; BX = X position
; DX = Y position
; ==========================================

DrawGlyph:

    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es

    mov [glyph_index], al
    mov [glyph_x], bx
    mov [glyph_y], dx

    ; Calculate font offset

    xor ax, ax
    mov al, [glyph_index]
    mov bl, 7
    mul bl

    mov si, ax

    ; Set framebuffer segment

    mov ax, [buffer_segment]
    mov es, ax

    ; Calculate starting pixel position
    ; Offset = Y * 320 + X

    mov ax, [glyph_y]
    mov bx, 320
    mul bx

    add ax, [glyph_x]
    mov di, ax

    ; Draw seven rows

    mov bp, 7

glyph_row:

    mov al, [glyph_font + si]
    mov [glyph_pattern], al

    mov bl, 10h
    mov cx, 5

glyph_column:

    test byte [glyph_pattern], bl
    jz skip_pixel

    mov byte [es:di], COLOR_WHITE

skip_pixel:

    inc di
    shr bl, 1

    loop glyph_column

    ; Move to the next row

    add di, 315
    inc si

    dec bp
    jnz glyph_row

    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    ret


; ==========================================
; CopyBuffer
; Copies the complete frame buffer to VGA memory.
; ==========================================

CopyBuffer:

    push ax
    push cx
    push si
    push di
    push ds
    push es

    mov ax, [buffer_segment]
    mov ds, ax

    mov ax, 0A000h
    mov es, ax

    xor si, si
    xor di, di
    mov cx, 32000

    cld
    rep movsw

    pop es
    pop ds
    pop di
    pop si
    pop cx
    pop ax

    ret


; ==========================================
; ClearBuffer
; Clears the complete frame buffer using REP STOSW.
; ==========================================

ClearBuffer:

    push ax
    push cx
    push di
    push es

    mov ax, [buffer_segment]
    mov es, ax

    xor di, di
    xor ax, ax
    mov cx, 32000

    cld
    rep stosw

    pop es
    pop di
    pop cx
    pop ax

    ret


; ==========================================
; DrawTestRectangle
; Draws a red rectangle into the frame buffer.
; ==========================================

DrawTestRectangle:

    push ax
    push cx
    push dx
    push di
    push es

    mov ax, [buffer_segment]
    mov es, ax

    cld

    ; Starting position: X=test_x, Y=50

    mov di, 16000
    add di, [test_x]

    ; Red colour

    mov al, COLOR_RED

    ; Draw 30 rows

    mov dx, 30

draw_row:

    mov cx, 40
    rep stosb

    add di, 280

    dec dx
    jnz draw_row

    pop es
    pop di
    pop dx
    pop cx
    pop ax

    ret


; ==========================================
; Bitmap Font
; First 10 characters: digits 0-9
; Next 4 characters: T, I, M, E
; ==========================================

glyph_font:

    ; 0
    db 11110b,10001b,10011b,10101b,11001b,10001b,01110b

    ; 1
    db 00100b,01100b,00100b,00100b,00100b,00100b,01110b

    ; 2
    db 01110b,10001b,00001b,00010b,00100b,01000b,11111b

    ; 3
    db 11110b,00001b,00001b,01110b,00001b,00001b,11110b

    ; 4
    db 00010b,00110b,01010b,10010b,11111b,00010b,00010b

    ; 5
    db 11111b,10000b,10000b,11110b,00001b,00001b,11110b

    ; 6
    db 01110b,10000b,10000b,11110b,10001b,10001b,01110b

    ; 7
    db 11111b,00001b,00010b,00100b,01000b,01000b,01000b

    ; 8
    db 01110b,10001b,10001b,01110b,10001b,10001b,01110b

    ; 9
    db 01110b,10001b,10001b,01111b,00001b,00001b,01110b

    ; T
    db 11111b,00100b,00100b,00100b,00100b,00100b,00100b

    ; I
    db 01110b,00100b,00100b,00100b,00100b,00100b,01110b

    ; M
    db 10001b,11011b,10101b,10101b,10001b,10001b,10001b

    ; E
    db 11111b,10000b,10000b,11110b,10000b,10000b,11111b


exit_message db 'Game timer test ended successfully!$'
allocation_failed db 'Memory allocation failed!$'

stack_space times 256 db 0
stack_top:
program_end:
