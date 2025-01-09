;   xmodem.s
;
;   xmodem upload and download
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
.include "xmodem.inc"

.code
;==============================================================================
xmodem_send:
;------------------------------------------------------------------------------
;   input:
;       w0          start address
;       w1          end address
;   changes:
;       X, Y, w0
;   output:
;       C           C=0: transmission failed, C=1: ok
;   remarks:
;       - receiver driven
;       - no retry limit, global timeout only (60s) 
;       - garbage data sent at end of last block
;------------------------------------------------------------------------------
;   wait for initial nak
    ldx #SERIAL_IN_TIMEOUT_60S
@wait_nak:
    jsr serial_in_char_timeout
    bcc @timeout                ; timeout
    cmp #NAK
    bne @wait_nak
    stz tmp1                    ; block #

@next_block:    
    ldx #SERIAL_IN_TIMEOUT_60S
    inc tmp1

;   done?
    CMP16_MEM16 w0, w1
    beq @send_block
    bcs @send_eot

@send_block:    
    lda #SOH
    jsr serial_out_char
    lda tmp1                    ; block #
    jsr serial_out_char
    lda tmp1
    eor #$FF
    jsr serial_out_char       ; invers block # 
    ldy #0                      
    tya                         ; chksum

@loop:    
    pha
    lda (w0), y
    jsr serial_out_char
    pla
    clc
    adc (w0), y
    iny
    bpl @loop
    jsr serial_out_char       ; chksum
    
@wait_ack:
    jsr serial_in_char_timeout
    bcc @timeout                
    cmp #NAK
    beq @send_block
    cmp #ACK
    bne @wait_ack

    lda #$7f                    ; C = 1
    adc w0l
    sta w0l
    bcc @next_block
    inc w0h
    bne @next_block

@send_eot:
    lda #EOT
    jsr serial_out_char

@wait_ack_eot:
    jsr serial_in_char_timeout
    bcc @timeout                
    cmp #NAK
    beq @send_eot
    cmp #ACK
    bne @wait_ack_eot
    rts                         ; C = 1

@timeout:
    rts                         ; C = 0

;==============================================================================
