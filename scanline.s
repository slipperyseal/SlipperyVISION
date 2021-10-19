
    .section .text

; line       vsync markers are currently non-interlaced PAL. some devices may not like them.
; 1        A vsync long long
; 2          vsync long long
; 3        B vsync long short
; 4        C vsync short short
; 5          vsync short short
; 6-63       top (blank, uart processing)
; 64-256     scanline (text area)
; 257-309    bottom (blank, uart processing)
; 310      D vsync short short
; 311        vsync short short
; 312        vsync short short

.include "macros.s"

.macro zero
     cbi 0x5, 0  ; PB0 = 0
.endm

.macro black
     sbi 0x5, 0 ; PB0 = 1
.endm

.macro whiteclear
     cbi 0x8, 0 ; PC0 = 0 (when PB0 = 1)
.endm

.macro white
     sbi 0x8, 0 ; PC0 = 1 (when PB0 = 1)
.endm

.macro yfx1on
     cbi 0x8, 4 ; PC4
.endm

.macro yfx1off
     sbi 0x8, 4 ; PC4
.endm

.macro cbon
     sbi 0xb, 4 ; PD4
.endm

.macro cboff
     cbi 0xb, 4 ; PD4
.endm

.macro cron
     sbi 0xb, 6 ; PD6
.endm

.macro croff
     cbi 0xb, 6 ; PD6
.endm

.macro cbfxon
     sbi 0xa, 7 ; DDRD 7
.endm

.macro cbfxoff
     cbi 0xa, 7 ; DDRD 7
.endm

.macro crfxon
     sbi 0xa, 3 ; DDRD 3
.endm

.macro crfxoff
     cbi 0xa, 3 ; DDRD 3
.endm

.macro connect
     sbi 0xa, 3
.endm

.macro disconnect
     cbi 0xa, 3
.endm

.macro blip
    white
    nop
    whiteclear
.endm

    ; checks the line counter. if matching, set the new line function, else returns from subroutine
.macro checkLineFunction count, function
    increment r24 counter
    cpi r24,\count
    breq .branchToSet\function
    ret
.branchToSet\function:
    setFunctionPointer lineFunction \function
.endm

.macro checkUart            ; checks the UART buffer and adds any waiting byte to the circular buffer
    lds r24,192             ; UCSR0A & (1 << RXC0)) != 0
    sbrs r24,7
    rjmp 8f
    lds r24,uartWrite
    lds r25,198             ; UDR0
    mov r30,r24
    ldi r31,0
    addAddressToZ uartBuffer
    st Z,r25
    subi r24,lo8(-(1))      ; uartWrite++
    andi r24,127            ; overrun protect
    sts uartWrite,r24
8:
.endm

.macro processUart               ; checks for data in the circular buffer and processes the next byte if it exists
    lds r20, uartWrite           ; keep write index in r20
    lds r22, uartRead            ; keep read index in r22
    cp r20,r22
    breq 9f                      ; skip if equal - nothing to process

    mov r30,r22                  ; add read index to buffer pointer
    ldi r31,0
    addAddressToZ uartBuffer
    ld r19, Z                    ; get char from uartBuffer

    inc r22
    andi r22, 127
    sts uartRead, r22            ; inc and store uartRead;

    rcall processChar            ; call rather than inline this code
9:
.endm

.macro doSync  ; 4.7 microseconds = (4*16) + 11.2 cycles
    zero
    delay4us
    nop
    nop
    nop
    nop ; 4
    nop
    nop
    nop
    nop ; 8
    nop ; 9
    black 
.endm

    ; if this macro is edited, timing nops will need to calibrated in renderScanline
.macro  mapFontSetup         ; decode the char buffer againt to the font data to fill the scanline buffer
    lds r25, counter         ; find the start row of char buffer
    subi r25, 64             ; subtract the start line of 64
    andi r25, 248            ; mask out the lower 3 bits (scanline > row number)

    lds r24, rowoffset       ; row position in circular buffer
    lsl r24
    lsl r24
    lsl r24
    add r25,r24

    clr r24                  ; multiply up to 32 width char buffer
    lsl r25
    rol r24
    lsl r25
    rol r24
    addressToX charbuffer
    addToX r25, r24

    ld r20,X+                ; get reversed font bits
    ld r21,X+
    ld r22,X+
    ld r23,X+                ; reserved - colour attributes?

    addressToY scanlinebuffer

    ldi r31, hi8(gs(fontdata))  ; upper Z - fontdata must be 512 byte aligned
    lsl r31                     ; account for program space being 16 bit aligned
    lds r25, counter
    andi r25, 7                 ; get font row number
    add r31, r25                ; add to page number
.endm

.macro  mapFont reg, bit
    ld r30, X+              ; load character into lower register of Z
    lpm r25, Z              ; load bitmap for scanline
    sbrc \reg,\bit          ; check the invert bit
    com r25                 ; invert the font bitmap if not skipped
    st Y+, r25              ; store in scanlinebuffer
.endm

.macro renderByte
    ld r25,X+
    out 0x8,r25 ; 0
    lsr r25
    nop
    out 0x8,r25 ; 1
    lsr r25
    nop
    out 0x8,r25 ; 2
    lsr r25
    nop
    out 0x8,r25 ; 3
    lsr r25
    nop
    out 0x8,r25 ; 4
    lsr r25
    nop
    out 0x8,r25 ; 5
    lsr r25
    nop
    out 0x8,r25 ; 6
    lsr r25
    nop
    out 0x8,r25 ; 7
.endm

processChar:                ; expect char in r19
    sts lastChar, r19
    lds r18, cursorx

    cpi r19, 10             ; Carriage Return
    brne notCr
    clr r18                 ; set cursorX to zero
    sts cursorx, r18
    ret
notCr:

    cpi r19, 13             ; Line Feed
    brne notLf
    increment r17 cursory
    incrementAndMask r17 31 rowoffset   ; rotate the view to keep up
    rcall clearLine
    ret
notLf:

    cpi r18, 24             ; check for line wrap
    brne notWrap
    clr r18
    increment r17 cursory
    incrementAndMask r17 31 rowoffset   ; rotate the view to keep up
    rcall clearLine
notWrap:

    lds r25, cursory         ; row position in circular buffer
    lsl r25                  ; start the multiply in 8 bit land
    lsl r25
    lsl r25
    clr r24                  ; multiply up to 32 width char buffer
    lsl r25
    rol r24
    lsl r25
    rol r24
    addressToX charbuffer+4 ; charbuffer + skip reverse bits
    addToX r25, r24         ; add cursor y offset to X
    addToX r18, r16         ; add column x to X
    st X, r19

    inc r18                  ; increment and store cursor x
    sts cursorx, r18
    ret

clearLine:                   ; clears row at cursor y including reverse bits
    lds r25, cursory         ; row position in circular buffer
    lsl r25                  ; start the multiply in 8 bit land
    lsl r25
    lsl r25
    clr r24                  ; multiply up to 32 width char buffer
    lsl r25
    rol r24
    lsl r25
    rol r24
    addressToX charbuffer
    addToX r25, r24          ; add cursor y offset to X
    st X+, r16               ; clear reverse bits
    st X+, r16
    st X+, r16
    st X+, r16
    st X+, r16 ; 0
    st X+, r16
    st X+, r16
    st X+, r16 ; 4
    st X+, r16
    st X+, r16
    st X+, r16
    st X+, r16 ; 8
    st X+, r16
    st X+, r16
    st X+, r16
    st X+, r16 ; 12
    st X+, r16
    st X+, r16
    st X+, r16
    st X+, r16 ; 16
    st X+, r16
    st X+, r16
    st X+, r16
    st X+, r16 ; 20
    st X+, r16
    st X+, r16
    st X+, r16
    st X+, r16 ; 24
    ret

renderScanline:
    zero          ; do sync but with some code hiding in there
    delay1us      ; tuned number nops + mapFontSetup = 4.7 microseconds
    delay1us
    nop
    nop
    nop
    nop ; 4
    nop
    nop ; 6 - my scope told me to stop here
    mapFontSetup
    black
    
    mapFont r20,0
    mapFont r20,1
    mapFont r20,2
    mapFont r20,3 ; 4
    mapFont r20,4
    mapFont r20,5
    mapFont r20,6
    mapFont r20,7 ; 8
    mapFont r21,0
    mapFont r21,1
    mapFont r21,2
    mapFont r21,3 ; 12
    mapFont r21,4
    mapFont r21,5
    mapFont r21,6
    mapFont r21,7 ; 16
    mapFont r22,0
    mapFont r22,1
    mapFont r22,2
    mapFont r22,3 ; 20
    mapFont r22,4
    mapFont r22,5
    mapFont r22,6
    mapFont r22,7 ; 24

    ;cbon

    addressToX scanlinebuffer
    renderByte
    renderByte
    renderByte
    renderByte ;4
    renderByte
    renderByte
    renderByte
    renderByte ;8
    renderByte
    renderByte
    renderByte
    renderByte ;12
    renderByte
    renderByte
    renderByte
    renderByte ;16
    renderByte
    renderByte
    renderByte
    renderByte ;20
    renderByte
    renderByte
    renderByte
    renderByte ;24
    nop
    nop
    whiteclear

    ;cboff

    checkUart
    checkLineFunction 0 renderLower
    ret

renderUpper:
    doSync
    checkUart
    processUart

    checkLineFunction 64 renderScanline
    ret

renderLower:
    doSync

    checkUart
    processUart

    ;delay4us
    ;delay4us
    ;delay4us
    ;delay4us
    ;cron
    ;delay4us
    ;crfxon
    ;delay4us
    ;cbon
    ;delay4us
    ;cbfxon
    ;delay4us
    ;croff
    ;delay4us
    ;crfxoff
    ;delay4us
    ;cboff
    ;delay4us
    ;cbfxoff
    ;delay4us
    ;crfxoff

    checkLineFunction 54 renderVerticalSyncD  ; previous loop of 256 + 56 = line 312

    lds r24, lastChar   ; skip hacky flash cursor while receiving non zero chars
    tst r24
    brne noHacky
    increment r24 frame
    lsr r24             ; hacky flash cursor at fixed position under READY
    lsr r24
    lsr r24
    lsr r24
    andi r24, 1
    sts charbuffer+(32*23), r24

noHacky:
    ret

    .global renderVerticalSync
renderVerticalSync:     ; long long
    zero        ; long
    delay30us

    black       ; notch
    delay2us

    zero        ; long
    delay30us
    black

    checkLineFunction 2 renderVerticalSyncB
    ret

renderVerticalSyncB:     ; long short
    zero        ; long
    delay30us

    black       ; notch
    delay2us

    zero        ; short
    delay2us

    black       ; cruizin

    checkUart

    checkLineFunction 3 renderVerticalSyncC
    ret

renderVerticalSyncC:       ; short short
    zero        ; short
    delay2us

    black       ; cruizin
    delay30us

    zero        ; short
    delay2us

    black       ; cruizin

    checkUart

    checkLineFunction 5 renderUpper
    ret

renderVerticalSyncD:       ; short short
    zero        ; short
    delay2us

    black       ; cruizin
    delay30us

    zero        ; short
    delay2us

    black       ; cruizin

    checkUart

    checkLineFunction 57 renderVerticalSync  ; previous loop of 256 + 56 = line 312
    clear counter
    ret

.global    __vector_11 ; TIMER1_COMPA_vect1
__vector_11:
    ldi r16, 0      ; r16 is our constant zero

    lds r30,lineFunction
    lds r31,lineFunction+1
    icall

    ldi r16, 1      ; tell the slippery slide that the ISR has returned
    reti

    .end
