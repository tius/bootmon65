;   fat32/fat32_test.s
;
;   test fat32 access
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
fat32_test:
;------------------------------------------------------------------------------
    ldx #STACK_INIT
    
    jsr fat32_init
    bcc @error
    
    jsr _x_test1
    jsr _x_test2
    rts

;------------------------------------------------------------------------------
@error:
    lda last_error
    jsr print_hex8
    jmp mon_err
  
;==============================================================================
_x_test1:
;------------------------------------------------------------------------------
;   - navigate to subdirectory 'subdir'
;   - print file 'three.txt'
;------------------------------------------------------------------------------
buffer = $2000

    jsr fat32_openrootdir

    ; Find subdirectory by name
    X_PUSH16 @subdirname
    jsr fat32_findfile
    bcc _subdir_not_found
    jsr fat32_print_dirent

    ; open subdirectory
    jsr fat32_open

    ; find file by name
    X_PUSH16 @filename
    jsr fat32_findfile
    bcc _file_not_found
    jsr fat32_print_dirent

    ; open file and read content into buffer
    jsr fat32_open
    X_PUSH16 buffer
    jsr fat32_loadfile
    bcc _load_error

    ; print data until 1st cr
    ldy #0
@printloop:
    lda buffer,y
    cmp #$0D
    beq @done
    jsr print_char
    iny
    bne @printloop

@done:    
    jmp print_crlf

;------------------------------------------------------------------------------
@subdirname:
    .asciiz "SUBDIR     "
@filename:
    .asciiz "THREE   TXT"

;==============================================================================
_subdir_not_found:
    jsr print_inline_asciiz
    .byte "subdir not found", $0d, $0a, $00
    rts

_file_not_found:
    jsr print_inline_asciiz
    .byte "file not found", $0d, $0a, $00
    rts

_load_error:
    jsr print_inline_asciiz
    .byte "load error", $0d, $0a, $00
    rts

;==============================================================================
_x_test2:
;------------------------------------------------------------------------------
;   - load file to memory
;   - ~37s for $e000 bytes (~1.5 kBytes/s)
;------------------------------------------------------------------------------
loadaddr = $0800

    jsr fat32_openrootdir

    ; find file by name
    X_PUSH16 @binname
    jsr fat32_findfile
    bcc _file_not_found
    jsr fat32_print_dirent

    ; open file and read content into memory at loadaddr
    jsr fat32_open
    X_PUSH16 loadaddr
    jmp fat32_loadfile

;------------------------------------------------------------------------------
@binname:
    .asciiz "0304    BIN"

;==============================================================================
