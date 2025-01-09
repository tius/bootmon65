# bootmon65

bootloader and monitor for the tiny65 system

## preface

This is the resident bootloader of the tiny65 system. However, some
components may also be suitable for other 65c02 systems.

The hardware requirements for the basic functionality are minimal, only a few
free I/O lines are needed for the serial interface and the optional SD card
interface.

Optional functions for accessing an extended memory of up to 512 kByte (xmem)
are included. These of course require the appropriate hardware.

Many of the decades of experience gathered on 6502.org have been incorporated
into the code. Many thanks to all the experts who contributed there.

The source code is published under the MIT license. Bug reports, comments and
improvements are very welcome.

## features

### serial interface

* software-only serial interface
* 57600 baud, half-duplex @ 1MHz cpu clock
* full xmodem implementation
* processing terminal input at wire speed requires remote echo off (e 0)

### sd card

* software-only interface without using via shift register
* speed up to 6 kByte/s @ 1MHz cpu clock
* sdhc compatible cards only
* minimal fat32 implementation (read directories, load files)

### extended memory (xmem)

* access up to 512 KByte ram via additional opcodes

### monitor

* minimal cbm-style monitor
* dump, edit and clear memory
* dump, edit and clear xmem
* dump and edit registers
* dump instructions
* run program
* brk handler
* xmodem upload and download
* sd card list and load

### misc

* hooks for reset, nmi, irq and brk
* hooks for monitor extensions
* utility functions available via jmp table

## design goals

### general

* readability
* consistency
* scalability
* modularity
* fast and small

### prefered calling conventions

input values

* A
* software stack
* global module variables

output values

* A
* C (0: failed, 1: success)
* last_error (0: ok, >0: error code)
* software stack
* global module variables

register and zeropage use

* caller saved: A, tmp0, tmp1, ...
* callee saved: X, Y, w0, w1, ...

exceptions

* tmp0..7 may be shared across functions within the same module if documented
* Y, w0 and w1 may be used as additional input or output value if documented

## monitor commands

    e [0|1]                 echo 
    r [pc ..]               register
    v [res ..]              vectors
    g [addr]                go
    m [addr [addr]]         memory dump
    : addr dd ..            set memory
    c addr addr [dd]        clear memory
    i [addr]                instruction dump
    x <0..7>                set xmem bank
    u addr                  xmodem upload
    d addr addr             xmodem download
    l [addr xx]             sd card list / load
    t [0|1]                 run tests

## planned

### refactoring

* refactor mon.s using software stack?
* redesign fat32 state representation?
* reorganize jmp table?

### optimization

* sd card multi-sector read for load?

### new features

* avrdude support?
* autostart application code
* autoload sd card files
* type sd card files (ascii and hex)
* use sd card for help files
* (extended) identity table
* more forth-style utility functions
* more 32 bit utility functions
* relocator helper
* memory management (zeropage, data, xmem)
* xmem filesystem
* i2c support
* generic spi support

### build system

* use libraries?
* move utils to submodule?

## wiring

    pa0     out     serial      tx          bit 0 used for optimized code
    pa1
    pa2
    pa3     out     sd          cs
    pa4     out     sd          sck
    pa5     out     sd          mosi
    pa6     in      sd          miso        bit 6 used for higher speed
    pa7     in      serial      rx          bit 7 is required for 57600 baud

## see also

software stacks

* <https://wilsonminesco.com/stacks/potpourri.html>
* <https://github.com/scotws/TaliForth2/blob/master/docs/manual.md>

sd card and fat32

* <https://github.com/gfoot/sdcard6502>
* <http://elm-chan.org/docs/mmc/mmc_e.html>
* <https://www.pjrc.com/tech/8051/ide/fat32.html>
