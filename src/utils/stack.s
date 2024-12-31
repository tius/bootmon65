;   stack.s
;
;   software stack
;       - starts at $ff and grows downward within zeropage 
;
;   credits:
;       https://wilsonminesco.com/stacks/      
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
x_push32_0:                            ; ( -- $0000 $0000 )
    jsr x_push16_0

;==============================================================================
x_push16_0:                            ; ( -- $0000 )
;------------------------------------------------------------------------------
    dex
    stz stack,x
    dex
    stz stack,x
    rts

;==============================================================================
x_dup16:                                ; ( w -- w w )
;------------------------------------------------------------------------------
    dex
    dex
    lda stack + 2, x
    sta stack, x
    lda stack + 3, x
    sta stack + 1, x
    rts

;==============================================================================
x_swap16:                               ; ( w1 w2 -- w2 w1 )
;------------------------------------------------------------------------------
    phy
    lda  0 + stack, x 
    ldy  2 + stack, x
    sta  2 + stack, x
    sty  0 + stack, x

    lda  1 + stack, x
    ldy  3 + stack, x
    sta  3 + stack, x
    sty  1 + stack, x
    ply
    rts

;==============================================================================
x_rot16:                                ; ( w1 w2 w3 -- w2 w3 w1 )
;------------------------------------------------------------------------------
    phy
    ldy  0 + stack, x        
    lda  4 + stack, x        
    sta  0 + stack, x
    lda  2 + stack, x  
    sta  4 + stack, x
    sty  2 + stack, x

    ldy  1 + stack, x
    lda  5 + stack, x
    sta  1 + stack, x
    lda  3 + stack, x
    sta  5 + stack, x
    sty  3 + stack, x    
    ply
    rts
   
;==============================================================================
x_push16_inline:                        ; ( -- literal16 )
;------------------------------------------------------------------------------
    pla
    sta tmp0
    pla
    sta tmp1

    dex
    dex

    INC16 tmp0
    lda (tmp0)                          ; lo byte first
    sta stack,x 

    INC16 tmp0
    lda (tmp0)                          ; hi byte
    sta stack + 1,x 

    lda tmp1
    pha
    lda tmp0
    pha
    rts        

;==============================================================================
x_dup32:                                ; ( dw -- dw dw )
;------------------------------------------------------------------------------
    dex
    dex
    dex
    dex
    lda stack + 4, x
    sta stack, x
    lda stack + 5, x
    sta stack + 1, x
    lda stack + 6, x
    sta stack + 2, x
    lda stack + 7, x
    sta stack + 3, x    
    rts
   
;=============================================================================
x_cmp_size8:                          ; ( addr1 addr2 size8 -- )
;------------------------------------------------------------------------------
;   compare two memory blocks with 8 bit size
;   - not speed optimized
;   - size 1 .. 256
;   
;   output:
;       Z           addr1[0..size-1] == addr2[0..size-1]
;       C           addr1[0..size-1] >= addr2[0..size-1]
;------------------------------------------------------------------------------
    phy
    ldy stack, x                        ; size8

@loop:
    lda (stack + 3, x)                  ; addr1
    sbc (stack + 1, x)                  ; addr2
    sta tmp0
    bne @done

    INC16 { stack + 1, x }
    INC16 { stack + 3, x }
    dey
    bne @loop

@done:
    inx                                 ; pop len
    inx                                 ; pop addr2
    inx
    inx                                 ; pop addr1
    inx
    ply
    lda tmp0
    rts
 
;==============================================================================
;   x_memcpy                            ( src dst size16 -- )
;   - not speed optimized
;   - ranges must not overlap unless dst < src
;------------------------------------------------------------------------------
_x_memcpy_loop:
    lda  (stack + 4, x)                 ; src
    sta  (stack + 2, x)                 ; dst

    INC16 { stack + 4, x }              ; src++
    INC16 { stack + 2, x }              ; dst++
    DEC16 { stack, x }                  ; size16--

x_memcpy:                               
    lda  stack, x        
    ora  stack + 1, x
    bne  _x_memcpy_loop

;==============================================================================
x_drop6:                                ; ( x x x x x x -- )
    inx
x_drop5:                                ; ( x x x x x -- )
    inx
x_drop4:                                ; ( x x x x -- )
    inx
    inx
    inx
    inx
    rts

;==============================================================================
x_dump_stack:                           ; ( -- )
;------------------------------------------------------------------------------
    phx
    phy

    lda #'>'
    jsr print_char

    ldy #(STACK_INIT - 1) & 255         ; start with first stack entry
@loop:
    cpx #STACK_INIT
    beq @done
    inx 
    jsr print_space
    lda stack, y
    jsr print_hex8
    dey
    bra @loop

@done:
    ply
    plx
    jmp print_crlf

;=============================================================================
x_print_size8:                          ; ( addr size8 -- )
;------------------------------------------------------------------------------
;   print string with 8 bit size         
;------------------------------------------------------------------------------
    phy
    ldy stack, x
    beq @done

@loop:
    lda (stack + 1, x)    
    jsr print_char
    INC16 { stack + 1, x }
    dey
    bne @loop

@done:
    inx                                 ; pop len
    inx                                 ; pop addr
    inx
    ply
    rts
