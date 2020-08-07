#
# Makefile to build and flash Arduino sketches
#
ifeq ($(OS),Windows_NT)
	BASE = D:/Dev-Tools/framework-arduino-samd-1.8.6
	CMSIS_BASE = D:/Dev-Tools/CMSIS_5
	STLINK = D:/Dev-Tools/stlink-1.3.0-win64
else
    UNAME_S := $(shell uname -s)
    ifeq ($(UNAME_S),Linux)
		BASE = /home/jef/Work/arduino/stm32/Arduino_Core_STM32
		CMSIS_BASE = /home/jef/Work/arduino/stm32/CMSIS_5
    endif
endif

# for a list of boards, see: $(BASE)/variants

_VERBOSE = @

# Configuration
BOARD = mkrzero
ARM = cortex-m0plus
HSE_VALUE = 8000000
HSI_VALUE = 8000000
PROCESSOR_MODEL = __SAMD21J18A__
PROCESSOR_LINKER_SCRIPT = flash_without_bootloader

# output folders
OBJDIR = obj
BINDIR = bin
# root source folder
SRCDIR = src

#
# Do not edit anything below this point
#
CORE = $(BASE)/cores
ARDUINO = $(CORE)/arduino
VARIANT = $(BASE)/variants/$(BOARD)
LIBDIR = $(BASE)/libraries
CMSIS = $(CMSIS_BASE)/CMSIS/Core/Include

LINKER_SCRIPT = $(BASE)/variants/$(BOARD)/linker_scripts/gcc/$(PROCESSOR_LINKER_SCRIPT).ld

export proefje=/usr/local/demo

# C++ Compiler and options
CXX = arm-none-eabi-g++
CXXFLAGS = -c -g -Os -mcpu=$(ARM) -std=gnu++14
CXXFLAGS += -ffunction-sections -fdata-sections -nostdlib -fno-threadsafe-statics --param max-inline-insns-single=500 
CXXFLAGS += -fno-rtti -fno-exceptions -fno-use-cxa-atexit -MMD

# C Compiler and options
CC = arm-none-eabi-gcc
CCFLAGS = -c -g -Os -std=gnu11 -mcpu=$(ARM)
CCFLAGS += -ffunction-sections -fdata-sections -nostdlib --param max-inline-insns-single=500 -MMD

# Linker and options
LD = arm-none-eabi-gcc
LDFLAGS = -mcpu=$(ARM) -mthumb -Os --specs=nano.specs -specs=nosys.specs 
#LDFLAGS += -larm_cortexM3l_math -lm -lgcc -lstdc++
LDFLAGS += -lm -lgcc -lstdc++
#LDFLAGS += -Wl,--defsym=LD_FLASH_OFFSET=0 -Wl,--defsym=LD_MAX_SIZE=131072 -Wl,--defsym=LD_MAX_DATA_SIZE=20480 
LDFLAGS += -Wl,--cref -Wl,--check-sections -Wl,--gc-sections -Wl,--entry=Reset_Handler -Wl,--unresolved-symbols=report-all -Wl,--warn-common 
LDFLAGS += -T$(LINKER_SCRIPT)
LDFLAGS += -L./lib 
LDFLAGS += "-Wl,-Map,bin/firmware.map" 
LDFLAGS += -Wl,--start-group -Wl,--whole-archive -Wl,--no-whole-archive -lc -Wl,--end-group 
LDFLAGS += --specs=rdimon.specs -lrdimon
#LDFLAGS += -Wl,--verbose

# Misc. programs
SIZE = arm-none-eabi-size
OBJCOPY = arm-none-eabi-objcopy

# source code to compile
SRCS = $(shell find $(CORE) -name "*.c")
OBJS = $(patsubst $(CORE)/%.c, $(OBJDIR)/%.o, $(SRCS))

CPPSRCS = $(shell find $(CORE) -name "*.cpp")
CPPOBJS = $(patsubst $(CORE)/%.cpp, $(OBJDIR)/%.o, $(CPPSRCS))

# arduino source code to compile
VARSRCS = $(wildcard $(VARIANT)/*.c)
VAROBJS = $(patsubst $(VARIANT)/%.c, $(OBJDIR)/variant/%.o, $(VARSRCS))

VARCPPSRCS = $(wildcard $(VARIANT)/*.cpp)
VARCPPOBJS = $(patsubst $(VARIANT)/%.cpp, $(OBJDIR)/variant/%.o, $(VARCPPSRCS))

SOURCES = $(wildcard $(SRCDIR)/*.cpp)
CPPUSEROBJS = $(patsubst $(SRCDIR)/%.cpp, $(OBJDIR)/%.o, $(SOURCES))

_WRAPPERSRCS = $(shell find $(BASE)/libraries/SrcWrapper/src -name "*.c")
_WRAPPEROBJS = $(patsubst $(BASE)/libraries/SrcWrapper/src/%.c, $(OBJDIR)/%.o, $(WRAPPERSRCS))

_WRAPPERSRCSCPP = $(shell find $(BASE)/libraries/SrcWrapper/src -name "*.cpp")
_WRAPPEROBJSCPP = $(patsubst $(BASE)/libraries/SrcWrapper/src/%.cpp, $(OBJDIR)/%.o, $(WRAPPERSRCSCPP))


LIBSRC = \
$(LIBDIR)/Wire/Wire.cpp \
$(LIBDIR)/SPI/SPI.cpp 
LIBOBJS = $(patsubst %.cpp, $(OBJDIR)/lib/%.o, $(notdir $(LIBSRC)))

_LIBSRCC = \
$(LIBDIR)/Wire/src/utility/twi.c 
LIBOBJSC = $(patsubst %.c, $(OBJDIR)/lib/%.o, $(notdir $(LIBSRCC))) 

INC = \
-I$(ARDUINO) \
-I$(ARDUINO)/stm32 \
-I$(ARDUINO)/stm32/LL \
-I$(ARDUINO)/stm32/usb \
-I$(BASE)/system/Drivers/CMSIS/Include \
-I$(HALBASE)/Inc \
-I$(VARIANT) \
-I$(LIBDIR)/Wire/src -I$(LIBDIR)/SPI/src -I$(LIBDIR)/IWatchdog/src  \
-I$(CMSIS) \
-I./samd_extra/_package_/samd21a/include

DEFINES = \
-D$(PROCESSOR_MODEL) \
-DBOARD=$(BOARD) \
-DARDUINO=10810 \
-DHAL_UART_MODULE_ENABLED \
-DF_CPU=48000000L \
-DCRYSTALLESS \
-DDEBUG

# linking
$(BINDIR)/firmware.elf:  $(ASMOBJ) $(VAROBJS) $(VARCPPOBJS) $(OBJS) $(CPPOBJS) $(HALOBJS) $(LIBOBJS) $(CPPUSEROBJS) $(LIBOBJSC) $(WRAPPEROBJSCPP) $(WRAPPEROBJS)
	@test -d $(BINDIR) || mkdir -p $(BINDIR)
	$(LD) $(LDFLAGS) -o $@ $(ASMOBJ) $(VAROBJS) $(VARCPPOBJS) $(OBJS) $(CPPOBJS) $(HALOBJS) $(LIBOBJS) $(CPPUSEROBJS) $(LIBOBJSC) $(WRAPPEROBJSCPP) $(WRAPPEROBJS) 

	$(LD) $(LDFLAGS) -o $@ $(ASMOBJ) $(VAROBJS) $(OBJS) $(CPPOBJS) $(LIBOBJSC) $(WRAPPEROBJSCPP) $(WRAPPEROBJS) $(VARCPPOBJS) $(HALOBJS) $(LIBOBJS) $(CPPUSEROBJS)
	$(OBJCOPY) -O binary $@ $(BINDIR)/firmware.bin
	$(OBJCOPY) -O ihex $@ $(BINDIR)/firmware.hex
	$(SIZE) -B $@

# Compiling asm startup vectors
$(ASMOBJ) : $(ASMSRC)
	@test -d $(dir $@) || mkdir -p $(dir $@)
	@echo compiling $<
	$(VERBOSE) $(CC) $(CCFLAGS) $(DEFINES) $(INC) -o $@ $<

$(VAROBJS):
	$(eval SOURCE := $(patsubst $(OBJDIR)/variant/%.o, $(VARIANT)/%.c, $@))
	@test -d $(dir $@) || mkdir -p $(dir $@)
	@echo compiling $(SOURCE)
	$(VERBOSE) $(CC) $(CCFLAGS) $(DEFINES) $(INC) -o $@ $(SOURCE)

$(HALOBJS):
	$(eval SOURCE := $(patsubst $(OBJDIR)/hal/%.o, $(HALBASE)/Src/%.c, $@))
	@test -d $(dir $@) || mkdir -p $(dir $@)
	@echo compiling $(SOURCE)
	$(VERBOSE) $(CC) $(CCFLAGS) $(DEFINES) $(INC) -o $@ $(SOURCE)

$(VARCPPOBJS):
	$(eval SOURCE := $(patsubst $(OBJDIR)/variant/%.o, $(VARIANT)/%.cpp, $@))
	@test -d $(dir $@) || mkdir -p $(dir $@)
	@echo compiling $(SOURCE)
	$(VERBOSE) $(CXX) $(CXXFLAGS) $(DEFINES) $(INC) -o $@ $(SOURCE)
	
$(WRAPPEROBJS):
	$(eval SOURCE := $(patsubst $(OBJDIR)/%.o, $(BASE)/libraries/SrcWrapper/src/%.c, $@))
	@test -d $(dir $@) || mkdir -p $(dir $@)
	@echo compiling $(SOURCE)
	$(VERBOSE) $(CC) $(CCFLAGS) $(DEFINES) $(INC) -o $@ $(SOURCE)
	
$(WRAPPEROBJSCPP):
	$(eval SOURCE := $(patsubst $(OBJDIR)/%.o, $(BASE)/libraries/SrcWrapper/src/%.cpp, $@))
	@test -d $(dir $@) || mkdir -p $(dir $@)
	@echo compiling $(SOURCE)
	$(VERBOSE) $(CXX) $(CXXFLAGS) $(DEFINES) $(INC) -o $@ $(SOURCE)
	
$(OBJS):
	$(eval SOURCE := $(patsubst $(OBJDIR)/%.o, $(CORE)/%.c, $@))
	@test -d $(dir $@) || mkdir -p $(dir $@)
	@echo compiling $(SOURCE)
	$(VERBOSE) $(CC) $(CCFLAGS) $(DEFINES) $(INC) -o $@ $(SOURCE)

$(CPPOBJS):
	$(eval SOURCE := $(patsubst $(OBJDIR)/%.o, $(CORE)/%.cpp, $@))
	@test -d $(dir $@) || mkdir -p $(dir $@)
	@echo compiling $(SOURCE)
	$(VERBOSE) $(CXX) $(CXXFLAGS) $(DEFINES) $(INC) -o $@ $(SOURCE)

$(LIBOBJS):
	$(eval LIBNAME := $(basename $(notdir $@)))
	$(eval SOURCE := $(patsubst $(OBJDIR)/lib/%.o, $(LIBDIR)/$(LIBNAME)/%.cpp, $@))
	@test -d $(dir $@) || mkdir -p $(dir $@)
	@echo compiling $(SOURCE)
	$(VERBOSE) $(CXX) $(CXXFLAGS) $(DEFINES) $(INC) -o $@ $(SOURCE)

$(LIBOBJSC):
	$(eval SOURCE := $(patsubst $(OBJDIR)/lib/%.o, $(LIBDIR)/Wire/src/utility/%.c, $@))
	@test -d $(dir $@) || mkdir -p $(dir $@)
	@echo compiling $(SOURCE)
	$(VERBOSE) $(CC) $(CCFLAGS) $(DEFINES) $(INC) -o $@ $(SOURCE)

$(CPPUSEROBJS): $(OBJDIR)/%.o : $(SRCDIR)/%.cpp
	@test -d $(dir $@) || mkdir -p $(dir $@)
	@echo compiling $<
	$(VERBOSE) $(CXX) $(CXXFLAGS) $(DEFINES) $(INC) -o $@ $<
		


.PHONY: clean flash debug info
clean:
	rm -fR $(OBJDIR)
	rm -fR $(BINDIR)

flash: $(BINDIR)/firmware.elf
	$(STLINK)/bin/st-flash write ./$(BINDIR)/firmware.bin 0x8000000

info:
	$(STLINK)/bin/st-info --probe

debug:
	@echo $(LIBSRC)
	@echo $(LIBOBJS)
	@echo $(LINKER_SCRIPT)