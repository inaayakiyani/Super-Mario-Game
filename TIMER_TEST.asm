org 100h

start:
    ; -------------------------------------------------------------
    ; 1. Save original INT 1Ch handler
    ; -------------------------------------------------------------
    mov ah, 35h
    mov al, 1Ch
    int 21h
    mov [old_int1c], bx
    mov [old_int1c+2], es

    ; -------------------------------------------------------------
    ; 2. Install our test INT 1Ch handler
    ; -------------------------------------------------------------
    mov dx, TimerHandler
    mov ax, 251Ch
    int 21h

    ; -------------------------------------------------------------
    ; 3. Print test start banner
    ; -------------------------------------------------------------
    mov dx, msg_start
    mov ah, 09h
    int 21h

    ; Get baseline tick
    mov ax, [game_ticks]
    mov [last_tick], ax

; -------------------------------------------------------------
; Main test loop
; Runs until total_ticks_counted reaches 1092 (~60 seconds)
; -------------------------------------------------------------
test_loop:

wait_tick:
    hlt                     ; Wait for the next hardware interrupt (avoids 100% spin)

    mov ax, [game_ticks]
    mov bx, ax

    sub ax, [last_tick]     ; ax = ticks elapsed since last check
    cmp ax, 0
    je wait_tick

    mov [last_tick], bx     ; Update last tick snapshot
    mov cx, ax              ; cx = number of elapsed ticks to process

update_clock:
    ; Increment our diagnostic counter of total processed ticks
    inc word [total_ticks_counted]

    ; Accumulate fractional time (exact algorithm from MARIO.asm)
    add word [clock_fraction], 10

    cmp word [clock_fraction], 182
    jb next_tick

    sub word [clock_fraction], 182

    cmp word [game_time], 0
    je next_tick

    dec word [game_time]

next_tick:
    ; Stop processing if we have reached exactly 1092 ticks
    cmp word [total_ticks_counted], 1092
    jae test_finished

    loop update_clock

    jmp test_loop

test_finished:

    ; -------------------------------------------------------------
    ; 4. Restore original INT 1Ch handler immediately
    ; -------------------------------------------------------------
    push ds
    mov dx, [old_int1c]
    mov ax, [old_int1c+2]
    mov ds, ax
    mov ax, 251Ch
    int 21h
    pop ds

    ; -------------------------------------------------------------
    ; 5. Print results to screen
    ; -------------------------------------------------------------
    mov dx, msg_result
    mov ah, 09h
    int 21h

    ; Print game_time as decimal
    mov ax, [game_time]
    call PrintDec16

    mov dx, msg_expected
    mov ah, 09h
    int 21h

    mov dx, msg_ticks
    mov ah, 09h
    int 21h

    mov ax, [total_ticks_counted]
    call PrintDec16

    mov dx, msg_crlf
    mov ah, 09h
    int 21h

    ; Exit cleanly to DOS
    mov ax, 4C00h
    int 21h


; =============================================================
; TimerHandler
; Increments game_ticks and jumps to the previous INT 1Ch handler.
; =============================================================
TimerHandler:
    pushf
    push ax
    inc word [cs:game_ticks]
    pop ax
    popf
    jmp far [cs:old_int1c]


; =============================================================
; PrintDec16
; Prints an unsigned 16-bit integer in AX in decimal to stdout.
; =============================================================
PrintDec16:
    push ax
    push bx
    push cx
    push dx

    xor cx, cx          ; Digit counter = 0
    mov bx, 10

.divide_loop:
    xor dx, dx
    div bx              ; AX = quotient, DX = remainder
    push dx             ; Save remainder (digit)
    inc cx
    cmp ax, 0
    jnz .divide_loop

.print_loop:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop .print_loop

    pop dx
    pop cx
    pop bx
    pop ax
    ret


; =============================================================
; Data Section
; =============================================================
LEVEL_TIME          equ 300

game_time           dw LEVEL_TIME
game_ticks          dw 0
last_tick           dw 0
clock_fraction      dw 0
total_ticks_counted dw 0

old_int1c:
    dw 0, 0

msg_start    db 'Starting Timer Test (waiting 1092 ticks / ~60 seconds)...', 0Dh, 0Ah, '$'
msg_result   db 0Dh, 0Ah, 'Final game_time : $'
msg_expected db ' (Expected: 240)', 0Dh, 0Ah, '$'
msg_ticks    db 'Total ticks     : $'
msg_crlf     db 0Dh, 0Ah, '$'
