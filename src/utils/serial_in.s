;   serial_in.s
;
;   bit-bang 57600 baud software serial input
;
;   config:
;       SERIAL_IN_REG               input register
;       SERIAL_IN_PORT_PIN          port pin (must be 7)
;
;   requirements:
;       - port pin must initialized to input
;       - timing requires input on bit 7
;
;   remarks:
;       - half-duplex only
;       - correct bit time is 17.36 cycles, tight timing required
;       - tuned sampling timing 26.5/17/17/18/17/17/18/17 for reliable rx
;       - large jitter by start bit detection, 
;         7 cycles (without timeout) or 11 cycles (with timeout)
;       - substract jitter/2 from start-bit delay (26.5)
;       - branches must not cross pages for correct timing 
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
    bit SERIAL_IN_REG                    ; 4
    ASSERT_BRANCH_PAGE bmi ,@wait   ; 3/2
.endmacro

;==============================================================================
.macro WAIT_TIMEOUT start
;------------------------------------------------------------------------------
;   wait for start bit with timeout
;   7 cycles + 11 cycles jitter
;
;   input:
;       X/Y     timeout h, l (~2.8 ms per inner loop)
;   output:
;       X/Y     remaining time (Z=0) or 0 on timeout (Z=1)
;------------------------------------------------------------------------------
.local @wait
@wait:    
    bit SERIAL_IN_REG               ; 4
    ASSERT_BRANCH_PAGE bpl ,start          ; 3/2
    dec                             ; 2
    bne @wait                       ; 3/2       

    bit SERIAL_IN_REG               ; 4
    bpl start                       ; 3/2
    dey                             ; 2 
    bne @wait                       ; 3/2       

    bit SERIAL_IN_REG               ; 4
    bpl start                       ; 3/2
    dex                             ; 2 
    ASSERT_BRANCH_PAGE bne ,@wait          ; 3/2       
    ;   timeout
.endmacro

;==============================================================================
.macro input_BYTE_FAST
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
    cpy SERIAL_IN_REG               ; 4     lsb
    ror                             ; 2
    DELAY11
    cpy SERIAL_IN_REG               ; 4
    ror                             ; 2
    DELAY11
    cpy SERIAL_IN_REG               ; 4
    ror                             ; 2
    DELAY12
    cpy SERIAL_IN_REG               ; 4
    ror                             ; 2
    DELAY11
    cpy SERIAL_IN_REG               ; 4
    ror                             ; 2
    DELAY11
    cpy SERIAL_IN_REG               ; 4
    ror                             ; 2
    DELAY12
    cpy SERIAL_IN_REG               ; 4
    ror                             ; 2
    DELAY11
    cpy SERIAL_IN_REG               ; 4     msb
    ror                             ; 2
    eor #$FF                        ; 2     
.endmacro

;==============================================================================
.macro input_BYTE_SHORT
;------------------------------------------------------------------------------
;   read data bits (space optimized)
;   
;   input:
;       Y       #$7f
;   changes:
;       X
;   output:     
;       A       received byte
;   remarks:
;       - 140 cycles total
;       - 7 cycles initial delay
;       - too slow to process data at line speed 8N1
;   credits: 
;       - https://forum.6502.org/viewtopic.php?f=2&t=2063&start=45#p98249
;         (clever hack for efficient bit time tuning)
;------------------------------------------------------------------------------
.local @l1, @l2
    ldx #$08                        ; 2     
    lda #%00100100                  ; 2     tuning bits
    bra @l2                         ; 3

    ;   data bit loop, 17 or 18 cycles per loop
@l1:
    nop                             ; 2
    nop                             ; 2
    bcs @l2                         ; 3/2   adjust bit time, controlled by tuning bits
@l2:    
    cpy SERIAL_IN_REG               ; 4
    ror                             ; 2
    dex                             ; 2    
    ASSERT_BRANCH_PAGE bne, @l1            ; 3/2

    ;   post process data byte, 2 cycles
    eor #$FF                        ; 2     
;   total time 141 cycles    
.endmacro

;==============================================================================
serial_in_line:
;------------------------------------------------------------------------------
;   read line with echo (blocking)
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
;       - does not work at wire speed (half-duplex)
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
;       - 170 cycles total processing time per byte max.
;       - nominial byte time is 173.6 cycles
;       - this allows up to 2.1% baud rate tolerance
;------------------------------------------------------------------------------
    ASSERT_SAME_PAGE input_buffer, input_buffer + 127

    ldy #$7f                        ; 2
    ldx #0                          ; 2

 @l0:    
;   wait for start bit, 6 cycles + 7 cycles jitter
    WAIT_BLOCKING                   ; 6

;   jitter is 7 cycles, so we need 23 - 6 = 17 cycles delay here
    DELAY17                         ; 17
    input_BYTE_FAST                 ; 129 (no initial delay)

;   process backspace 
    cmp #$08                        ; 2
    beq @backspace                  ; 3/2

;   process cr
    cmp #$0d                        ; 2
    beq @done                       ; 3/2
    
;   store character    
    sta input_buffer, x             ; 5
@l1:
    inx                             ; 2  
    ASSERT_BRANCH_PAGE bpl, @l0     ; 3/2
;   170 cycles total 

@done:
    stz input_buffer, x
    stz input_idx
    rts

@backspace:        
    dex                             ; 2
    bpl @l0                         ; 3/2
;   162 cycle total (+1 for page crossing)   

    bra @l1                         ; 3
;   169 cycles total (+1 for page crossing)   

;==============================================================================
serial_in_char_timeout:
;------------------------------------------------------------------------------
;   receive one byte with timeout
;
;   input:
;       X       timeout value
;   changed:
;       Y
;   output (success):     
;       A       received byte 
;       X       remaining timeout value
;       C       1
;   output (timeout):     
;       A       0
;       X       0
;       C       0
;   remarks:
;       - too slow to process data at line speed 8n1 
;------------------------------------------------------------------------------
    WAIT_TIMEOUT @startbit          ; 7 (+ 11 cycles jitter)
    clc                             ; timeout
    rts                         

@startbit:    
;   jitter is 11 cycles, so we need 21 - 7 = 14 cycles delay here
    phx                             ; 3
    ldy #$7f                        ; 2
    DELAY2                          ; 2
    input_BYTE_SHORT                ; 140 (7 initial delay)
    plx                         
    sec                             ; ok
    rts

;==============================================================================
serial_in_char:
;------------------------------------------------------------------------------
;   receive one byte (blocking)
;   output:     
;       A       received byte
;
;   remarks:
;       - total time is 164 cycles including jsr/rts
;       - should be fast enough for simple interactive applications  
;       - this is too slow to process data at line speed 8n1 however 
;------------------------------------------------------------------------------
    WAIT_BLOCKING                   ; 6 (+ 7 cycles jitter)
    ;   jitter is 7 cycles, so we need 23 - 6 = 17 cycles delay now
    phy                             ; 3
    phx                             ; 3
    ldy #$7f                        ; 2
    DELAY2                          ; 2
    input_BYTE_SHORT                ; 140 (7 initial delay)
    plx
    ply
    rts

;==============================================================================
.if FEAT_XMODEM

serial_in_xmodem:
;------------------------------------------------------------------------------
;   read 132 byte xmodem block with timeout
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
    ldx #SERIAL_IN_TIMEOUT_10S      ; initial timeout 10s
    ;   make sure
    ASSERT_SAME_PAGE input_buffer, input_buffer+131

    SKIP2                               ; skip next 2-byte instruction

@loop:    
    ldx #1                          ; 2     byte timeout 0.4s (with Y = 127)
    WAIT_TIMEOUT @startbit          ; 7 (+ 11 cycles jitter)
    clc                             ; timeout                                      
    bra @done

@startbit:
;   jitter is 11 cycles, so we need 21-7=14 cycles delay now
   
;   read data byte using input_BYTE_FAST with relaxed timing
.if 0
;   make sure
    ASSERT_SAME_PAGE input_buffer-1, input_buffer+131

    ldy #$7f                        ; 2
    ldx tmp0                        ; 3
    inc tmp0                        ; 5

    DELAY4
    input_BYTE_FAST                 ; 129 (no initial delay)

    sta input_buffer, x             ; 5
    cpx #131                        ; 2
    ASSERT_BRANCH_PAGE bcc ,@loop          ; 3/2
;   162 cycles total byte time   
.endif

;   read data byte using input_BYTE_SHORT requires tight timing
.if 1
    ldy #$7f                        ; 2
    inc tmp0                        ; 5
    input_BYTE_SHORT                ; 140 (7 initial delay)

    ldx tmp0                        ; 3
    sta input_buffer - 1, x         ; 5
    cpx #132                        ; 2
    ASSERT_BRANCH_PAGE bcc ,@loop          ; 3/2
;   169 cycles total byte time   
.endif

@done:    
    ply
    lda tmp0
    rts

.endif
;------------------------------------------------------------------------------
