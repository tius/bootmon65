;   print_hex.s
;
;   print hex numbers
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
print_hex16_w0:
;------------------------------------------------------------------------------
;   input:
;       w0
;------------------------------------------------------------------------------
    lda w0h
    jsr print_hex8
    lda w0l
    bra print_hex8
    
;==============================================================================
print_hex16_ay:                       
;------------------------------------------------------------------------------
    pha
    tya
    jsr print_hex8
    pla
    
;==============================================================================
print_hex8:
;------------------------------------------------------------------------------
;   input:
;       A           8 bit value to print
;------------------------------------------------------------------------------
    pha
    lsr a
    lsr a
    lsr a
    lsr a
    jsr print_hex4
    pla
    and #15

;==============================================================================
print_hex4:
;------------------------------------------------------------------------------
;   input:
;       A           4 bit value to print
;------------------------------------------------------------------------------
    BIN4_TO_HEX
    jmp print_char
      
