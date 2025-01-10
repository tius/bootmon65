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
;   compiler settings
;------------------------------------------------------------------------------
.pc02                                   ; allow 65c02 opcodes
.feature string_escapes                 ; allow \r \n ...

;==============================================================================
;   general
;------------------------------------------------------------------------------
.define VERSION_LO          01
.define VERSION_HI          25

;==============================================================================
;   features
;------------------------------------------------------------------------------
.define FEAT_HELP           1
.define FEAT_OPSIZE         1               
.define FEAT_XMODEM         1               
.define FEAT_XMEM           1               
.define FEAT_SD             1
 
.define FEAT_TEST_SD        0
.define FEAT_TEST_FAT32     0

;==============================================================================
;   debug settings
;------------------------------------------------------------------------------
.define DEBUG_SD            0
.define DEBUG_FAT32         0

;==============================================================================
;   hardware
;------------------------------------------------------------------------------
via1        := $e810

via1_orb    := via1 
via1_ira    := via1 + 1
via1_ora    := via1 + 1
via1_ddrb   := via1 + 2
via1_ddra   := via1 + 3
via1_pcr    := via1 + 12

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

ORA_MASK    := %00111001                ; output pins
ORA_DEFAULT := %00101001                ; output default values (cs=hi, sck=lo, mosi=hi)

;==============================================================================
;   modules
;------------------------------------------------------------------------------
;   input

.define input_read                  serial_in_line

;------------------------------------------------------------------------------
;   print

.define print_char                  serial_out_char
.define PRINT_CHAR_PRESERVES_TMP67  1

;------------------------------------------------------------------------------
;   serial_in

.define SERIAL_IN_REG               via1_ira
.define SERIAL_IN_PORT_PIN          7

;------------------------------------------------------------------------------
;   serial_out

.define SERIAL_OUT_PORT             via1_ora
.define SERIAL_OUT_PORT_DEFAULT     ORA_DEFAULT
.define SERIAL_OUT_PORT_PRESERVE    0
.define SERIAL_OUT_PORT_PIN         0

;------------------------------------------------------------------------------
;   sd

.define SD_PORT                     via1_ora
.define SD_PORT_DEFAULT             ORA_DEFAULT
.define SD_PORT_PRESERVE            0

.define SD_PORT_PIN_CS              3
.define SD_PORT_PIN_SCK             4
.define SD_PORT_PIN_MOSI            5
.define SD_PORT_PIN_MISO            6

.define SD_CA2_SCK                  0