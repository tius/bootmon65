;   serial_in_xmodem.s
;   
;   see also serial_in.inc
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
.include "serial_in.inc"

;==============================================================================
serial_in_xmodem:
;------------------------------------------------------------------------------
;   read 132 byte xmodem block at wire speed with timeout
;
;   changed:
;       X
;   output:     
;       input_buffer
;       A           no. of bytes received           
;       Z           Z=0: data received, Z=1: timeout on 1st byte
;       C           C=0: timeout, C=1 full block received
;
;   remarks:
;       - timeout ~10 s for 1st byte
;       - timeout ~0.4 s for remaining bytes
;------------------------------------------------------------------------------
    phy
    stz tmp0
    ldx #SERIAL_IN_TIMEOUT_10S          ; initial timeout 10s

    SKIP2                               ; skip next 2-byte instruction

@loop:    
    ldx #1                              ; 2     byte timeout 0.4s (with Y = 127)
    WAIT_TIMEOUT @start                 ; 7 + 11 cycles jitter
    clc                                 ; timeout                                      
    bra @done
;       26.5    cycles required until next sampling
;   -    7      delay by WAIT_TIMEOUT
;   -    5.5    jitter / 2 by WAIT_TIMEOUT
;   -    7      initial delay by INPUT_BYTE_SHORT
;   =    7      cycles needed until INPUT_BYTE_SHORT

@start:
    ldy #$7f                            ; 2
    inc tmp0                            ; 5
    INPUT_BYTE_SHORT                    ; 140 (7 initial delay)

    ldx tmp0                            ; 3
    sta input_buffer - 1, x             ; 5
    cpx #132                            ; 2
    ASSERT_BRANCH_PAGE bcc ,@loop       ; 3/2

;   total loop time 169 cycles

@done:    
    ply
    lda tmp0
    rts
