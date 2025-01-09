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
xmodem_receive:
;------------------------------------------------------------------------------
;   input:
;       w0          start address
;   changes:
;       X, Y
;   output:
;       A           no. of received blocks
;       C           C=0: transmission failed, C=1: ok
;       w0          end address + 1
;------------------------------------------------------------------------------
block_type      := input_buffer + 0
block_num       := input_buffer + 1
block_num_inv   := input_buffer + 2
block_data      := input_buffer + 3
block_chksum    := input_buffer + 131
;------------------------------------------------------------------------------
    stz tmp1                        ; current block number
    ldy #10  

@retry:    
    lda #NAK

@loop:    
    jsr serial_out_char
    jsr serial_in_xmodem
    beq @nak_block                  ; timeout 1st byte

    lda block_type
    bcc @short_block                ; timeout during block

;   check soh
    cmp #SOH
    bne @nak_block
    
;   check block #
    lda block_num_inv
    eor #$ff
    cmp block_num
    bne @nak_block                   ; invalid block #
    
    sbc tmp1
    beq @ack_block                   ; ignore block 0 and repeated blocks           
    dec a
    bne @nak_block                   ; out of sync
    
;   test checksum
    tax                              ; A=0
@add:
    clc    
    adc block_data, x
    inx
    bpl @add
    eor block_chksum
    bne @nak_block                   ; wrong checksum
   
;   save block
    tax                              ; A=0
@store:    
    lda block_data, x
    sta (w0l)
    jsr inc_w0
    inx
    bpl @store
    inc tmp1

@ack_block:
    ldy #10
    lda #ACK
    bra @loop

@short_block:    
    cmp #EOT
    beq @ack_eot

@nak_block:
    dey 
    bne @retry
    clc
    bra @return

@ack_eot:
    lda #ACK
    jsr serial_out_char
    sec

@return:
    lda tmp1
    rts

;==============================================================================
