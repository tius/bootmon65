;   macros_delay.inc
;
;   delay helper macros 
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

.macro DELAY1
    .byte $FB               ; 2 (65c02 only)
.endmacro

.macro DELAY2
    nop                     ; 2
.endmacro

.macro DELAY3
    bit tmp0                ; 3
.endmacro

.macro DELAY4
    nop                     ; 2
    nop                     ; 2
.endmacro

.macro DELAY5
    nop                     ; 2
    bit tmp0                ; 3
.endmacro

.macro DELAY6
    nop                     ; 2
    nop                     ; 2
    nop                     ; 2
.endmacro

.macro DELAY7
    php                     ; 3     
    plp                     ; 4
.endmacro

.macro DELAY8
    nop                     ; 2
    nop                     ; 2
    nop                     ; 2
    nop                     ; 2
.endmacro

.macro DELAY9
    php                     ; 3     
    plp                     ; 4
    nop                     ; 2
.endmacro

.macro DELAY10
    php                     ; 3     
    bit tmp0                ; 3
    plp                     ; 4
.endmacro

.macro DELAY11
    php                     ; 3     
    nop                     ; 2
    nop                     ; 2
    plp                     ; 4
.endmacro

.macro DELAY12
    jsr delay12
.endmacro

.macro DELAY13
    php                     ; 3     
    nop                     ; 2
    nop                     ; 2
    nop                     ; 2
    plp                     ; 4
.endmacro

.macro DELAY14
    jsr delay14
.endmacro

.macro DELAY15
    jsr delay15
.endmacro

.macro DELAY16
    jsr delay16
.endmacro

.macro DELAY17
    jsr delay17
.endmacro

.macro DELAY18
    jsr delay18
.endmacro

.macro DELAY19
    jsr delay19
.endmacro

.macro DELAY20
    jsr delay20
.endmacro
