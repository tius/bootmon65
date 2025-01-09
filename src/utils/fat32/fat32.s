;   fat32.s
;
;   minimal fat32 read access
;
;   requirements:
;       - 512 byte page aligned sector buffer (fat32_buffer)
;       - 32 byte zeropage space (could be reduced)
;
;   remarks:
;       - all api functions expect x as stackpointer
;       - sector buffer and zeropage memory may be reused by other modules
;
;   to do:
;       - read file character by character
;       - reduce zeropage usage?
;
;   credits:
;       - https://github.com/gfoot/sdcard6502
;       - https://www.pjrc.com/tech/8051/ide/fat32.html
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

;------------------------------------------------------------------------------
ASSERT_ALIGNMENT fat32_buffer, 256

;------------------------------------------------------------------------------
;   master boot record offsets
MBR_PARTITION_TABLE = 446
MBR_TYPE_CODE       = MBR_PARTITION_TABLE + 4
MBR_LBA_BEGIN       = MBR_PARTITION_TABLE + 8
TYPE_CODE_FAT32     = 12

;   bios parameter block offsets
BPB_BYTSPERSEC	    = $0B               ; 2 bytes              
BPB_SECPERCLUS	    = $0D               ; 1 byte
BPB_RSVDSECCNT	    = $0E               ; 2 bytes
BPB_NUMFATS	        = $10               ; 1 byte
BPB_FATSZ32	        = $24               ; 4 bytes
BPB_ROOTCLUS	    = $2C               ; 4 bytes

;   directory entry offsets
DIR_NAME            = $00               ; 11 bytes
DIR_ATTR            = $0B               ; 1 byte
DIR_FSTCLUSHI	    = $14               ; 2 bytes 
DIR_FSTCLUSLO	    = $1A               ; 2 bytes
DIR_FILESIZE	    = $1C               ; 4 bytes

;==============================================================================
.zeropage

fat32_dirent:           .res 2          ; address of current directory entry

;   sector currently loaded to buffer
loaded_sector:          .res 4

;   partition info stored by fat32_init 
fat_begin_lba:          .res 4          ; first sector of fat
cluster_begin_lba:      .res 4          ; sector of first cluster
root_dir_first_cluster: .res 4          ; first cluster of root directory
sectors_per_cluster:    .res 1          ; sectors per cluster

;   iterator variables              
next_cluster:           .res 4          ; next cluster within current chain
next_sector:            .res 4          ; next sector within current cluster
sectors_pending:        .res 1          ; number of sectors left in current cluster
remaining_bytes:        .res 4          ; remaining bytes in current file

.code
;==============================================================================
fat32_init:
;------------------------------------------------------------------------------
;   output:
;       C           0: failed, 1: ok
;
;   output:
;       C           0: failed, 1: ok
;       last_error  0: ok
;------------------------------------------------------------------------------
.if DEBUG_FAT32
    PRINTLN "fat32_init"
.endif

    phy
    jsr sd_init
    bcc @done

;------------------------------------------------------------------------------
;   process master boot record (mbr)

    ;   invalidate cache 
    stx loaded_sector                   ; any number != 0

    ;   read sector 0
    jsr x_push32_0
    jsr _load_sector
    bcc @done                                

    ;   check mbr signature 
    jsr _check_signature
    bne @error_mbr                

    ;   find 1st fat32 partition within partition table
    ldy #0
    lda #TYPE_CODE_FAT32
    cmp fat32_buffer + MBR_TYPE_CODE, y
    beq @found_partition

    ldy #16
    cmp fat32_buffer + MBR_TYPE_CODE, y
    beq @found_partition

    ldy #32
    cmp fat32_buffer + MBR_TYPE_CODE, y
    beq @found_partition

    ldy #48
    cmp fat32_buffer + MBR_TYPE_CODE, y
    beq @found_partition

    lda #FAT32_ERR_PARTITION
    SKIP2                               ; skip next 2-byte instruction

@error_mbr:
    lda #FAT32_ERR_MBR
    SKIP2                               ; skip next 2-byte instruction

@error_bpb:
    lda #FAT32_ERR_BPB
    sta last_error
    clc
@done:
    ply
    rts

@found_partition:
    ;   push lba_begin
    X_PUSH_MEM32 { fat32_buffer + MBR_LBA_BEGIN, y }

.if DEBUG_FAT32 >= 2
    PRINT_HEX32 { stack, x }
    PRINTLN " lba_begin"
.endif

;------------------------------------------------------------------------------
;   process bios parameter block (bpb)

    jsr x_dup32
    jsr _load_sector
    X_POP_MEM32 tmp0                    ; lba_begin
    bcc @done

    ;   check bpb signature 
    jsr _check_signature
    bne @error_bpb

    ;   check some other values
    lda fat32_buffer + BPB_BYTSPERSEC   ; bytes per sector lo   (0)
    bne @error_bpb
    lda #2
    cmp fat32_buffer + BPB_BYTSPERSEC+1 ; bytes per sector hi   (2)
    bne @error_bpb
    cmp fat32_buffer + BPB_NUMFATS      ; number of fats        (2)
    bne @error_bpb

;------------------------------------------------------------------------------
;   save partition info

    ;   fat_begin_lba = cluster_begin_lba = lba_begin + BPB_RsvdSecCnt;
    clc
    lda tmp0        
    adc fat32_buffer + BPB_RSVDSECCNT 
    sta fat_begin_lba
    sta cluster_begin_lba

    lda tmp0 + 1    
    adc fat32_buffer + BPB_RSVDSECCNT + 1
    sta fat_begin_lba + 1
    sta cluster_begin_lba + 1

    lda tmp0 + 2
    adc #0
    sta fat_begin_lba + 2
    sta cluster_begin_lba + 2

    lda tmp0 + 3
    adc #0
    sta fat_begin_lba + 3
    sta cluster_begin_lba + 3

    ;   cluster_begin_lba += BPB_NumFATs * BPB_FATSz32
    ldy fat32_buffer + BPB_NUMFATS 
@skip_fats:
    clc
    lda cluster_begin_lba
    adc fat32_buffer + BPB_FATSZ32
    sta cluster_begin_lba

    lda cluster_begin_lba + 1
    adc fat32_buffer + BPB_FATSZ32 + 1
    sta cluster_begin_lba + 1

    lda cluster_begin_lba + 2
    adc fat32_buffer + BPB_FATSZ32 + 2
    sta cluster_begin_lba + 2

    lda cluster_begin_lba + 3
    adc fat32_buffer + BPB_FATSZ32 + 3
    sta cluster_begin_lba + 3

    dey
    bne @skip_fats

    ;   sectors_per_cluster = BPB_SecPerClus (1, 2, 4, ..., 128)    
    lda fat32_buffer + BPB_SECPERCLUS           
    sta sectors_per_cluster

    ;   root_dir_first_cluster = BPB_RootClus 
    CPY32 root_dir_first_cluster, fat32_buffer + BPB_ROOTCLUS


.if DEBUG_FAT32 >= 2
    PRINT_HEX32 fat_begin_lba
    PRINTLN " fat_begin_lba"

    PRINT_HEX32 cluster_begin_lba
    PRINTLN " cluster_begin_lba"

    PRINT_HEX32 root_dir_first_cluster
    PRINTLN " root_dir_first_cluster"

    lda sectors_per_cluster
    jsr print_hex8
    PRINTLN " sectors per cluster"

    PRINTLN "fat32_init done"
.endif

    ply
    sec                                 ; ok
    rts

;==============================================================================
fat32_openrootdir:              
;------------------------------------------------------------------------------
;   open root directory
;------------------------------------------------------------------------------
.if DEBUG_FAT32 >= 2
    PRINTLN "fat32_openrootdir"
.endif

;   next_cluster = root_dir_first_cluster
    CPY32 next_cluster, root_dir_first_cluster

;==============================================================================
_begindir:              
;------------------------------------------------------------------------------
;   reset directory iterator
;------------------------------------------------------------------------------
    stz sectors_pending                     ; force _seek_next_cluster
    lda #>(fat32_buffer + 512)              ; force _read_sector
    sta fat32_dirent + 1
    rts

;==============================================================================
fat32_readdir:                               
;------------------------------------------------------------------------------
;   read next directory entry, skip LFN and empty entries
;
;   output:   
;       C       1: success, 0: no more files
;------------------------------------------------------------------------------
.if DEBUG_FAT32 >= 2
    PRINTLN "fat32_readdir"
.endif

    phy
@loop:
    ;   fat32_dirent += 32 for next entry
    clc
    ADD16 fat32_dirent, 32

    ;   directory entry left in current sector?
    ;   (compare hi byte only, fat32_buffer is page aligned)
    cmp #>(fat32_buffer + 512)           
    bcc @gotdata

    ;   read next sector
    X_PUSH16 fat32_buffer
    jsr _read_next_sector
    SET16 fat32_dirent, fat32_buffer

    bcs @gotdata

@end_of_directory:
    clc
    bra @done

@gotdata:
    ;   end of directory?
    lda (fat32_dirent)
    beq @end_of_directory

    ;   skip unused entries
    cmp #$e5
    beq @loop

    ;   check attribute bits
    ldy #DIR_ATTR
    lda (fat32_dirent),y
    and #$3f
    cmp #$0f                            ; skip lfn
    beq @loop
    ; jsr print_hex8 
    ; jsr print_space
    bit #$0e                            ; skip hidden, system and volume label
    bne @loop

    sec                                 ; ok
@done:
    ply
    rts

;==============================================================================
fat32_open:                              
;------------------------------------------------------------------------------
;   prepare to read a file or subdir (fat32_dirent must point to dirent)
;------------------------------------------------------------------------------
    phy

    ;   store filesize
    ldy #DIR_FILESIZE
    lda (fat32_dirent),y
    sta remaining_bytes
    iny
    lda (fat32_dirent),y
    sta remaining_bytes + 1
    iny
    lda (fat32_dirent),y
    sta remaining_bytes + 2
    iny
    lda (fat32_dirent),y
    sta remaining_bytes + 3

    ;   store 1st cluster
    ldy #DIR_FSTCLUSLO
    lda (fat32_dirent),y
    sta next_cluster
    iny
    lda (fat32_dirent),y
    sta next_cluster + 1
    ldy #DIR_FSTCLUSHI
    lda (fat32_dirent),y
    sta next_cluster + 2
    iny
    lda (fat32_dirent),y
    sta next_cluster + 3

    ply
    bra _begindir

;==============================================================================
fat32_loadfile:                         ; ( addr -- )     
;------------------------------------------------------------------------------
;   load complete file contents to memory (64k max.)
;
;   output:   
;       C       1: success, 0: error
;------------------------------------------------------------------------------
    lda remaining_bytes + 2
    ora remaining_bytes + 3
    bne @done                           ; file too large

@next_sector:
.if DEBUG_FAT32 >= 2
    lda remaining_bytes + 1
    jsr print_hex8
    lda remaining_bytes
    jsr print_hex8
    jsr print_inline_asciiz
    .byte " bytes left", $0d, $0a, $00
.endif

    ;   remaining_bytes -= 512
    sec
    lda remaining_bytes + 1
    sbc #2 
    bcc @last_sector
    sta remaining_bytes + 1

    ;   read full sector to memory
    jsr x_dup16                         ; addr
    jsr _read_next_sector
    bcc @done                           ; out of sectors

    inc stack + 1, x                    ; addr += 512   
    inc stack + 1, x
    bra @next_sector

@last_sector:
    lda remaining_bytes
    ora remaining_bytes + 1
    sec                                 ; ok
    beq @done                           ; no bytes left

    ;   read last partial sector to buffer
    X_PUSH16 fat32_buffer 
    jsr _read_next_sector
    bcc @done                           ; out of sectors

    ;   memcpy(addr, fat32_buffer, remaining bytes)
    X_PUSH16 fat32_buffer 
    jsr x_swap16
    X_PUSH_MEM16 remaining_bytes
    jsr x_memcpy   
    sec                                 ; ok
    rts

@done:
    X_DROP16                            ; drop addr
    rts

;==============================================================================
;   internal methods
;==============================================================================
_check_signature:
;------------------------------------------------------------------------------
    lda fat32_buffer + $1fe
    cmp #$55
    bne @done
    lda fat32_buffer + $1ff
    cmp #$aa
@done:    
    rts

;==============================================================================
_load_next_sector:                      ; ( -- )    
;------------------------------------------------------------------------------
    X_PUSH_MEM32 next_sector

;==============================================================================
_load_sector:                           ; ( sector32 -- )    
;------------------------------------------------------------------------------
    X_PUSH16 fat32_buffer

;==============================================================================
_read_sector_cached:                    ; ( sector32 addr -- )    
;------------------------------------------------------------------------------
    ;   check addr
    CMP16 { stack, x }, fat32_buffer
    bne @no_buffer

    ;   check sector
    CMP32_MEM32 loaded_sector, { stack + 2, x } 
    beq @cache_hit
.if DEBUG_FAT32 >= 2
    PRINTLN "cache miss"
.endif
    CPY32 loaded_sector, { stack + 2, x }

@no_buffer:    
    jmp sd_read_sector

@cache_hit:
.if DEBUG_FAT32 >= 2
    PRINTLN "cache hit"
.endif
    sec
    jmp x_drop6

;==============================================================================
_read_next_sector:                    ; ( addr -- )
;------------------------------------------------------------------------------
;   output:
;       C           0: failed, 1: ok
;------------------------------------------------------------------------------
    ;   more sectors within current cluster?
    lda sectors_pending
    bne @read_sector

    jsr _seek_next_cluster              ; *** inline?
    bcs @read_sector

    X_DROP16
    rts

@read_sector:
    ;   read next sector within current chain to addr
    X_PUSH_MEM32 next_sector
    jsr x_rot16
    jsr _read_sector_cached
    bcc @done

    ;   advance to next sector
    INC32 next_sector
    dec sectors_pending
    sec
@done:    
    rts

;==============================================================================
_seek_next_cluster:
;------------------------------------------------------------------------------
    ;   check for end of chain
    lda next_cluster + 3                
    bpl @more_clusters
    clc 
    rts

@more_clusters:
    phy

;------------------------------------------------------------------------------
;   read fat sector for next cluster

    ;   next_sector = next_cluster * 2 / 256 
    lda next_cluster
    asl
    lda next_cluster + 1
    rol
    sta next_sector
    lda next_cluster + 2
    rol
    sta next_sector + 1
    lda next_cluster + 3
    rol                                 ; C = 0
    sta next_sector + 2

    ;   next_sector += fat_begin_lba (C = 0)
    lda next_sector
    adc fat_begin_lba
    sta next_sector
    lda next_sector + 1
    adc fat_begin_lba + 1
    sta next_sector + 1
    lda next_sector + 2
    adc fat_begin_lba + 2
    sta next_sector + 2
    lda #0
    adc fat_begin_lba + 3
    sta next_sector + 3

    ;   load next_sector to fat32_buffer
    jsr _load_next_sector
    bcc @done

;------------------------------------------------------------------------------
;   next_sector = ((next_cluster - 2) * sectors_per_cluster) + cluster_begin_lba

    ;   next_cluster = next_cluster - 2
    sec
    lda next_cluster
    sbc #2
    sta next_sector
    lda next_cluster + 1
    sbc #0
    sta next_sector + 1
    lda next_cluster + 2
    sbc #0
    sta next_sector + 2
    lda next_cluster + 3
    sbc #0
    sta next_sector + 3

    ;   next_sector *= sectors_per_cluster
    lda sectors_per_cluster                 ; 1, 2, 4, ..., 128
@loop:
    lsr
    bcs @break
    ASL32 next_sector
    bra @loop
@break:

    ;   next_sector += cluster_begin_lba
    clc
    ADD32_MEM32 next_sector, cluster_begin_lba

;------------------------------------------------------------------------------
;   sectors_pending = sectors_per_cluster

    lda sectors_per_cluster
    sta sectors_pending

;------------------------------------------------------------------------------
;   advance next_cluster within chain

    lda #<fat32_buffer
    sta tmp0
    lda #>fat32_buffer
    sta tmp1
 
    ;   offset within sector = (next_cluster % 127) * 4
    lda next_cluster
    and #$7f
    asl
    asl                                 
    tay                                 ; Y = offset lo, C = offset hi
    bcc @no_carry                       
    inc tmp1
@no_carry:                              ; tmp0 + y now points to next cluster number

    ;   load next cluster number
    lda (tmp0),y
    sta next_cluster
    iny
    lda (tmp0),y
    sta next_cluster + 1
    iny
    lda (tmp0),y
    sta next_cluster + 2

    ;   clear reserved bits but keep highest bit
    ;   (cluster number >= $FFFFFFF8 means end of chain)
    iny
    lda (tmp0),y
    and #$8f                            
    sta next_cluster + 3
    sec

@done:
    ply
    rts