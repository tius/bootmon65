;   macros_misc.inc
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
;   hex conversion
;------------------------------------------------------------------------------
;   credits: Bruce Clark 

.macro BIN4_TO_HEX
    sed
    cmp #$0a
    adc #$30
    cld
.endmacro

;------------------------------------------------------------------------------
;   cheap hex character to bin value without error checking

.macro HEX_TO_BIN4_CHEAP
.local @done
    cmp #':'
    and #15
    bcc @done
    adc #8
@done:     
.endmacro

;==============================================================================
;   minimal memcpy (255 bytes max.)
;------------------------------------------------------------------------------
;   side effects:
;       x       0
;       z       1 
;------------------------------------------------------------------------------
.macro COPY_USING_X dest, src, size
.local @loop
    ldx #size
@loop:  
    lda src - 1, x
    sta dest - 1, x
    dex
    bne @loop
.endmacro    
