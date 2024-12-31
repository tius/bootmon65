;   utils_zp.s
;
;   zero page locations used by the utility functions
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

.zeropage
;------------------------------------------------------------------------------
;   scratchpad
;   - caller saved
;   - assume that data may be overwritten by every function (!)
;   - may be used across functions within the same module if documented
;------------------------------------------------------------------------------
tmp:
tmp0:           .res 1                  
tmp1:           .res 1
tmp2:           .res 1
tmp3:           .res 1
tmp4:           .res 1
tmp5:           .res 1
tmp6:           .res 1
tmp7:           .res 1

;==============================================================================
;   zeropage registers
;   - callee saved
;   - may be used only for parameters and return values if documented
;------------------------------------------------------------------------------
.if FEAT_XMEM

;   smc wrapper for xmem access via w0 (see xmem.s)
xmem_access:    .res 1                  ; $ea (nop), $03, $13, ... $73 (xmem)
xmem_op:        .res 1                  ; $ad (lda abs), $8d (sta abs), ...

.endif
;------------------------------------------------------------------------------
;   generic 16 bit value

w0:                                     
w0l:            .res 1                  
w0h:            .res 1

;------------------------------------------------------------------------------
.if FEAT_XMEM

;   end of smc wrapper
xmem_rts:       .res 1                  ; $60 (rts)

.endif
;------------------------------------------------------------------------------
;   generic 16 bit value

w1:                                     
w1l:            .res 1
w1h:            .res 1

;==============================================================================
;   return values
;------------------------------------------------------------------------------
last_error:     .res 1                  ; last error code
