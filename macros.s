
; standard AVR shortcut macros

.macro addressToX address
    ldi r26,lo8(\address)  ; X
    ldi r27,hi8(\address)
.endm

.macro addressToY address
    ldi r28,lo8(\address)  ; Y
    ldi r29,hi8(\address)
.endm

.macro addressToZ address
    ldi r30,lo8(\address)  ; Z
    ldi r31,hi8(\address)
.endm

.macro addAddressToZ address
    subi r30,lo8(-(\address))
    sbci r31,hi8(-(\address))
.endm

.macro addToX reg1, reg2
    add r26,\reg1
    adc r27,\reg2
.endm

.macro addToY reg1, reg2
    add r28,\reg1
    adc r29,\reg2
.endm

.macro addToZ reg1, reg2
    add r30,\reg1
    adc r31,\reg2
.endm

.macro copyXtoY
    mov r28, r26            ; X -> Y
    mov r29, r27
.endm

.macro setFunctionPointer pointer function
    ldi r17,lo8(gs(\function))
    sts \pointer,r17
    ldi r17,hi8(gs(\function))
    sts \pointer+1,r17
.endm

.macro increment reg address
    lds \reg,\address
    subi \reg,lo8(-(1))
    sts \address,\reg
.endm

.macro incrementAndMask reg mask address
    lds \reg,\address
    subi \reg,lo8(-(1))
    andi \reg, \mask
    sts \address,\reg
.endm

.macro clear address
    sts \address,r16
.endm

.macro delay1us
    nop
    nop
    nop
    nop ;4
    nop
    nop
    nop
    nop ;8
    nop
    nop
    nop
    nop ;12
    nop
    nop
    nop
    nop ;16
.endm

.macro delay2us
    delay1us
    delay1us
.endm

.macro delay4us
    delay1us
    delay1us
    delay1us
    delay1us
.endm

.macro delay30us
    delay4us
    delay4us
    delay4us
    delay4us
    delay4us
    delay4us
    delay4us
    delay2us
.endm

