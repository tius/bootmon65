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

* software-only interface without using the via 6522 shift register
* speed up to 6 kByte/s @ 1MHz cpu clock
* sdhc compatible cards only
* minimal fat32 implementation (read directories, load files)

### extended memory (xmem)

* access up to 512 KByte ram via additional opcodes
* requires minimal external logic (e. g. gal)

### monitor

* minimal cbm-style monitor
* dump, edit and clear memory
* dump and edit registers
* run code
* brk handler
* dump instructions (opt.)
* dump and edit xmem (opt.)
* xmodem upload and download (opt.)
* sd card list and load (opt.)

### misc

* hooks for reset, nmi, irq and brk
* hooks for monitor extensions
* utility functions available via jmp table (wip)

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
* callee saved: X, Y, r0, r1, ...

exceptions

* Y may be used as additional input or output value if documented
* zp use across functions _must_ be documented

## monitor commands

    e [0|1]                 read and write echo setting
    r [pc ..]               read and write register
    v [res ..]              read and write vectors
    g [addr]                go (run code)
    m [addr [addr]]         read memory 
    : addr dd ..            write memory
    c addr addr [dd]        clear memory
    i [addr]                instruction dump
    x xaddr [dd ..]         read and write xmem
    u addr                  xmodem upload
    d addr addr             xmodem download
    l [xx addr]             sd card list / load
    t [0|1]                 run tests

## planned

### refactoring

* refactor mon.s using software stack?
* redesign fat32 state representation?
* reorganize jmp table?

### optimization

* sd card multi-sector read for load?

### new features

* autostart application code
* autoload sd card files
* display sd card files (ascii and hex)
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

* use git submodule?

## wiring

    pa0     out     serial      tx          bit 0 used for optimized code
    pa1                                     xtra cs?
    pa2                                     xtra cs?
    pa3     out     sd          cs
    pa4     out     sd          sck         shared with i²c?
    pa5     out     sd          mosi        shared with i²c?
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
