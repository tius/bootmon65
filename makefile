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
#------------------------------------------------------------------------------

#==============================================================================
#   project settings
#------------------------------------------------------------------------------
#	changing order may cause alignment errors (will be detected by linker)

SRC_NAMES	:= \
	utils/utils_zp 				\
	utils/serial_out 			\
	utils/serial_in 			\
	utils/delay_cycles  		\
	utils/delay_ms				\
	utils/fat32					\
	utils/input					\
	utils/instruction_size		\
	utils/misc					\
	utils/print					\
	utils/sd 					\
	utils/stack					\
	utils/vectors				\
	utils/xmem 					\
	utils/xmodem				\
	data 						\
	handlers 					\
	mon 						\
	test_sd 					\
	test_fat32 					\
	jmp_table 					\

BIN_NAME	:= boot
BIN_ADDR	:= f000

#==============================================================================
#   path settings
#------------------------------------------------------------------------------
#	tools

CA65		:= $(CC65_DIR)/ca65
LD65		:= $(CC65_DIR)/ld65

MKDIR 		:= $(GNUWIN_DIR)/mkdir.exe
RM 			:= $(GNUWIN_DIR)/rm.exe
FIND 		:= $(GNUWIN_DIR)/find.exe

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
SRC_FILES	:= $(addprefix $(SRC_DIR)/, $(addsuffix .s, $(SRC_NAMES)))
OBJ_FILES	:= $(addprefix $(OBJ_DIR)/, $(addsuffix .o, $(SRC_NAMES)))
LST_FILES	:= $(addprefix $(LST_DIR)/, $(addsuffix .o, $(SRC_NAMES)))
INC_FILES 	:= $(shell $(FIND) $(INC_DIRS) -name '*.inc')

OBJ_DIRS	:= $(patsubst %/, %, $(sort $(dir $(OBJ_FILES))))
LST_DIRS	:= $(patsubst %/, %, $(sort $(dir $(LST_FILES))))

LINKER_CFG	:= linker.cfg
MAP_FILE	:= $(LST_DIR)/linker.map
SYM_FILE	:= $(LST_DIR)/linker.sym

#==============================================================================
#   options
#------------------------------------------------------------------------------
.secondary:	$(OBJ_FILES)			# prevent object files from being deleted

#==============================================================================
#   targets
#------------------------------------------------------------------------------
.phony: default all compile upload clean 

# test:
# 	@echo $(INC_FILES)

default: compile

all: compile upload

compile: $(BIN_FILE)

upload:
	$(UPLOAD) $(BIN_ADDR) $(BIN_FILE)

clean:
	-$(RM) -r $(BUILD_DIR)

#------------------------------------------------------------------------------
#	create directories

$(BUILD_DIR) $(OBJ_DIRS) $(LST_DIRS):	
	$(MKDIR) -p $@

#------------------------------------------------------------------------------
#	process assembler files

$(OBJ_DIR)/%.o : $(SRC_DIR)/%.s $(OBJ_DIRS) $(LST_DIRS) $(INC_FILES)
	$(CA65) $(CA65_FLAGS) -o $@ -l $(LST_DIR)/$*.lst $<

#------------------------------------------------------------------------------
#	link object files

$(BIN_FILE): $(OBJ_FILES) $(LINKER_CFG)
	$(LD65) $(LD65_FLAGS) -o $(BIN_FILE) -C $(LINKER_CFG) -m $(MAP_FILE) -Ln $(SYM_FILE) $(OBJ_FILES)
