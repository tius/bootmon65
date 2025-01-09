;   xmem.s
;
;   extendend memory access (xmem)
;
;   description:
;       - the 65c02 instruction set is extended by external logic to support 
;         a larger address space of 512k
;
;       - additional opcodes (xop) are used to set the high address bits 
;         A16..18 for the operand of the next instruction
;
;       - opcodes $03..$73 select bank 0..7 (default bank is 7)
;
;       - the xmem functions below use self-modifying code within the zeropage
;
;   credits:
;       - the idea for the xmem logic is based on the work of some very 
;         clever people at the 6502.org forum
;
;   see also:
;       - http://6502.org/tutorials/65c02opcodes.html
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
.include "global.inc"
.include "utils.inc"

.code
;==============================================================================
xmem_init:
;------------------------------------------------------------------------------
;   initialize smc in zeropage
;
;   input:
;       A
;   side effects:
;       xmem_op     A
;       xmem_rts    $60 (rts)
;------------------------------------------------------------------------------
    lda #$ea                ; nop
    sta xmem_access
    lda #$60                ; rts
    sta xmem_rts
    rts    

;==============================================================================
xmem_set:
;------------------------------------------------------------------------------
;   set xmem bank
;
;   input:
;       A           bank 0..7
;   side effects:
;       xmem_access $03 .. $73
;------------------------------------------------------------------------------
    asl
    asl
    asl
    asl
    ora #03
    SKIP2                               ; skip next 2-byte instruction

;==============================================================================
xmem_clr:
;------------------------------------------------------------------------------
;   clear xmem bank
;
;   side effects:
;       xmem_access $EA
;------------------------------------------------------------------------------
    lda #$ea                            ; nop
    sta xmem_access
    rts

;==============================================================================
