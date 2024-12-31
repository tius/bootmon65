;   macros_32bit.inc
;
;   macros for some common 32 bit operations

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
.macro STZ32 dw
    stz dw
    stz 1 + dw 
    stz 2 + dw 
    stz 3 + dw 
.endmacro    

;------------------------------------------------------------------------------
.macro CPY32 dw1, dw2
    lda 0 + dw2
    sta 0 + dw1
    lda 1 + dw2
    sta 1 + dw1
    lda 2 + dw2
    sta 2 + dw1
    lda 3 + dw2
    sta 3 + dw1
.endmacro    

;------------------------------------------------------------------------------
.macro CMP32_MEM32 dw1, dw2
.local @done
    lda 0 + dw2
    cmp 0 + dw1
    bne @done
    lda 1 + dw2
    cmp 1 + dw1
    bne @done
    lda 2 + dw2
    cmp 2 + dw1
    bne @done
    lda 3 + dw2
    cmp 3 + dw1
@done:
.endmacro    

;------------------------------------------------------------------------------
.macro INC32 dw
.local @done
    inc dw
    bne @done
    inc 1 + dw 
    bne @done
    inc 2 + dw 
    bne @done
    inc 3 + dw 
@done:    
.endmacro    

;------------------------------------------------------------------------------
.macro ASL32 dw
    asl dw
    rol 1 + dw
    rol 2 + dw
    rol 3 + dw
.endmacro    

;------------------------------------------------------------------------------
.macro ADD32_MEM32 dw1, dw2
    lda dw1
    adc dw2
    sta dw1
    lda dw1 + 1
    adc dw2 + 1
    sta dw1 + 1
    lda dw1 + 2
    adc dw2 + 2
    sta dw1 + 2
    lda dw1 + 3
    adc dw2 + 3
    sta dw1 + 3
.endmacro