;   config.inc
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

;==============================================================================
;   general
;------------------------------------------------------------------------------
VERSION_LO      = 01
VERSION_HI      = 25

;==============================================================================
;   features
;------------------------------------------------------------------------------
FEAT_HELP       = 1
FEAT_OPSIZE     = 1               
FEAT_XMODEM     = 1               
FEAT_XMEM       = 1               
FEAT_SD         = 1
 
FEAT_TEST_SD    = 0
FEAT_TEST_FAT32 = 0

;==============================================================================
;   hardware
;------------------------------------------------------------------------------
via1            := $e810

via1_orb        := via1 
via1_ira        := via1 + 1
via1_ora        := via1 + 1
via1_ddrb       := via1 + 2
via1_ddra       := via1 + 3
via1_pcr        := via1 + 12

;------------------------------------------------------------------------------
;   pin assignments
;
;   remarks:
;       - using default values for output pins allows optimized code
;       - care must be taken to avoid unintended changing other output lines
;------------------------------------------------------------------------------
;   port    dir     module      usage       default 
;
;   pa0     out     serial      tx          hi
;   pa1 
;   pa2 
;   pa3     out     sd          cs          hi
;   pa4     out     sd          sck         lo
;   pa5     out     sd          mosi        hi
;   pa6     in      sd          miso                 
;   pa7     in      serial      rx

ORA_MASK        = %00111001             ; output pins
ORA_IDLE        = %00101001             ; output idle values (cs=hi, sck=lo, mosi=hi)

;==============================================================================
;   modules
;------------------------------------------------------------------------------
;   fat32

FAT32_DEBUG         = 0

;------------------------------------------------------------------------------
;   serial_in

SERIAL_RX_PORT      = via1_ira
SERIAL_RX_PORT_PIN  = 7

;------------------------------------------------------------------------------
;   serial_out

SERIAL_TX_PORT      = via1_ora
SERIAL_TX_PORT_IDLE = ORA_IDLE
SERIAL_TX_PORT_SAVE = 0
SERIAL_TX_PORT_PIN  = 0

;------------------------------------------------------------------------------
;   sd

SD_DEBUG            = 0
SD_PORT             = via1_ora
SD_PORT_IDLE        = ORA_IDLE
SD_PORT_SAVE        = 0

SD_PORT_PIN_CS      = 3
SD_PORT_PIN_SCK     = 4
SD_PORT_PIN_MOSI    = 5
SD_PORT_PIN_MISO    = 6

SD_CA2_SCK          = 0
