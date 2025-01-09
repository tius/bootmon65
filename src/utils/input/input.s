;   input.s
;
;   parse input line
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

;------------------------------------------------------------------------------
.include "config.inc"
.include "utils.inc"

;==============================================================================
.zeropage
;------------------------------------------------------------------------------
input_idx:          .res 1

.code
;==============================================================================
input_char:
;------------------------------------------------------------------------------
;   side effects:
;       input_idx
;   output:
;       A
;       C       0: end of line, 1: valid char
;   remarks:
;       - does not stop at null byte (!)
;       - this avoids edge cases when undoing last character
;------------------------------------------------------------------------------
    phx
    ldx input_idx
    lda input_buffer, x
    inc input_idx
    plx
    cmp #$01                ; set C unless eol
    rts    

;==============================================================================
input_skip_spaces:
;------------------------------------------------------------------------------
;   side effects:
;       input_idx
;------------------------------------------------------------------------------
@skip:
    jsr input_char
    cmp #' '
    beq @skip
    dec input_idx            ; unget last character
    rts
 
;==============================================================================
