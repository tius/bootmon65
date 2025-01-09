;   print.s
;
;   helper functions for printing
;
;   prerequisites:
;       - print_char (must preserve tmp6 and tmp7)
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
print_char_space: 
;------------------------------------------------------------------------------
    jsr print_char
    bra print_space

;==============================================================================
print_crlf:
;------------------------------------------------------------------------------
    jsr print_cr

;==============================================================================
print_lf:
;------------------------------------------------------------------------------
    lda #$0a
    SKIP2                               ; skip next 2-byte instruction

;==============================================================================
print_space:
;------------------------------------------------------------------------------
    lda #' '
    SKIP2                               ; skip next 2-byte instruction
       
;==============================================================================
print_cr:
;------------------------------------------------------------------------------
    lda #$0d
    jmp print_char
