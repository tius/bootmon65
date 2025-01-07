;   serial_in.s
;
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
.include "config.inc"
.include "utils.inc"

;------------------------------------------------------------------------------
.if SERIAL_IN_PORT_PIN = 7
    .out "using optimized code for port pin 7"
.else
    .error "SERIAL_IN_PORT_PIN must be 7"
.endif

;==============================================================================
.zeropage
;------------------------------------------------------------------------------
serial_in_echo:     .res 1

.code
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

;==============================================================================
serial_in_line:
;------------------------------------------------------------------------------
;   read line with optional echo (blocking)
;   
;   changed:
;       X, Y
;   output:     
;       input_idx        0  
;       input_buffer     input data (zero terminated)
;
;   remarks:
;       - read character data until cr or buffer is full (128 bytes + null byte)
;       - backspace removes last character from buffer (if any)
;       - does not work at wire speed if echo is enabled (half-duplex)
;------------------------------------------------------------------------------
    lda serial_in_echo
    beq serial_in_line_no_echo
    ldx #0                      
@loop:
    jsr serial_in_char
    
    cmp #$7f
    bcs @loop                

    cmp #$20
    bcs @printable

    cmp #$0d                    
    beq @done

    cmp #$08                    
    beq @backspace

    bra @loop

@backspace:
    cpx #0
    beq @loop
    jsr serial_out_char       
    jsr print_space
    lda #$08
    jsr serial_out_char       
    dex      
    bra @loop               

@printable:    
    sta input_buffer, x   
    jsr serial_out_char       
    inx      
    bpl @loop

@done:
    stz input_buffer, x
    stz input_idx
    jmp print_cr

;==============================================================================
serial_in_line_no_echo:
;------------------------------------------------------------------------------
;   read line without echo at wire speed (blocking)
;   
;   changed:
;       X, Y
;   output:     
;       input_idx        0 
;       input_buffer     input data (zero terminated)
;
;   remarks:
;       - read character until cr or buffer is full (128 bytes + null byte)
;       - backspace removes last character from buffer (if any)
;       - terminal local echo should be enabled 
;------------------------------------------------------------------------------
    ASSERT_SAME_PAGE input_buffer, input_buffer + 127

    ldy #$7f                            ; 2
    ldx #0                              ; 2

 @l0:    
;   wait for start bit, 6 cycles + 7 cycles jitter
    WAIT_BLOCKING                       ; 6 + 7 cycles jitter

;------------------------------------------------------------------------------
;   remark: INPUT_BYTE_SHORT would be too slow here

.if 0
;       26.5    cycles required until next sampling
;   -    6      delay by WAIT_BLOCKING
;   -    3.5    jitter / 2 by WAIT_BLOCKING
;   -    7      initial delay by INPUT_BYTE_SHORT
;   =   10      cycles needed until INPUT_BYTE_SHORT

    DELAY7                              ; 7
    phx                                 ; 3
    INPUT_BYTE_SHORT                    ; 140 (7 initial delay)
    plx                                 ; 4
                                        ; 154 cycles total
.endif    
;------------------------------------------------------------------------------
;   remark: we need to use INPUT_BYTE_FAST here for a loop time <= 170 cycles

;       26.5    cycles required until next sampling
;   -    6      delay by WAIT_BLOCKING
;   -    3.5    jitter / 2 by WAIT_BLOCKING
;   =   17      cycles needed until INPUT_BYTE_FAST

    DELAY17                             ; 17
    INPUT_BYTE_FAST                     ; 129 (no initial delay)
                                        ; 146 cycles total        

;   process backspace   
    cmp #$08                            ; 2
    beq @backspace                      ; 3/2

;   process cr  
    cmp #$0d                            ; 2
    beq @done                           ; 3/2

;   store character     
    sta input_buffer, x                 ; 5
@l1:    
    inx                                 ; 2  
    ASSERT_BRANCH_PAGE bpl, @l0         ; 3/2
;   170 cycles total 

@done:
    stz input_buffer, x
    stz input_idx
    rts

@backspace:        
    dex                                 ; 2
    bpl @l0                             ; 3/2
;   162 cycle total (+1 for page crossing is ok)   

    bra @l1                             ; 3
;   169 cycles total (+1 for page crossing is ok)   

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

;==============================================================================
.if FEAT_XMODEM

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
    sta input_buffer - 1, x             ; 5/6   (may cross page boundary)
    cpx #132                            ; 2
    ASSERT_BRANCH_PAGE bcc ,@loop       ; 3/2

;   total loop time 169/170 cycles

@done:    
    ply
    lda tmp0
    rts

.endif

;==============================================================================
.if 0

serial_in_block:
;------------------------------------------------------------------------------
;   read block of 1..256 bytes at wire speed, timeout 0.72 s per byte
;
;   input:
;       tmp0        target address low byte
;       tmp1        target address high byte
;       tmp2        no. of bytes to read
;
;   changed:
;       X, Y, tmp2
;
;   output:
;       C           1: ok, 0: timeout
;       Y           no. of bytes received - 1
;
;------------------------------------------------------------------------------
    ldy #$ff                            ; y is incremented at start of loop
    dec tmp2                            ; y is compared before increment

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
    sta (tmp0), y                       ; 6

    cpy tmp2                            ; 3
    ASSERT_BRANCH_PAGE bne, @loop       ; 3/2
                                        ; 170   total loop time
;   C = 1
    rts                                  

.endif

