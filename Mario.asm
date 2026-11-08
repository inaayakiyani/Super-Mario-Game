org 100h
jmp start

;Display Constants

SCREEN_WIDTH equ 320
SCREEN_HEIGHT equ 200
TILE_SIZE equ 16
MARIO_WIDTH equ 16
MARIO_HEIGHT equ 32
VISIBLE_COLUMNS equ 20
VISIBLE_ROWS equ 12
TRANSPARENT_COLOR equ 0

;Keyboard Scan Codes

KEY_LEFT equ 4Bh
KEY_RIGHT equ 4Dh
KEY_UP equ 48h
KEY_DOWN equ 50h
KEY_SPACE equ 39h
KEY_SHIFT equ 2Ah
KEY_PAUSE equ 19h
KEY_ENTER equ 1Ch
KEY_ESC equ 01h

;Game Limits

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

; Keyboard Variables

key_pressed db 0
key_scan_code db 0

start:

    mov ax, 0003h
    int 10h

    mov ax, 4C00h
    int 21h