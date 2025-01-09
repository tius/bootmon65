;   input/input_hex.s
;
;   hex and binary input routines
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
input_hex:
;------------------------------------------------------------------------------
;   side effects:
;       input_idx
;
;   output:
;       tmp0..3 decoded value L .. HH
;       A       no. of valid digits
;       C       0: data invalid, 1: at least one digit found
;
;   remarks:
;       - support lower and upper case hex digits
;------------------------------------------------------------------------------
    jsr input_skip_spaces
    stz tmp0
    stz tmp1
    stz tmp2
    stz tmp3
    phy
    ldy #0                              ; no of valid digits

@decode:                
    ;   wozmon style hex decoding ;-)
    jsr input_char                      ; $30..$39, $41..$46, $61..$66
    beq done                
    eor #$30                            ; $00..$09, $71..$76, $51..$56
    cmp #$0a                
    bcc @valid_digit                
    and #$df                            ; $51..$56
    adc #$a8                            ; $fa..$ff
    cmp #$fa                
    bcc @done                           ; invalid hex digit

@valid_digit:               
    iny                 
    asl             
    asl             
    asl             
    asl                                 ; $00, $10, ..., $F0

    ;   shift digit into tmp0..3
    phx
    ldx #4
@shift:
    asl
    rol tmp0
    rol tmp1
    rol tmp2
    rol tmp3     
    dex
    bne @shift
    plx
    bra @decode         

@done:
    dec input_idx                       ; unget last character
    tya                                 ; no. of valid digits
    ply
    cmp #1                              ; at least one digit found
    rts
   
;==============================================================================
input_hex8:
;------------------------------------------------------------------------------
;   output:
;       A       decoded value
;       C       0: data invalid, 1: data valid
;------------------------------------------------------------------------------
    jsr input_hex
    lda tmp0                            ; result low byte
    rts

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
    beq done
    eor #$30                            ; $00/$01
    cmp #$02
    bcs done
    iny 
    lsr
    rol tmp0
    bra @loop

done:
    dec input_idx                       ; unget last character
    cpy #1                              ; at least one digit required
    ply
    lda tmp0                            ; result low byte
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
