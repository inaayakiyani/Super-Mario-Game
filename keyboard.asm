; ==========================================
; Module: keyboard.asm
; ==========================================
old_off dw 0
old_seg dw 0

key_state times 128 db 0


; ==========================================
; Procedure: InstallKeyboard
; Purpose: Save old INT 09h and install our handler.
; Inputs: None
; Outputs: Keyboard interrupt installed.
; Registers: Preserved
; ==========================================

InstallKeyboard:

    push ax
    push bx
    push dx
    push ds
    push es

    ; Get old keyboard interrupt
    mov ax, 3509h
    int 21h

    ; Save old interrupt address
    push cs
    pop ds

    mov [old_off], bx
    mov [old_seg], es

    ; Install our keyboard handler
    mov dx, KeyboardHandler
    mov ax, 2509h
    int 21h

    pop es
    pop ds
    pop dx
    pop bx
    pop ax

    ret


; ==========================================
; Procedure: RestoreKeyboard
; Purpose: Restore original INT 09h.
; Inputs: None
; Outputs: Original keyboard interrupt restored.
; Registers: Preserved
; ==========================================

RestoreKeyboard:

    push ax
    push dx
    push ds

    ; Access saved interrupt address
    push cs
    pop ds

    mov dx, [old_off]
    mov ax, [old_seg]

    ; Restore old interrupt
    mov ds, ax
    mov ax, 2509h
    int 21h

    pop ds
    pop dx
    pop ax

    ret


; ==========================================
; Procedure: KeyboardHandler
; Purpose: Read scan codes and update key states.
; Inputs: Keyboard interrupt
; Outputs: Updates key_state table.
; Registers: AX, BX, DS preserved.
; ==========================================

KeyboardHandler:

    push ax
    push bx
    push ds

    push cs
    pop ds

    ; Read scan code
    in al, 60h

    ; Ignore E0 prefix
    cmp al, 0E0h
    je .send_eoi

    ; Get scan code index
    mov bl, al
    and bl, 7Fh

    xor bh, bh

    ; Check key release
    test al, 80h
    jnz .released

    ; Key pressed
    mov byte [key_state+bx], 1
    jmp .send_eoi

.released:

    ; Key released
    mov byte [key_state+bx], 0

.send_eoi:

    ; Send End Of Interrupt
    mov al, 20h
    out 20h, al

    pop ds
    pop bx
    pop ax

    iret