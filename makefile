#	makefile
#
#	enviroment:
#		CC65_DIR=d:\run\cc65\bin
#		GNUWIN_DIR=d:\run\gnuwin32
#
#------------------------------------------------------------------------------
#   MIT License
#
#   Copyright (c) 1978-2025 Matthias Waldorf, https://tius.org
#
#   Permission is hereby granted, free of charge, to any person obtaining a copy
#   of this software and associated documentation files (the "Software"), to deal
#   in the Software without restriction, including without limitation the rights
#   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#   copies of the Software, and to permit persons to whom the Software is
#   furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in all
#   copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#   SOFTWARE.
#
#==============================================================================
#   project settings
#------------------------------------------------------------------------------
#	- add source files to the list in the order they should be linked
#	- re-order files if the linker detects forbidden page branches
#	- other source files are added to LIB_FILE and linked only if referenced 

SRC_NAMES	:= \
	tinylib65/data/tinylib65_zp			\
	tinylib65/serial/serial_out 		\
	tinylib65/serial/serial_in_line		\
	tinylib65/serial/serial_in_char		\
	tinylib65/serial/serial_in_xmodem	\
	tinylib65/delay/delay_ms			\
	data 								\
	handlers 							\
	mon 								\
	jmp_table 							\
	vectors								\

BIN_NAME	:= boot
BIN_ADDR	:= f000

#==============================================================================
include makehelper65/ca65.mak