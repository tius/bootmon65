;   x_stack16.s
;
;   software stack
;       - starts at $ff and grows downward within zeropage 
;
;   credits:
;       https://wilsonminesco.com/stacks/      
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
.include "config.inc"
.include "utils.inc"

.code
;==============================================================================
x_push32_0:                            ; ( -- $0000 $0000 )
    jsr x_push16_0

;==============================================================================
x_push16_0:                            ; ( -- $0000 )
;------------------------------------------------------------------------------
    dex
    stz stack,x
    dex
    stz stack,x
    rts

;==============================================================================
x_dup16:                                ; ( w -- w w )
;------------------------------------------------------------------------------
    dex
    dex
    lda stack + 2, x
    sta stack, x
    lda stack + 3, x
    sta stack + 1, x
    rts

;==============================================================================
x_swap16:                               ; ( w1 w2 -- w2 w1 )
;------------------------------------------------------------------------------
    phy
    lda  0 + stack, x 
    ldy  2 + stack, x
    sta  2 + stack, x
    sty  0 + stack, x

    lda  1 + stack, x
    ldy  3 + stack, x
    sta  3 + stack, x
    sty  1 + stack, x
    ply
    rts

;==============================================================================
x_rot16:                                ; ( w1 w2 w3 -- w2 w3 w1 )
;------------------------------------------------------------------------------
    phy
    ldy  0 + stack, x        
    lda  4 + stack, x        
    sta  0 + stack, x
    lda  2 + stack, x  
    sta  4 + stack, x
    sty  2 + stack, x

    ldy  1 + stack, x
    lda  5 + stack, x
    sta  1 + stack, x
    lda  3 + stack, x
    sta  5 + stack, x
    sty  3 + stack, x    
    ply
    rts
   
;==============================================================================
x_push16_inline:                        ; ( -- literal16 )
;------------------------------------------------------------------------------
    pla
    sta tmp0
    pla
    sta tmp1

    dex
    dex

    INC16 tmp0
    lda (tmp0)                          ; lo byte first
    sta stack,x 

    INC16 tmp0
    lda (tmp0)                          ; hi byte
    sta stack + 1,x 

    lda tmp1
    pha
    lda tmp0
    pha
    rts        
