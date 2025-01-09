;   serial_in_line.s
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
.zeropage
;------------------------------------------------------------------------------
serial_in_echo:     .res 1

.code
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
