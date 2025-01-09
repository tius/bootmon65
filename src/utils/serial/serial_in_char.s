;   serial_in_char.s
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
serial_in_char_timeout:
;------------------------------------------------------------------------------
;   receive one byte with timeout
;
;   input:
;       X       timeout value (steps of 0.72 s)
;
;   output (ok):     
;       A       received byte 
;       X       remaining timeout value
;       C       1
;
;   output (timeout):     
;       A       0
;       X       0
;       C       0
;
;   remarks:
;       - too slow to process data at line speed 8n1 
;------------------------------------------------------------------------------
    phy
    WAIT_TIMEOUT _in_byte               ; 7     (+ 11 cycles jitter)
    clc                                 ; timeout
    ply
    rts                         

;       26.5    cycles required until next sampling
;   -    7      delay by WAIT_TIMEOUT
;   -    5.5    jitter / 2 by WAIT_TIMEOUT
;   -    7      initial delay by INPUT_BYTE_SHORT
;   =    7      cycles needed until INPUT_BYTE_SHORT

;==============================================================================
serial_in_char:
;------------------------------------------------------------------------------
;   receive one byte (blocking)
;
;   output:     
;       A       received byte
;       C       1   
;
;   remarks:
;       - total time is 178 cycles including jsr/rts
;       - should be fast enough for simple interactive applications  
;       - this is too slow to process data at line speed 8n1 however 
;------------------------------------------------------------------------------
    WAIT_BLOCKING                       ; 6     (+ 7 cycles jitter)

;       26.5    cycles required until next sampling
;   -    6      delay by WAIT_BLOCKING
;   -    3.5    jitter / 2 by WAIT_BLOCKING
;   -    7      initial delay by INPUT_BYTE_SHORT
;   =   10      cycles needed until INPUT_BYTE_SHORT

    phy                                 ; 3

_in_byte:    
    phx                                 ; 3
    ldy #$7f                            ; 2
    DELAY2                              ; 2
    INPUT_BYTE_SHORT                    ; 140   (7 initial delay)
    plx                                 ; 4
    ply                                 ; 4
    sec                                 ; 2     required for serial_in_char_timeout
    rts                                 ; 6     (+ 6 for jsr)
