;   x_print_mem.s
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
x_memdump:                              ; ( addr size16 -- ) 
;------------------------------------------------------------------------------
    X_PUSH 16

;==============================================================================
x_memdump_cols:                         ; ( addr size16 cols -- ) 
;------------------------------------------------------------------------------
@next_row:
    lda #':'
    jsr print_char_space

    lda stack + 3, x
    ldy stack + 4, x
    jsr print_hex16_ay

    ldy stack, x                        ; cols
@next_col:    
    jsr print_space
    lda (stack + 3, x)    
    jsr print_hex8

    INC16 { stack + 3, x }              ; addr++
    DEC16 { stack + 1, x }              ; size16--

    lda stack + 1, x
    ora stack + 2, x
    beq @done

    dey
    bne @next_col
    jsr print_crlf
    bra @next_row

@done:
    jsr x_drop5
    jmp print_crlf

;==============================================================================
