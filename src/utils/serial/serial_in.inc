;   serial_in.inc

;   bit-bang 57600 baud software serial input
;
;   features:
;       - line speed 57600 baud 8n1 @ 1 MHz CPU clock
;       - half-duplex only
;       - input with and without timeout 
;       - line input with and without echo
;       - xmodem block input at line speed
;       - line input without echo at line speed
;
;   config:
;       SERIAL_IN_REG               input register
;       SERIAL_IN_PORT_PIN          port pin (must be 7)
;
;   requirements:
;       - port pin must initialized to input
;       - timing requires input on bit 7
;
;   general remarks:
;       - very tight timing requirements
;       - large jitter by start bit detection
;       - code alignment is critical for correct timing
;
;   bit timing:
;       - nominal bit time is 17.36 cycles
;       - tuned sampling timing 26.5/17/17/18/17/17/18/17 for reliable rx
;       - large jitter by start bit detection, 
;         7 cycles (without timeout) or 11 cycles (with timeout)
;       - substract jitter/2 from start-bit delay (26.5)
;
;   byte timing:
;       - nominial byte time is 173.6 cycles
;       - 170 cycles total processing time per byte max.
;       - this allows up to 2.1% baud rate tolerance
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
.if SERIAL_IN_PORT_PIN = 7
    .out "using optimized code for port pin 7"
.else
    .error "SERIAL_IN_PORT_PIN must be 7"
.endif

;==============================================================================
.macro WAIT_BLOCKING
;------------------------------------------------------------------------------
;   wait for start bit (blocking)
;   6 cycles + 7 cycles jitter
;------------------------------------------------------------------------------
.local @wait
@wait:    
    bit SERIAL_IN_REG                   ; 4
    ASSERT_BRANCH_PAGE bmi ,@wait       ; 3/2
.endmacro

;==============================================================================
.macro WAIT_TIMEOUT start
;------------------------------------------------------------------------------
;   wait for start bit with timeout (184.5s max.)
;
;   7 cycles + 11 cycles jitter
;
;   input:
;       X, Y    timeout H, L (~2.8 ms per inner loop)
;
;   output (ok):
;       X, Y    remaining timeout H, L
;       Z       0
;
;   output (timeout):
;       X, Y    0
;       Z       1
;------------------------------------------------------------------------------
.local @wait
@wait:    
    bit SERIAL_IN_REG                   ; 4
    ASSERT_BRANCH_PAGE bpl ,start       ; 3/2
    dec                                 ; 2
    bne @wait                           ; 3/2       
                                        ; 2815  total (11 * 256 - 1)

    bit SERIAL_IN_REG                   ; 4
    bpl start                           ; 3/2
    dey                                 ; 2 
    bne @wait                           ; 3/2       

    bit SERIAL_IN_REG                   ; 4
    bpl start                           ; 3/2
    dex                                 ; 2 
    ASSERT_BRANCH_PAGE bne ,@wait       ; 3/2       
    ;   timeout
.endmacro

;==============================================================================
.macro WAIT_TIMEOUT_SHORT start
;------------------------------------------------------------------------------
;   wait for start bit with timeout (0.72s max.)
;
;   7 cycles + 11 cycles jitter
;
;   input:
;       X       timeout (~2.8 ms per inner loop)
;
;   output (ok):
;       X       remaining timeout
;       Z       0
;
;   output (timeout):
;       X       0
;       Z       1
;------------------------------------------------------------------------------
.local @wait
@wait:    
    bit SERIAL_IN_REG                   ; 4
    ASSERT_BRANCH_PAGE bpl ,start       ; 3/2
    dec                                 ; 2
    bne @wait                           ; 3/2       
                                        ; 2815  total (11 * 256 - 1)

    bit SERIAL_IN_REG                   ; 4
    bpl start                           ; 3/2
    dex                                 ; 2 
    ASSERT_BRANCH_PAGE bne ,@wait       ; 3/2       
    ;   timeout
.endmacro

;==============================================================================
.macro INPUT_BYTE_FAST
;------------------------------------------------------------------------------
;   read data bits (speed optimized)
;   
;   input:
;       Y       #$7f
;   output:     
;       A       received byte
;   remarks:
;       - 129 cycles total
;       - no initial delay
;       - fast enough to process data at line speed 8N1
;------------------------------------------------------------------------------
    cpy SERIAL_IN_REG                   ; 4     lsb
    ror                                 ; 2
    DELAY11 
    cpy SERIAL_IN_REG                   ; 4
    ror                                 ; 2
    DELAY11 
    cpy SERIAL_IN_REG                   ; 4
    ror                                 ; 2
    DELAY12 
    cpy SERIAL_IN_REG                   ; 4
    ror                                 ; 2
    DELAY11 
    cpy SERIAL_IN_REG                   ; 4
    ror                                 ; 2
    DELAY11 
    cpy SERIAL_IN_REG                   ; 4
    ror                                 ; 2
    DELAY12 
    cpy SERIAL_IN_REG                   ; 4
    ror                                 ; 2
    DELAY11 
    cpy SERIAL_IN_REG                   ; 4     msb
    ror                                 ; 2
    eor #$FF                            ; 2     
.endmacro

;==============================================================================
.macro INPUT_BYTE_SHORT
;------------------------------------------------------------------------------
;   read data bits (space optimized)
;   
;   input:
;       Y       $7f
;
;   output:     
;       A       received byte
;       X       0
;       Y       $7f
;
;   remarks:
;       - 7 cycles initial delay
;       - 140 cycles total
;       
;   credits: 
;       - https://forum.6502.org/viewtopic.php?f=2&t=2063&start=45#p98249
;         (clever hack for efficient bit time tuning)
;------------------------------------------------------------------------------
.local @l1, @l2
    ;   initialization, 7 cycles
    ldx #$08                            ; 2     
    lda #%00100100                      ; 2     tuning bits
    bra @l2                             ; 3

    ;   data bit loop, 17 or 18 cycles per loop
@l1:
    nop                                 ; 2
    nop                                 ; 2
    bcs @l2                             ; 3/2   adjust bit time, controlled by tuning bits
@l2:        
    cpy SERIAL_IN_REG                   ; 4
    ror                                 ; 2
    dex                                 ; 2    
    ASSERT_BRANCH_PAGE bne, @l1         ; 3/2

    ;   post process data byte, 2 cycles
    eor #$FF                            ; 2     
;   total time 140 cycles    
.endmacro
