;   x_cmp_size8.s
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
;=============================================================================
x_cmp_size8:                          ; ( addr1 addr2 size8 -- )
;------------------------------------------------------------------------------
;   compare two memory blocks with 8 bit size
;   - not speed optimized
;   - size 1 .. 256
;   
;   output:
;       Z           addr1[0..size-1] == addr2[0..size-1]
;       C           addr1[0..size-1] >= addr2[0..size-1]
;------------------------------------------------------------------------------
    phy
    ldy stack, x                        ; size8

@loop:
    lda (stack + 3, x)                  ; addr1
    sbc (stack + 1, x)                  ; addr2
    sta tmp0
    bne @done

    INC16 { stack + 1, x }
    INC16 { stack + 3, x }
    dey
    bne @loop

@done:
    inx                                 ; pop len
    inx                                 ; pop addr2
    inx
    inx                                 ; pop addr1
    inx
    ply
    lda tmp0
    rts
 