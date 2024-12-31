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
    
_print_char:    
    jmp print_char
      
;==============================================================================
print_bin8:
;------------------------------------------------------------------------------
;   input:
;       A           8 bit value to print
;------------------------------------------------------------------------------
    phx
    ldx #8
@loop:    
    asl
    pha
    lda #'0'
    adc #0
    jsr print_char
    pla
    dex
    bne @loop
    plx
    rts

;==============================================================================
print_char_space: 
;------------------------------------------------------------------------------
    jsr print_char
    jmp print_space
 
;==============================================================================
print_mem_row:
;------------------------------------------------------------------------------
;   input:
;       A       no. of bytes to print
;       w0      start address
;   output:
;       w0      end address + 1
;------------------------------------------------------------------------------
    pha
    lda #':'
    jsr print_char
    jsr print_space
    jsr print_hex16_w0
    pla

;==============================================================================
print_hex_bytes_crlf:
;------------------------------------------------------------------------------
;   print line with multiple hex values separated by space
;
;   input:
;       A       no. of values                   
;       w0      start address
;   output:
;       w0      end address + 1
;------------------------------------------------------------------------------
@loop:     
    pha
    jsr print_space
    lda (w0)
    jsr print_hex8
    jsr inc_w0
    pla

    dec
    bne @loop

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
    bra _print_char
    
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
