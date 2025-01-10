;   input/input_bin8.s
;
;   binary input
;
;   remark:
;       - we could save 4 bytes by sharing code with input_hex.s
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
input_bin8:
;------------------------------------------------------------------------------
;   output:
;       A       decoded value
;       C       0: data invalid, 1: data valid
;       Z       data == 0
;------------------------------------------------------------------------------
    jsr input_skip_spaces
    stz tmp0
    phy
    ldy #0                              ; no of valid digits

@loop:
    jsr input_char                      ; $30/$31
    beq @done
    eor #$30                            ; $00/$01
    cmp #$02
    bcs @done
    iny 
    lsr
    rol tmp0
    bra @loop

@done:
    lda tmp0                            ; result   
    dec input_idx                       ; unget last character
    cpy #1                              ; at least one digit found
    ply
    rts

;==============================================================================
