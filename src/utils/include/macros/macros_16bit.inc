;   macros_16bit.inc
;
;   macros for some common 16 bit operations
;
;   credits:
;       - http://6502org.wikidot.com/software-incdec
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

;==============================================================================
;   16 bit operations on A/Y
;------------------------------------------------------------------------------
.macro INCAY
.local @done
    inc 
    bne @done
    iny
@done:    
.endmacro

;------------------------------------------------------------------------------
.macro LDAY w
    lda w
    ldy 1 + w 
.endmacro

;------------------------------------------------------------------------------
.macro STAY w
    sta w
    sty 1 + w
.endmacro

;==============================================================================
;   16 bit operations on A/X
;------------------------------------------------------------------------------
.macro INCAX
.local @done
    inc 
    bne @done
    inx
@done:    
.endmacro

;------------------------------------------------------------------------------
.macro STAX w
    sta w
    stx 1 + w
.endmacro

;==============================================================================
;   16 bit operations on memory word
;------------------------------------------------------------------------------
.macro INC16 w
.local @done
    inc w
    bne @done
    inc 1 + w 
@done:    
.endmacro    

;------------------------------------------------------------------------------
.macro DEC16 w
.local @l0
    lda w
    bne @l0
    dec 1 + w
@l0:    
    dec w 
.endmacro    

.macro BEQ_DEC16 w, label
.local @l0
    lda w
    bne @l0
    lda 1 + w
    beq label
    dec 1 + w
@l0:    
    dec w 
.endmacro    

;------------------------------------------------------------------------------
.macro SET16 w, val
    lda #<val
    sta 0 + w
    lda #>val
    sta 1 + w
.endmacro    

;------------------------------------------------------------------------------
.macro CPY16 w1, w2
    lda 0 + w2
    sta 0 + w1
    lda 1 + w2
    sta 1 + w1
.endmacro    

;------------------------------------------------------------------------------
.macro CMP16 w, val
.local @done
    lda 0 + w
    cmp #<val
    bne @done
    lda 1 + w
    cmp #>val
@done:
.endmacro    

.macro CMP16_MEM16 w1, w2
.local @done
    lda 1 + w1
    cmp 1 + w2
    bne @done
    lda w1
    cmp w2
@done:    
.endmacro    

;------------------------------------------------------------------------------
.macro ADD16 w1, val
    lda w1
    adc #<val
    sta w1
    lda w1 + 1
    adc #>val
    sta w1 + 1
.endmacro