;   jmp_table.s
;
;   *** to be defined
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

.segment "JMPTABLE"
;==============================================================================
;   api version
;------------------------------------------------------------------------------
.byte VERSION_LO, VERSION_HI

;==============================================================================
;   jmp table
;------------------------------------------------------------------------------
jmp mon_call
jmp mon_hlp
jmp mon_err

jmp serial_out_char
jmp serial_in_char
jmp serial_in_char_timeout
jmp serial_in_line

jmp print_char
jmp print_hex4
jmp print_hex8
jmp print_hex16_w0
jmp print_hex16_ay
jmp print_bin8
jmp print_space
jmp print_cr
jmp print_lf
jmp print_crlf
jmp print_char_space
jmp print_inline_asciiz
jmp print_mem_row
jmp print_hex_bytes_crlf

jmp input_char
jmp input_hex
jmp input_hex16_ay
jmp input_hex16_w0
jmp input_bin8

jmp fat32_init
jmp fat32_openrootdir
jmp fat32_readdir
jmp fat32_findfile
jmp fat32_open
jmp fat32_loadfile
jmp fat32_print_dirent

jmp sd_init
jmp sd_read_sector

jmp xmodem_receive
jmp xmodem_send