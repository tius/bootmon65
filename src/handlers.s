;   handlers.s
;
;   handler for hardware signals
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
.include "global.inc"
.include "config.inc"
.include "tinylib65.inc"

.code
;==============================================================================
res_handler:
;------------------------------------------------------------------------------
    ;   initialize hardware stack
    ldx #$ff                
    txs
    
    ;   initialize ports 
    lda #ORA_DEFAULT
    sta via1_ora                        ; avoid glitches by setting ora first
    lda #ORA_MASK           
    sta via1_ddra

    ;   enter monitor on enter key
    jsr print_inline_asciiz
    .byte $0d, $0a, .sprintf ("tiny65 %02d.%02d", VERSION_HI, VERSION_LO), $0d, $0a
    .byte "press spc for monitor", $00

    ldx #SERIAL_IN_TIMEOUT_2S
@wait:  
    jsr serial_in_char_timeout
    bcc @timeout  

    cmp #$20
    bne @wait

    jsr mon_init                        ; run monitor (init hooks for monitor calls)

@timeout: 
    jsr print_crlf
    jmp (res_hook)

;==============================================================================
irq_handler:                            ; cld is not required for 65c02
;------------------------------------------------------------------------------
    pha
    phx                                 ; do not save Y for minimal latency
    tsx                     
    lda $0103,x
    and #$10                            ; check pushed status byte for "B flag" 
    bne @brk
    jmp (irq_hook)
@brk:   
    jmp (brk_hook)

;==============================================================================
nmi_handler:
;------------------------------------------------------------------------------
    jmp (nmi_hook)
