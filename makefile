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
#   path settings
#------------------------------------------------------------------------------
#	tools

CA65		:= $(CC65_DIR)/ca65
AR65		:= $(CC65_DIR)/ar65
LD65		:= $(CC65_DIR)/ld65

MKDIR 		:= $(GNUWIN_DIR)/mkdir.exe
RM 			:= $(GNUWIN_DIR)/rm.exe
FIND 		:= $(GNUWIN_DIR)/find.exe

PYTHON		:= python

#	upload binary using teraterm for windows
UPLOAD		:= cmd /c upload.ttl

#------------------------------------------------------------------------------
#	directories

SRC_DIR		:= src
INC_DIRS	:= $(shell $(FIND) $(SRC_DIR) -name include)

BUILD_DIR	:= build
OBJ_DIR		:= $(BUILD_DIR)/obj
LST_DIR		:= $(BUILD_DIR)/lst

#------------------------------------------------------------------------------
#	flags

CA65_FLAGS	:= -v $(addprefix -I, $(INC_DIRS))
LD65_FLAGS	:= -v -vm

#------------------------------------------------------------------------------
#	files

BIN_FILE	:= $(BUILD_DIR)/$(BIN_NAME).bin
NAMED_SRCS	:= $(addprefix $(SRC_DIR)/, $(addsuffix .s, $(SRC_NAMES)))
NAMED_OBJS	:= $(addprefix $(OBJ_DIR)/, $(addsuffix .o, $(SRC_NAMES)))

ALL_SRCS 	:= $(shell $(FIND) $(SRC_DIR) -name '*.s')
ALL_OBJS	:= $(patsubst $(SRC_DIR)%, $(OBJ_DIR)%, $(ALL_SRCS:.s=.o))
ALL_INCS	:= $(shell $(FIND) $(SRC_DIR) -name '*.inc')
LIB_FILE	:= $(BUILD_DIR)/$(BIN_NAME).lib
LIB_OBJS	:= $(filter-out $(NAMED_OBJS), $(ALL_OBJS))

OBJ_DIRS	:= $(patsubst %/, %, $(sort $(dir $(ALL_OBJS))))
LST_DIRS	:= $(patsubst $(OBJ_DIR)%, $(LST_DIR)%, $(OBJ_DIRS))

LINKER_CFG	:= linker.cfg
MAP_FILE	:= $(LST_DIR)/linker.map
SYM_FILE	:= $(LST_DIR)/linker.sym

#==============================================================================
#   options
#------------------------------------------------------------------------------
.secondary:	$(ALL_OBJS)				# prevent object files from being deleted

#==============================================================================
#   targets
#------------------------------------------------------------------------------
.phony: default all compile upload memuse clean 

default: compile

all: compile upload

lib: $(LIB_FILE)

compile: $(BIN_FILE)

upload:
	$(UPLOAD) $(BIN_ADDR) $(BIN_FILE)

memuse: $(MAP_FILE)	
	@$(PYTHON) memuse.py -v $(MAP_FILE)

clean:
	-$(RM) -r $(BUILD_DIR)

#------------------------------------------------------------------------------
#	create directories

$(BUILD_DIR) $(OBJ_DIRS) $(LST_DIRS):	
	$(MKDIR) -p $@

#------------------------------------------------------------------------------
#	process assembler files

$(OBJ_DIR)/%.o : $(SRC_DIR)/%.s $(OBJ_DIRS) $(LST_DIRS) $(ALL_INCS)
	$(CA65) $(CA65_FLAGS) -o $@ -l $(LST_DIR)/$*.lst $<

#------------------------------------------------------------------------------
#	build lib file

$(LIB_FILE): $(LIB_OBJS) 
	$(AR65) a $(LIB_FILE) $(LIB_OBJS)  

#------------------------------------------------------------------------------
#	link object files

$(BIN_FILE): $(NAMED_OBJS) $(LIB_FILE) $(LINKER_CFG)
	$(LD65) $(LD65_FLAGS) -o $(BIN_FILE) -C $(LINKER_CFG) -m $(MAP_FILE) -Ln $(SYM_FILE) $(NAMED_OBJS) $(LIB_FILE)
	@$(PYTHON) memuse.py -v $(MAP_FILE)