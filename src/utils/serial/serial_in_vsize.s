;   serial_in_vsize.s
;
;   read block with len byte at wire speed, timeout 0.72 s per byte
;
;   see also: 
;       - serial_in.inc
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
serial_in_vsize:
;------------------------------------------------------------------------------
;   read block with len byte at wire speed, timeout 0.72 s per byte
;
;   requriments:
;       buffer      256 bytes
;
;   changed:
;       X
;
;   output:
;       C           1: ok, 0: timeout
;       Y           no. of bytes received
;       buffer      received bytes
;
;------------------------------------------------------------------------------
    ldy #$ff                            ; byte counter is incremented at start of loop
    ldx #0                              ; 0.72 s initial timeout

@loop:    
    WAIT_TIMEOUT_SHORT @start           ; 7 + 11 cycles jitter
    clc                                 ; timeout                                      
    rts

;       26.5    cycles required until next sampling
;   -    7      delay by WAIT_TIMEOUT
;   -    5.5    jitter / 2 by WAIT_TIMEOUT
;   -    7      initial delay by INPUT_BYTE_SHORT
;   =    7      cycles needed until INPUT_BYTE_SHORT

@start:
    iny                                 ; 2
    phy                                 ; 3

    ldy #$7f                            ; 2
    INPUT_BYTE_SHORT                    ; 140 (7 initial delay), X = 0

    ply                                 ; 4
    sta buffer, y                       ; 5

    cpy buffer                          ; 4     1st byte is size
    ASSERT_BRANCH_PAGE bne, @loop       ; 3/2
                                        ; 170   total loop time
;   C = 1
    rts                                  


