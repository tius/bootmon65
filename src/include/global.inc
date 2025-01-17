;   global.inc

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

;------------------------------------------------------------------------------
;   extended opcodes
;------------------------------------------------------------------------------
.macro      xmem bank
    .byte bank << 4 | 3
.endmacro

;------------------------------------------------------------------------------
;   data.s
;------------------------------------------------------------------------------
.global     res_hook, res_hookl, res_hookh
.global     irq_hook, irq_hookl, irq_hookh
.global     brk_hook, brk_hookl, brk_hookh
.global     nmi_hook, nmi_hookl, nmi_hookh
.global     mon_hook, mon_hookl, mon_hookh

;------------------------------------------------------------------------------
;   handler.s

.global     res_handler
.global     irq_handler
.global     nmi_handler

;------------------------------------------------------------------------------
;   mon.s
;------------------------------------------------------------------------------
.globalzp   mon_pc, mon_pcl, mon_pch
.globalzp   mon_s, mon_a, mon_x, mon_y, mon_sp    

.global     mon_init
.global     mon_call
.global     mon_hlp
.global     mon_err
.global     mon_print_prefix

;------------------------------------------------------------------------------
