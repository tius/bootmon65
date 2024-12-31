;   delay_cycles.s
;
;   short cycle accurate delays
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
.include "utils.inc"
 
.code
;==============================================================================
;   nice hack for longer delays
;
;   changed: 
;       N, Z and C  
;
;   credits:
;       - https://www.pagetable.com/?p=669
;------------------------------------------------------------------------------
delay20:
    .byte $c9               ; 2     cmp #
delay19:
    .byte $c9               ; 2     cmp #
delay18:
    .byte $c9               ; 2     cmp #
delay17:
    .byte $c9               ; 2     cmp #
delay16:
    .byte $c9               ; 2     cmp #
delay15:
    .byte $c5               ; 3     cmp zp   
delay14:
    nop                     ; 2
delay12:    
    rts                     ; 6 + 6
