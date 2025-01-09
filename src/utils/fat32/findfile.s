;   fat32/findfile.s
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
fat32_findfile:                         ; ( filename )        
;------------------------------------------------------------------------------
;   find file by name
;
;   requirements:
;   - fat32_openrootdir or fat32_open for a subdir
;
;   output:   
;       C       1: success, 0: not found
;------------------------------------------------------------------------------
@loop:
    ;   read next directory entry
    jsr fat32_readdir
    bcc @done                           ; no more files

    ;   compare filename (11 bytes)
    jsr x_dup16                     
    X_PUSH_MEM16 fat32_dirent
    X_PUSH 11
    jsr x_cmp_size8
    bne @loop
    sec                                 ; found

@done:  
    X_DROP16                            ; drop filename
    rts

