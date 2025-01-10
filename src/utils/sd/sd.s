;   sd.s
;
;   sd card access
;
;   config:
;       SD_PORT                     output register
;       SD_PORT_DEFAULT             output register default value
;       SD_PORT_PRESERVE            (preserve port state, not implemented)
;       SD_PORT_PIN_SCK             port pin for sck
;       SD_PORT_PIN_CS              port pin for cs
;       SD_PORT_PIN_MOSI            port pin for mosi      
;       SD_PORT_PIN_MISO            port pin for miso
;       SD_CA2_SCK                  (use ca2 for sck, not implemented)
;
;   requirements:
;       - data direction register must be set for SCK, CS and MOSI
;       - output register must be initialized SCK=LO, CS=HI, MOSI=HI
;
;   to do:
;       - multiple sector read?
;
;   zeropage use:
;       - tmp0, tmp1 and tmp2 are reserved for sd_read_sector
;       - tmp3 is reserved for _readbyte and _writebyte
;
;   remarks:
;       - does not preserve port state (!)
;       - using ca2 for sck allows faster _readbyte implementation
;       - however, this would make code much more complicated
;
;   credits:
;       - https://github.com/gfoot/sdcard6502
;       - http://elm-chan.org/docs/mmc/mmc_e.html
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
.if SD_PORT_PRESERVE
    .error "SD_PORT_PRESERVE is not implemented"
.endif
.if SD_CA2_SCK
    .error "SD_CA2_SCK is not implemented"
.endif

;------------------------------------------------------------------------------
BIT_SCK  = (1 << SD_PORT_PIN_SCK)
BIT_CS   = (1 << SD_PORT_PIN_CS)
BIT_MOSI = (1 << SD_PORT_PIN_MOSI)
BIT_MISO = (1 << SD_PORT_PIN_MISO)

.define BITS_CS_HI              SD_PORT_DEFAULT
.define BITS_CS_LO              SD_PORT_DEFAULT & ~BIT_CS                        
 
;------------------------------------------------------------------------------
.rodata

CMD17   = $51                           ; CMD17 - READ_SINGLE_BLOCK

cmd_bytes:
cmd0_bytes:
  .byte $40, $00, $00, $00, $00, $95    ; CMD0 - GO_IDLE_STATE
cmd8_bytes:
  .byte $48, $00, $00, $01, $aa, $87    ; CMD8 - SEND_IF_COND
cmd55_bytes:
  .byte $77, $00, $00, $00, $00, $01    ; CMD55 - APP_CMD
cmd41_bytes:
  .byte $69, $40, $00, $00, $00, $01    ; ACMD41 - APP_SEND_OP_COND

.code
;==============================================================================
sd_init:
;------------------------------------------------------------------------------
.if DEBUG_SD
    PRINTLN "sd_init"
.endif
;------------------------------------------------------------------------------
;   output:
;       C           0: failed, 1: ok
;       last_error  error code or 0 for success
;------------------------------------------------------------------------------
    phx
    phy

;------------------------------------------------------------------------------
;   power on or card insertion:
;   - set mosi and cs high and apply 74 or more clock pulses to sclk 
;   - enter native operation mode 

    lda #SD_PORT_DEFAULT
    ldx #160               
@l1:
    eor #BIT_SCK
    sta SD_PORT
    dex
    bne @l1

    lda #SD_ERR_BASE
    sta last_error                           

;------------------------------------------------------------------------------
;   software reset

    ;   send cmd0 GO_IDLE_STATE
    ldy #cmd0_bytes - cmd_bytes
    jsr _cmd

    ;   expect R1 response idle state (not initialized)       
    cmp #$01                        
    bne @failed                             ; SD_ERR_CMD0
    inc last_error                              

;------------------------------------------------------------------------------
;   initialize sdhc card

    ;   send cmd8 SEND_IF_COND  
    ldy #cmd8_bytes - cmd_bytes
    jsr _cmd

    ;   expect R1 response idle state (not initialized)       
    cmp #$01                        
    bne @failed                         ; SD_ERR_CMD8
    inc last_error                              

    ;   ignore 32-bit return value
    phx
    jsr _readbyte
    jsr _readbyte
    jsr _readbyte
    jsr _readbyte
    plx

;------------------------------------------------------------------------------
@retry:
    ;   send cmd55 APP_CMD (prefix for acmd*)
    ldy #cmd55_bytes - cmd_bytes
    jsr _cmd

    ;   expect R1 response idle state (not initialized)       
    cmp #$01
    bne @failed                         ; SD_ERR_CMD55
    inc last_error                              

;------------------------------------------------------------------------------
    ;   send acmd41 APP_SEND_OP_COND
    ldy #cmd41_bytes - cmd_bytes
    jsr _cmd

    ;   expect R1 response (initialized) when card is ready
    cmp #$00
    beq @ok

    ;   expect R1 response idle state (not initialized) otherwise
    cmp #$01
    bne @failed                         ; SD_ERR_CMD41

    lda #100
    jsr delay_ms

    dec last_error                              
    bra @retry

@ok:
    stz last_error
    sec
    SKIP1                               ; skip next 1-byte instruction

@failed:
    clc
    ply
    plx
    rts

;==============================================================================
sd_read_sector:                         ; (sector32 addr --)
;------------------------------------------------------------------------------
;   output (ok / error):
;       Z           1 / 0
;       A           0 / <error code>
;------------------------------------------------------------------------------
.if DEBUG_SD
    lda #'R'
    jsr print_char
    jsr print_space
    PRINT_HEX32 { stack + 2, x }
    jsr print_crlf
.endif

    lda #BITS_CS_LO
    sta SD_PORT

    ;   CMD17 - READ_SINGLE_BLOCK
    lda #CMD17                          
    jsr _writebyte    
    lda stack + 5, x                    ; sector 24:31
    jsr _writebyte    
    lda stack + 4, x                    ; sector 16:23
    jsr _writebyte    
    lda stack + 3, x                    ; sector 8:15
    jsr _writebyte    
    lda stack + 2, x                    ; sector 0:7
    jsr _writebyte    
    lda #$00                            ; crc (not checked)
    jsr _writebyte

    lda stack, x                        ; addr lo
    sta tmp0
    lda stack + 1, x                    ; addr hi
    sta tmp1

    jsr x_drop6

    lda #SD_ERR_CMD17
    sta last_error

    ;   expect $00 (ok)
    jsr _waitresult
    cmp #$00
    bne @failed                         ; SD_ERR_CMD17
    inc last_error

    ;   expect $fe (data token)
    jsr _waitresult
    cmp #$fe
    bne @failed                         ; SD_ERR_READ

;------------------------------------------------------------------------------
;   read 512 bytes                      

    phx
    phy
    lda #2
    sta tmp2
    ldy #0

@loop:
    jsr _readbyte
    sta (tmp0),y
    iny
    bne @loop
    inc tmp1

    dec tmp2
    bne @loop

    ply
    plx

    stz last_error                            
    sec                                 ; ok        
    SKIP1                               ; skip next 1-byte instruction

@failed:
    clc
    lda #BITS_CS_HI                     ; release CS
    sta SD_PORT
    rts

;==============================================================================
_cmd:
;------------------------------------------------------------------------------
;   send command (6 bytes) to sd card 
;
;   input:
;       Y           command data offset
;   changes:
;       A, X, Y
;   output:
;       A           command last_error         
;------------------------------------------------------------------------------
    lda #BITS_CS_LO
    sta SD_PORT

    ldx #6
@loop:   
    lda cmd_bytes,y    
    jsr _writebyte
    iny
    dex 
    bne @loop
  
    jsr _waitresult
  
    ldx #BITS_CS_HI
    stx SD_PORT
    rts

;==============================================================================
_readbyte:

.if SD_PORT_PIN_MISO = 6
;==============================================================================
.out "using optimized _readbyte"
;------------------------------------------------------------------------------
;   changes:
;       X
;   output:
;       A           received byte
;   remarks:
;       - this is the optimized implementation for input on pin 6
;       - 154 cycles per byte including jsr/rts (to be checked)
;------------------------------------------------------------------------------
    phy 

    lda #0
    ldx #BITS_CS_LO
    ldy #BITS_CS_LO | BIT_SCK    

    sty SD_PORT                 ; 4     set sck hi
    bit SD_PORT                 ; 4     test miso
    stx SD_PORT                 ; 4     set sck lo
    bvc *+4                     ; 2/3   branch if miso is low    
    ora #$80                    ; 2     set bit 0

    sty SD_PORT                 ; 4     set sck hi
    bit SD_PORT                 ; 4     test miso
    stx SD_PORT                 ; 4     set sck lo
    bvc *+4                     ; 2/3   branch if miso is low    
    ora #$40                    ; 2     set bit 0

    sty SD_PORT                 ; 4     set sck hi
    bit SD_PORT                 ; 4     test miso
    stx SD_PORT                 ; 4     set sck lo
    bvc *+4                     ; 2/3   branch if miso is low    
    ora #$20                    ; 2     set bit 0

    sty SD_PORT                 ; 4     set sck hi
    bit SD_PORT                 ; 4     test miso
    stx SD_PORT                 ; 4     set sck lo
    bvc *+4                     ; 2/3   branch if miso is low    
    ora #$10                    ; 2     set bit 0

    sty SD_PORT                 ; 4     set sck hi
    bit SD_PORT                 ; 4     test miso
    stx SD_PORT                 ; 4     set sck lo
    bvc *+4                     ; 2/3   branch if miso is low    
    ora #$08                    ; 2     set bit 0

    sty SD_PORT                 ; 4     set sck hi
    bit SD_PORT                 ; 4     test miso
    stx SD_PORT                 ; 4     set sck lo
    bvc *+4                     ; 2/3   branch if miso is low    
    ora #$04                    ; 2     set bit 0

    sty SD_PORT                 ; 4     set sck hi
    bit SD_PORT                 ; 4     test miso
    stx SD_PORT                 ; 4     set sck lo
    bvc *+4                     ; 2/3   branch if miso is low    
    ora #$02                    ; 2     set bit 0

    sty SD_PORT                 ; 4     set sck hi
    bit SD_PORT                 ; 4     test miso
    stx SD_PORT                 ; 4     set sck lo
    bvc *+4                     ; 2/3   branch if miso is low    
    ora #$01                    ; 2     set bit 0

    ply
    rts

.else
;==============================================================================
.out "using default _readbyte"
;------------------------------------------------------------------------------
;   changes:
;       X
;   output:
;       A           received byte
;   remarks:
;       - this is the default implementation
;       - it is slower but works with any pin
;       - 238 cycles per byte including jsr/rts (to be checked)
;------------------------------------------------------------------------------
    ldx #8                              
@l1:
    lda #BITS_CS_LO | BIT_SCK           ; set sck hi
    sta SD_PORT

    lda SD_PORT                         ; read next bit
    and #BIT_MISO
    cmp #BIT_MISO
    rol tmp3

    lda #BITS_CS_LO
    sta SD_PORT                         ; set sck lo

    dex                                 
    bne @l1                             

    lda tmp3
    rts

.endif

;==============================================================================
_writebyte:
;------------------------------------------------------------------------------
;   input:
;       A           byte to send
;   remarks:
;       - works with any pin
;       - 217 cycles per byte including jsr/rts (to be checked)
;------------------------------------------------------------------------------
    sta tmp3
    sec                                 ; end of byte marker
    rol tmp3                            

@l1:
    lda #BITS_CS_LO                     ; sck lo
    bcs *+4
    eor #BIT_MOSI

    sta SD_PORT                         ; output mosi with sck lo
    ora #BIT_SCK
    sta SD_PORT                         ; sck hi

    asl tmp3                            ; shift out next bit
    bne @l1                             

    lda #BITS_CS_LO                     ; sck lo
    sta SD_PORT                         
    rts

;==============================================================================
_waitresult:
;   wait for the sd card to return something other than $ff
;
;   output:
;       A           received byte or $ff on timeout
;------------------------------------------------------------------------------
    phx
    phy
    ldy #0

@retry:    
    jsr _readbyte
    cmp #$ff
    bne @done
    dey
    bne @retry

@done:
    ply
    plx
    rts

; .if SD_CA2_SCK 
; ;==============================================================================
; _clk_lo:
; ;------------------------------------------------------------------------------
;     lda via1_pcr
;     and #%11110001
;     ora #%00001100
;     sta via1_pcr
;     rts
 
; ;==============================================================================
; _clk_hi:
; ;------------------------------------------------------------------------------
;     lda via1_pcr
;     ora #%00001110
;     sta via1_pcr
;     rts
 
; ;==============================================================================
; _clk_pulse:
; ;------------------------------------------------------------------------------
;     lda via1_pcr
;     and #%11110001
;     ora #%00001010
;     sta via1_pcr
;     rts
; .endif
    
    
