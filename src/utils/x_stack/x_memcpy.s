;   x_memcpy.s
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
;   x_memcpy                            ( src dst size16 -- )
;   - not speed optimized
;   - ranges must not overlap unless dst < src
;------------------------------------------------------------------------------
_x_memcpy_loop:
    lda  (stack + 4, x)                 ; src
    sta  (stack + 2, x)                 ; dst

    INC16 { stack + 4, x }              ; src++
    INC16 { stack + 2, x }              ; dst++
    DEC16 { stack, x }                  ; size16--

x_memcpy:                               
    lda  stack, x        
    ora  stack + 1, x
    bne  _x_memcpy_loop

;==============================================================================
x_drop6:                                ; ( x x x x x x -- )
    inx
x_drop5:                                ; ( x x x x x -- )
    inx
x_drop4:                                ; ( x x x x -- )
    inx
    inx
    inx
    inx
    rts
