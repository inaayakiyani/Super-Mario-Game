
; Module 5: Frame Buffer and Block Operations

; buffer_segment is declared in Mario.asm.


; Allocate 64 KB for frame buffer
; Input: None
; Output: buffer_segment and CF status

buffer_segment dw 0
last_tick dw 0

AllocFrameBuffer:

    push ax
    push bx

    mov bx, 1000h
    mov ah, 48h
    int 21h

    jc .failed

    mov [cs:buffer_segment], ax
    clc
    jmp .done

.failed:
    stc

.done:
    pop bx
    pop ax
    ret


; Clear the complete frame buffer
; Input: buffer_segment
; Output: Black frame
; Registers: Preserved

ClearFrame:

    pushf
    push ax
    push cx
    push di
    push es

    mov ax, [cs:buffer_segment]
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
    popf
    ret


; Copy frame buffer to VGA memory
; Input: buffer_segment
; Output: Frame displayed on screen
; Registers: Preserved

CopyFrame:

    pushf
    push ax
    push cx
    push si
    push di
    push ds
    push es

    mov ax, [cs:buffer_segment]
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
    popf
    ret
