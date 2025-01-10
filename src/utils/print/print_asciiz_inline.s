;   print_asciiz_inline.s
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
print_inline_asciiz:
;------------------------------------------------------------------------------
;   input:
;       <inline>    asciiz string
;
;   see also:
;       - http://6502.org/source/io/primm.htm
;       - http://wilsonminesco.com/stacks/inlinedData.html
;------------------------------------------------------------------------------
;   avoid overhead of saving tmp6 and tmp7

.if !PRINT_CHAR_PRESERVES_TMP67
    .error "print_char must preserve tmp6 and tmp7"
.endif

;------------------------------------------------------------------------------
    pla
    sta tmp6
    pla
    sta tmp7

@loop:    
    INC16 tmp6
    lda (tmp6)
    beq @done
    jsr print_char
    bra @loop

@done:    
    lda tmp7
    pha
    lda tmp6
    pha

    rts    
