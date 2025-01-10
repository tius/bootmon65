;   macros_stack.inc
;
;------------------------------------------------------------------------------
;   MIT License
;
;   Copyright (c) 1978-2025 Matthias Waldorf, https://tius.org
;
;   Permission is hereby granted, free of charge, to any person obtaining a copy
;   of this software and associated documentation files (the "Software"), to deal
;   in the Software without restriction, including without limitation the rights
;   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;   copies of the Software, and to permit persons to whom the Software is
;   furnished to do so, subject to the following conditions:
;
;   The above copyright notice and this permission notice shall be included in all
;   copies or substantial portions of the Software.
;
;   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;   SOFTWARE.
;------------------------------------------------------------------------------

;==============================================================================
;   8 bit stack operations
;------------------------------------------------------------------------------
.macro X_PUSH_A                         ; ( -- A )
    dex
    sta stack,x
.endmacro

.macro X_PUSH_Y                         ; ( -- Y )
    dex
    sty stack,x
.endmacro

.macro X_PUSH val                       ; ( -- val8 )
    dex
    lda #val
    sta stack,x
.endmacro

.macro X_PUSH_0                         ; ( -- A )
    dex
    stz stack,x
.endmacro

;------------------------------------------------------------------------------
.macro X_PULL_A                         ; ( A -- )
    lda stack,x
    inx
.endmacro

.macro X_PULL_Y                         ; ( Y -- )
    ldy stack,x
    inx
.endmacro

;------------------------------------------------------------------------------
.macro X_DROP                           ; ( val8 -- )
    inx
.endmacro

;==============================================================================
;   16 bit stack operations
;------------------------------------------------------------------------------
.macro X_DROP16                         ; ( val16 -- )
    inx
    inx
.endmacro

;------------------------------------------------------------------------------
.macro X_PUSH_MEM16 addr                ; ( -- addr[1] addr[0] )
    lda 1 + addr                        ; high byte first for l, h on stack
    X_PUSH_A
    lda addr
    X_PUSH_A
.endmacro

.macro X_PULL_MEM16 addr                ; ( addr[1] addr[0] -- )
    X_PULL_A
    sta addr
    X_PULL_A
    sta 1 + addr
.endmacro

;------------------------------------------------------------------------------
.macro X_PUSH16 val                     ; ( -- val16 )
    jsr x_push16_inline
    .word val
.endmacro

;==============================================================================
;   32 bit stack operations             *** optimize me for code size 
;------------------------------------------------------------------------------
.macro X_PUSH_MEM32 addr                ; ( -- addr[3] addr[2] addr[1] addr[0] )
    lda 3 + addr
    X_PUSH_A
    lda 2 + addr
    X_PUSH_A
    lda 1 + addr
    X_PUSH_A
    lda 0 + addr
    X_PUSH_A
.endmacro

.macro X_POP_MEM32 addr                 ; ( addr[3] addr[2] addr[1] addr[0] -- )
    X_PULL_A
    sta 0 + addr
    X_PULL_A
    sta 1 + addr
    X_PULL_A
    sta 2 + addr
    X_PULL_A
    sta 3 + addr
.endmacro
