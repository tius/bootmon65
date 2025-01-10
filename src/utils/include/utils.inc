;   utils.inc
;
;   some useful helper functions
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

;------------------------------------------------------------------------------
.include "macros/macros_16bit.inc"
.include "macros/macros_32bit.inc"
.include "macros/macros_align.inc"
.include "macros/macros_delay.inc"
.include "macros/macros_misc.inc"
.include "macros/macros_print.inc"
.include "macros/macros_skip.inc"
.include "macros/macros_stack.inc"

;==============================================================================
;   external symbols
;------------------------------------------------------------------------------
;   bss data

.global     input_buffer
.global     fat32_buffer

;------------------------------------------------------------------------------
;   hardware vector handlers

.global     res_handler
.global     irq_handler
.global     nmi_handler

;==============================================================================
;   modules
;------------------------------------------------------------------------------
;   data_zp.s

.globalzp   tmp0, tmp1, tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7
.globalzp   r0, r1, r2, r3, r4, r5, r6, r7
.globalzp   w0, w0l, w0h
.globalzp   w1, w1l, w1h
.globalzp   last_error
.globalzp   xmem_access
.globalzp   xmem_op
.globalzp   xmem_rts

;------------------------------------------------------------------------------
;   delay_cycles.s

.global delay12
.global delay14
.global delay15
.global delay16
.global delay17
.global delay18
.global delay19
.global delay20

;------------------------------------------------------------------------------
;   delay_ms.s

.global delay_ms

;------------------------------------------------------------------------------
;   fat32.s

FAT32_ERR_BASE      = $20
FAT32_ERR_MBR       = FAT32_ERR_BASE + 0
FAT32_ERR_PARTITION = FAT32_ERR_BASE + 1
FAT32_ERR_BPB       = FAT32_ERR_BASE + 2

.globalzp   fat32_dirent

.global     fat32_init
.global     fat32_openrootdir
.global     fat32_readdir
.global     fat32_findfile
.global     fat32_open
.global     fat32_loadfile
.global     fat32_print_dirent
.global     fat32_test

;------------------------------------------------------------------------------
;   input.s

.globalzp   input_idx
.global     input_char
.global     input_skip_spaces
.global     input_hex
.global     input_hex8
.global     input_hex16_ay
.global     input_hex16_w0
.global     input_bin8

;------------------------------------------------------------------------------
;   instruction_size.s

.global instruction_size

;------------------------------------------------------------------------------
;   misc.s

.global     inc_w0

;------------------------------------------------------------------------------
;   print.s

.global     print_hex4
.global     print_hex8
.global     print_hex16_w0
.global     print_hex16_ay
.global     print_bin8
.global     print_space
.global     print_cr
.global     print_lf
.global     print_crlf
.global     print_char_space
.global     print_inline_asciiz
.global     print_mem_row
.global     print_hex_bytes_crlf

;------------------------------------------------------------------------------
;   sd.s

SD_ERR_BASE         = $10
SD_ERR_CMD0         = SD_ERR_BASE + 0
SD_ERR_CMD8         = SD_ERR_BASE + 1
SD_ERR_CMD55        = SD_ERR_BASE + 2
SD_ERR_CMD41        = SD_ERR_BASE + 3
SD_ERR_CMD17        = SD_ERR_BASE + 4
SD_ERR_READ         = SD_ERR_BASE + 5

.global     sd_init
.global     sd_read_sector
.global     sd_test

;------------------------------------------------------------------------------
;   serial output

.global     serial_out_char

;------------------------------------------------------------------------------
;   serial input

SERIAL_IN_TIMEOUT_2S   := 3
SERIAL_IN_TIMEOUT_10S  := 14
SERIAL_IN_TIMEOUT_60S  := 83

.globalzp   serial_in_echo
.global     serial_in_char
.global     serial_in_line
.global     serial_in_xmodem
.global     serial_in_char_timeout

;------------------------------------------------------------------------------
;   x_stack.s

stack       = $00                       ; zeropage stack base address
STACK_INIT  = $00                       ; stack starts at $FF and grows downwards

.global     x_push16_0
.global     x_push32_0
.global     x_dup16
.global     x_swap16
.global     x_rot16
.global     x_dup32
.global     x_cmp_size8
.global     x_push16_inline
.global     x_memcpy
.global     x_drop4
.global     x_drop5
.global     x_drop6
.global     x_dump_stack
.global     x_print_size8
.global     x_memdump
.global     x_memdump_cols

;------------------------------------------------------------------------------
;   xmem.s
;------------------------------------------------------------------------------
.global     xmem_init
.global     xmem_set
.global     xmem_clr

;------------------------------------------------------------------------------
;   xmodem.s

.global     xmodem_receive
.global     xmodem_send
