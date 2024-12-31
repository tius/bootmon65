;   delay_ms.s
;
;   simple ms delay function
;
;   see also:
;       - http://6502org.wikidot.com/software-delay (longer delays)
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
delay_ms:
;------------------------------------------------------------------------------
;   delay given number of milliseconds (not accurate)
;
;   input:
;       A       number of milliseconds at 1 MHz
;------------------------------------------------------------------------------
@outer_loop: 
    pha                                 ; 3
    lda #197                            ; 2

@inner_loop:
    dec                                 ; 2
    bne @inner_loop                     ; 3 / 2
    ; 985 total for inner loop (n * 5 - 1)

    pla                                 ; 4
    dec                                 ; 2
    ASSERT_BRANCH_PAGE bne, @outer_loop ; 3 / 2    
    ; A * 999 - 1 total for outer loop

    rts                                 ; 6 + 6            
