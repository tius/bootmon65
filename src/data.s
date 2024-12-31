;   data.s
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
.include "utils.inc"

.bss
;==============================================================================
;   fat32.s
;------------------------------------------------------------------------------
;   sector buffer, must be page aligned

fat32_buffer:   .res 512 

;==============================================================================
;   hooks for hardware vectors and monitor extensions
;------------------------------------------------------------------------------
res_hook:         
res_hookl:      .res 1      
res_hookh:      .res 1      

irq_hook:         
irq_hookl:      .res 1      
irq_hookh:      .res 1      

brk_hook:         
brk_hookl:      .res 1      
brk_hookh:      .res 1      

nmi_hook:         
nmi_hookl:      .res 1      
nmi_hookh:      .res 1      

mon_hook:       
mon_hookl:      .res 1      
mon_hookh:      .res 1      

;==============================================================================
;   serial_in and input
;------------------------------------------------------------------------------
input_buffer:   .res 132                ; must not cross page boundary
