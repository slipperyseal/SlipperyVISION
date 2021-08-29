
    .section .text

    ; what is this you ask? this project uses exact timing of an ISR.
    ; if the ISR fires while a multi cycle instruction is executing, this offsets the time
    ; the ISR executes. it may only be 1 or 2 cycles but that's enough to skew the video.
    ; there seems to be no way to branch or jump without at least two cycles being used.
    ; to get around this, the main loop run a long sequence of single cycle instructions.
    ; but it has to loop back the to start at some point. so what we do is clear a register and
    ; wait for that value to change. the change will be the signal from the ISR that it's just
    ; returned. this is a good time to get to the top of the loop again.
    ; as conditional branches can only be +/- 64 instructions, we have to leap frog our way to the top or
    ; bottom of the loop (which does a long range jump to the top again), whichever is closer.

    ; 1024 (max time of ISR) / 59 (cycles of jumpblock) = 17 blocks

.macro jumpblock firsttarget target
    brne \firsttarget
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
    brne \target
    tst r16
.endm

    .global slipperyslide
slipperyslide:
    clr r16
    tst r16
block1:     ; upper half - all blocks jump backwards to slipperyslide
    jumpblock slipperyslide, slipperyslide
block2:
    jumpblock block1, block2
block3:
    jumpblock block2, block3
block4:
    jumpblock block3, block4
block5:
    jumpblock block4, block5
block6:
    jumpblock block5, block6
block7:
    jumpblock block7, block8
block8:
    jumpblock block8, block9
block9:     ; lower half - go forward to the final jump
    jumpblock block10, block10
block10:
    jumpblock block11, block11
block11:
    jumpblock block12, block12
block12:
    jumpblock block13, block13
block13:
    jumpblock block14, block14
block14:
    jumpblock block15, block15
block15:
    jumpblock block16, block16
block16:
    jumpblock block17, block17
block17:
    jumpblock slidebottom, slidebottom
slidebottom:
    jmp slipperyslide
    .end
