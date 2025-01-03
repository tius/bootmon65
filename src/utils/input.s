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
_skip_spaces:
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
input_hex:
;------------------------------------------------------------------------------
;   side effects:
;       input_idx
;
;   output:
;       tmp0    decoded value L (for internal module use only)
;       tmp1    decoded value H (for internal module use only)
;       A       decoded value L
;       C       0: data invalid, 1: data valid
;       Z       A == 0
;
;   remarks:
;       - support lower and upper case hex digits
;       - discard excessive leading digits 
;------------------------------------------------------------------------------
    jsr _skip_spaces
    stz tmp0
    stz tmp1
    phy
    ldy #0              ; no of valid digits

@decode:                
    ;   wozmon style hex decoding ;-)
    jsr input_char      ; $30..$39, $41..$46, $61..$66
    beq done
    eor #$30            ; $00..$09, $71..$76, $51..$56
    cmp #$0a
    bcc @valid_digit
    and #$df            ; $51..$56
    adc #$a8            ; $fa..$ff
    cmp #$fa
    bcc done            ; invalid hex digit, C = 0

@valid_digit:
    iny    
    asl
    asl
    asl
    asl                 ; $00, $10, ..., $F0

    ;   shift digit into tmp0/tmp1
    phx
    ldx #4
@shift:
    asl
    rol tmp0
    rol tmp1
    dex
    bne @shift
    plx
    bra @decode         

;==============================================================================
input_hex16_ay:
;------------------------------------------------------------------------------
;   side effects:
;       input_idx
;
;   output:
;       A       decoded value L                 
;       Y       decoded value H
;       C       0: data invalid, 1: data valid
;------------------------------------------------------------------------------
    jsr input_hex
    ldy tmp1
    rts

;==============================================================================
input_hex16_w0:
;------------------------------------------------------------------------------
;   side effects:
;       input_idx
;
;   output:
;       w0      decoded value L, H                 
;       C       0: data invalid, 1: data valid
;------------------------------------------------------------------------------
    jsr input_hex
    sta w0l
    lda tmp1
    sta w0h
    rts

;==============================================================================
;   x_input_hex16:                          ; (-- u16)
;------------------------------------------------------------------------------
;   side effects:
;       input_idx
;
;   output:
;       C       0: data invalid, 1: data valid
;------------------------------------------------------------------------------
;   jsr input_hex
;   X_PUSH_W tmp0
;   rts

;==============================================================================
input_bin8:
;------------------------------------------------------------------------------
;   output:
;       A       decoded value
;       C       0: data invalid, 1: data valid
;       Z       data == 0
;------------------------------------------------------------------------------
    jsr _skip_spaces
    stz tmp0
    phy
    ldy #0              ; no of valid digits

@loop:
    jsr input_char      ; $30/$31
    beq done
    eor #$30            ; $00/$01
    cmp #$02
    bcs done
    iny 
    lsr
    rol tmp0
    bra @loop

done:
    dec input_idx        ; unget last character
    cpy #1
    ply
    lda tmp0
    rts
