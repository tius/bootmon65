;   instruction_size.s
;
;   calculate the size of an instruction
;
;   to do:
;       - check results for x7 and xF
;       - check 6502.org for shorter code
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
instruction_size:
;------------------------------------------------------------------------------
;   input:
;       A       opcode
;   output
;       A       instruction size (1..3)
;   remarks:
;       - result valid for newer 65c02 with BBR, BBS, RMB and SMB instructions
;   see also:
;       - https://llx.com/Neil/a2/opcodes.html
;       - http://www.6502.org/tutorials/65c02opcodes.html
;------------------------------------------------------------------------------
    phx
    ldx #3
    eor #$0c
    bit #$0c
    beq @three              ; xC, xD, xE, xF

    ;   x0 .. xB
    eor #$08
    bit #$0c
    beq @two                ; x4, x5, x6, x7

    ;   x0 .. x3, x8 .. xF
    eor #$03   
    bit #$03
    beq @one                ; x3, xB

    ;   x0 .. x2, x8 .. xA
    bit #$08        
    beq @x0_2               ; x0 .. x2

    ;   x8 .. xA
    bit #$01        
    bne @one                ; x8, xA

    ;   x9
    bit #$10        
    beq @two                ; 09, 29, ..., e9
    bne @three              ; 19, 39, ..., f9

    ;   x0 .. x2
@x0_2:  
    eor #$03
    bit #$03
    bne @two                ; x1, x2

    ;   x0
    bit #$80        
    bne @two                ; 80, 90, .., F0

    ;   00, 10, ..., 70
    bit #$10        
    bne @two                ; 10, 30, 50, 70

    ;   00, 20, 40, 60
    cmp #$24
    beq @three              ; 20

    ;   00, 40, 60
@one:   
    dex
@two:   
    dex
@three: 
    txa
    plx
    rts

;------------------------------------------------------------------------------
