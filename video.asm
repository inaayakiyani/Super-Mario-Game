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

    RECT 0, 0, 320, 192, COLOR_SKY
    RECT 0, 0, 320, 16, COLOR_HUD
    RECT 0, 192, 320, 8, COLOR_BLACK

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

    xor bx, bx
    mov dx, 10
.palette_loop:
    push dx
    push word 100
    push word 18
    push word 20
    push bx
    call FillRect
    add dx, 19
    inc bx
    cmp bx, 16
    jb .palette_loop

    mov cx, 100
    mov dx, 110
.line_loop:
    push dx
    push word 140
    push word COLOR_TEXT
    call PutPixel
    inc dx
    loop .line_loop

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