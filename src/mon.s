;   mon.s
;
;   minimal cbm-style monitor program
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

;==============================================================================
.zeropage
;------------------------------------------------------------------------------
;   register values

mon_pc:
mon_pcl:        .res 1
mon_pch:        .res 1

mon_s:          .res 1
mon_a:          .res 1
mon_x:          .res 1
mon_y:          .res 1
mon_sp:         .res 1

.code
;==============================================================================
mon_init:

;   initialize hooks and start monitor
;------------------------------------------------------------------------------
.rodata
@hooks: 
    .word mon_irq, mon_brk, mon_nmi, mon_hlp
@hooks_end:

.code        
    COPY_USING_X irq_hook, @hooks, @hooks_end - @hooks

;==============================================================================
mon_call:

;   enter monitor via call - PC-1 on stack
;------------------------------------------------------------------------------
    php
    pha
    phx
    lda #'c'
    bra _save

;==============================================================================
mon_nmi:

;   enter monitor via nmi hook - PC, S on stack
;------------------------------------------------------------------------------
    pha
    phx
    lda #'n'
    SKIP2                               ; skip next 2-byte instruction

;==============================================================================
mon_irq:

;   enter monitor via irq hook - PC, S, A, X on stack
;------------------------------------------------------------------------------
    lda #'i'
    SKIP2                               ; skip next 2-byte instruction

;==============================================================================
mon_brk:

;   enter monitor via break hook - PC+1, S, A, X on stack
;------------------------------------------------------------------------------
    lda #'b'

;------------------------------------------------------------------------------
_save:
    sta tmp1                        ; save signature character
   
    sty mon_y                     
    pla
    sta mon_x                     
    pla
    sta mon_a                     
    pla
    sta mon_s                     
    pla                             
    sta mon_pcl             
    pla
    sta mon_pch
    tsx
    stx mon_sp

    ;   pc++ for call entry
    ldx tmp1 
    cpx #'c'                
    bne @l0
    INC16 mon_pc
    
    ;   pc-- for brk entry
@l0:    
    cpx #'b'                
    bne @l1
    DEC16 mon_pc

    ;   print welcome message with signature character in x
@l1:    
    jsr print_crlf
    txa
    jsr print_char                  ; print signature character
    lda #'*'
    jsr print_char
    jsr print_crlf
    jsr cmd_r_dspl

;------------------------------------------------------------------------------
@prompt:
    lda #'.'
    jsr print_char
    jsr input_read
    jsr print_crlf

@read:  
;   read command, skip '.' and ' '
    jsr input_char
    bcc @prompt
    cmp #'.'                    
    beq @read
    cmp #' '
    beq @read
    jsr _dispatch
    bra @prompt

;==============================================================================    
_dispatch:    

;   lookup command character and run command subroutine
;------------------------------------------------------------------------------
    ldx #@cmd_chars_end - @cmd_chars - 1
@loop:  
    cmp @cmd_chars,x
    bne @next
    txa                         
    asl
    tax
    jmp (@cmd_addr, x)
@next:  
    dex
    bpl @loop
    jmp (mon_hook)              ; hook for unknown commands

;------------------------------------------------------------------------------
;   command dispatch table

.rodata
@cmd_addr:        
    .word cmd_e, cmd_r, cmd_v, cmd_g, cmd_m, cmd_colon, cmd_c

    .if FEAT_OPSIZE
        .word cmd_i
    .endif    
    .if FEAT_XMEM
        .word cmd_x
    .endif    
    .if FEAT_XMODEM
        .word cmd_u, cmd_d
    .endif    
    .if FEAT_SD
        .word cmd_l
    .endif    
    .if FEAT_TEST_SD || FEAT_TEST_FAT32
        .word cmt_t
    .endif    

@cmd_chars:       
        .byte "ervgm:c"
    .if FEAT_OPSIZE
        .byte "i"
    .endif    
    .if FEAT_XMEM
        .byte "x"
    .endif    
    .if FEAT_XMODEM
        .byte "ud"
    .endif    
    .if FEAT_SD
        .byte "l"
    .endif    
    .if FEAT_TEST_SD || FEAT_TEST_FAT32
        .byte "t"
    .endif    

@cmd_chars_end:    
.code

;==============================================================================    
mon_hlp:     
;------------------------------------------------------------------------------
.if FEAT_HELP
    jsr print_inline_asciiz
    .byte "e [0|1]", $0d, $0a
    .byte "r [pc ..]", $0d, $0a
    .byte "v [res ..]", $0d, $0a
    .byte "g [addr]", $0d, $0a
    .byte "m [addr [addr]]", $0d, $0a
    .byte ": addr dd ..", $0d, $0a
    .byte "c addr addr [dd]", $0d, $0a
.if FEAT_OPSIZE
    .byte "i [addr]", $0d, $0a
.endif    
.if FEAT_XMEM
    .byte "x <0..7>", $0d, $0a
.endif    
.if FEAT_XMODEM
    .byte "u addr", $0d, $0a
    .byte "d addr addr", $0d, $0a
.endif    
.if FEAT_SD
    .byte "l [xx addr]", $0d, $0a
.endif    
.if FEAT_TEST_SD || FEAT_TEST_FAT32
    .byte "t [n]", $0d, $0a
.endif
    .byte $00
    rts

.endif    

;==============================================================================    
mon_err:     
;------------------------------------------------------------------------------
lda #'?'
    jsr print_char
    jmp print_crlf

;==============================================================================
cmd_m:

;   display memory data
;------------------------------------------------------------------------------
    ;   enter 1st address, default to last used address
    jsr input_hex16_w0
    bcc @default_cnt       

    ;   enter 2nd address
    jsr input_hex16_ay
    bcc @default_cnt                    ; default to 64 bytes

    ;   calculate size, 256 bytes max.
    INCAY
    sbc w0l
    tax                                 ; no. of bytes to show
    tya
    sbc w0h
    beq @loop
   
    ldx #0                              ; limit to 256 bytes 
    SKIP2                               ; skip next 2-byte instruction

@default_cnt:    
    ldx #$40                            ; default to 64 bytes

@loop: 
    txa
    beq @go_on                          ; edge case 256 bytes
    cmp #9
    bcc @rest

@go_on:    
    sbc #8
    tax

    lda #8
    .if FEAT_XMEM
        jsr _xmem_print_row
    .else
        jsr print_mem_row
    .endif
    bra @loop

@rest:
    .if FEAT_XMEM
        jmp _xmem_print_row
    .else
        jmp print_mem_row
    .endif

;==============================================================================
.if FEAT_XMODEM
cmd_u:
;   xmodem upload
;------------------------------------------------------------------------------
    jsr input_hex16_w0
    bcc mon_err
    jsr xmodem_receive
    jsr print_hex8          ; no. of blocks received
    jmp print_crlf

;==============================================================================
cmd_d:
;   xmodem download
;------------------------------------------------------------------------------
    jsr input_hex16_w0
    bcc mon_err
    jsr input_hex16_ay
    bcc mon_err
    STAY w1
    jsr xmodem_send
    bcc _jmp_err
    rts

.endif

;==============================================================================
.if FEAT_OPSIZE
cmd_i:
;   dump opcodes
;------------------------------------------------------------------------------
    ;   enter address, default to last address
    jsr input_hex16_w0
    bcc @no_addr
@no_addr:  

    ldy #$10                ; list 10 instuctions
@loop:  
    lda (w0)
    jsr instruction_size
    jsr print_mem_row
    dey
    bne @loop

    rts    

.endif    

;==============================================================================
cmd_c:
;   clear memory
;------------------------------------------------------------------------------
.if FEAT_XMEM
    lda #$8d                            ; sta <abs>
    sta xmem_op
.endif         

    jsr input_hex16_w0                  ; start address    
    bcc _jmp_err
    jsr input_hex16_ay                  ; end address
    bcc _jmp_err
    tax
    jsr input_hex                       ; fill byte (defaults to 0)

@loop:  

.if FEAT_XMEM
    jsr xmem_access
.else    
    sta (w0)
.endif

    jsr inc_w0
    cpy w0h
    bne @l1
    cpx w0l
@l1:    
    bcs @loop
    rts

;==============================================================================
cmd_colon:
;   enter memory data
;------------------------------------------------------------------------------
    jsr input_hex16_w0
    bcc _jmp_err
    ldx #0

;==============================================================================
_enter_data:     
;------------------------------------------------------------------------------
.if FEAT_XMEM
    lda #$8d                            ; sta <abs>
    sta xmem_op
.endif        

    jsr input_hex
    bcc _done

.if FEAT_XMEM
    jsr xmem_access
.else    
    sta (w0)
.endif
    jsr inc_w0
    dex
    bne _enter_data
_done:    
    rts

_jmp_err:     
    jmp mon_err
      
;==============================================================================
cmd_r:
;   display and edit registers
;------------------------------------------------------------------------------
    jsr _input_pc
    bcc cmd_r_dspl
    jsr input_bin8
    bcc _done
    sta mon_s
    jsr _load_w0_and_a_for_regs
    tax
    jsr _enter_data

cmd_r_dspl:    
    ;   print header and prefix
    jsr print_inline_asciiz
    .byte "   pc  nv-bdizc ac xr yr sp", $0d, $0a, $00
    lda #'r'
    jsr print_char_space

    ;   print pc
    lda mon_pch
    jsr print_hex8
    lda mon_pcl
    jsr print_hex8
    jsr print_space

    ;   print flags
    lda mon_s
    jsr print_bin8

    ;   print register values
    jsr _load_w0_and_a_for_regs
    jmp print_hex_bytes_crlf
        
;==============================================================================
cmd_v:
;   display and edit hook vector table
;------------------------------------------------------------------------------
;   enter max. 5 hook addresses

    ldx #0
@l0:    
    jsr input_hex16_ay
    bcc @dspl
    sta res_hookl, x
    tya
    sta res_hookh, x
    inx
    inx
    cpx #$0a
    bcc @l0

;------------------------------------------------------------------------------
;   print hooks

@dspl:
    jsr print_inline_asciiz
    .byte "  res  irq  brk  nmi  mon ", $0d, $0a, $00
    lda #'v'
    jsr print_char

    ldy #0
@l1:    
    jsr print_space
    lda res_hookh, y
    jsr print_hex8
    lda res_hookl, y
    jsr print_hex8
    iny
    iny
    cpy #$0a
    bne @l1
    jmp print_crlf

;==============================================================================
cmd_g:
;   execute program
;------------------------------------------------------------------------------
    jsr _input_pc

    ldx mon_sp
    txs
    sei
    lda mon_pch
    pha
    lda mon_pcl
    pha
    lda mon_s
    pha
    lda mon_a
    ldx mon_x
    ldy mon_y
    rti

;==============================================================================
cmd_e:
;   switch echo
;------------------------------------------------------------------------------
    jsr input_hex
    bcc @dspl
    sta serial_in_echo

@dspl:  
    lda #'e'
    jsr print_char_space
    lda serial_in_echo
    jsr print_hex8
    jmp print_crlf    

;==============================================================================
.if FEAT_XMEM

cmd_x:
;   set xmem bank 
;------------------------------------------------------------------------------
    jsr input_hex                   
    bcc @clr
    jmp xmem_set
@clr:
    jmp xmem_clr
   
;==============================================================================
_xmem_print_row:
;------------------------------------------------------------------------------
;   print xmem data separated by space
;
;   input:
;       A       no. of bytes to print
;       w0      start address
;   output:
;       w0      end address + 1
;------------------------------------------------------------------------------
    phx
    tax

    lda #':'
    jsr print_char
    jsr print_space
    jsr print_hex16_w0

    lda #$ad                ; lda abs
    sta xmem_op

@loop:     
    jsr print_space
    jsr xmem_access
    jsr print_hex8
    jsr inc_w0

    dex
    bne @loop

    plx
    jmp print_crlf
    
.endif    
;==============================================================================
.if FEAT_SD
cmd_l:
;   sd card list and load 
;------------------------------------------------------------------------------
    jsr input_hex                       ; file index
    beq @dir
    tay
    jsr input_hex16_ay                  ; load address
    bcc @dir
    
;------------------------------------------------------------------------------
;   load file

    pha                                 
    phy 

    ldx #STACK_INIT
    jsr fat32_init
    bcc @error

    pla
    X_PUSH_A                             
    pla
    X_PUSH_A
    jsr fat32_openrootdir
    
@skip_file:    
    jsr fat32_readdir
    bcc @error
    dey
    bne @skip_file
    jsr fat32_print_dirent
    jsr fat32_open
    jsr fat32_loadfile
    bcs @done

@error:    
    jmp mon_err

;------------------------------------------------------------------------------
;   print directory

@dir:
    ldx #STACK_INIT
    jsr fat32_init
    bcc @error

    jsr fat32_openrootdir
    ldy #1                              ; file index (0 = volume label)
@next_file:    
    jsr fat32_readdir
    bcc @done
    tya
    jsr print_hex8
    jsr print_space
    jsr fat32_print_dirent
    iny
    bne @next_file
@done:
    rts

;------------------------------------------------------------------------------
@init_error:
    jmp mon_err

.endif    

;==============================================================================
.if FEAT_TEST_SD || FEAT_TEST_FAT32

cmt_t:
    jsr input_hex
    asl
    tax                                 
    cpx #@table_end - @table
    bcs @test_error
    jmp (@table, x)                     ; jump to specified test routine  
.endif

@test_error:
    jmp mon_err

@table:
.if FEAT_TEST_SD
    .word test_sd
.endif
.if FEAT_TEST_FAT32
    .word test_fat32
.endif
@table_end:

;==============================================================================
_input_pc:
;   enter pc value
;------------------------------------------------------------------------------
    jsr input_hex16_ay
    bcc @empty
    sta mon_pcl
    sty mon_pch
@empty: 
    rts

;==============================================================================
_load_w0_and_a_for_regs:
;   set w0 and a for register access a .. sp
;------------------------------------------------------------------------------
    lda #< (mon_a)
    sta w0l
    lda #> (mon_a)
    sta w0h
    lda #4
    rts 

