# Makefile for Arduino Due w/ native GCC tooling
#
# This Makefile uses the Arduino-Makefile project[1] to enable compilation
# and flashing for the Arduino Due, using a globally installed GCC toolchain.
#
# [1]: https://github.com/sudar/Arduino-Makefile

# use newhope1024cca by default
CRYPTO_PATH ?= newhope/newhope1024cca/
CRYPTO_ITERATIONS ?= 1

# Setup required by Arduino-Makefile
ARDUINO_DIR             ?= /usr/share/arduino
VENDOR_DIR              ?= $(realpath ../vendor)
ARDMK_DIR               ?= $(VENDOR_DIR)/Arduino-Makefile
ARDUINO_PACKAGE_DIR     ?= ~/.arduino15/packages
ALTERNATE_CORE_PATH     ?= $(VENDOR_DIR)/ArduinoCore-sam

# Override the location of the arm tooling
#
# Some sensible location would be `/usr`, but could also be `/usr/local` or `/opt`.
ARM_TOOLS_DIR           ?= $(shell dirname $(shell dirname $(shell which arm-none-eabi-gcc)))

# Override the monitor and ISP ports
ISP_PORT                ?= /dev/ttyACM0
MONITOR_PORT            ?= $(ISP_PORT)

# Setup bossa flashing tool
BOSSA                   ?= $(shell which bossac)
BOSSA_OPTS              := --erase --write --verify --boot=1

# Specify the board
BOARD_TAG               := arduino_due_x
ARCHITECTURE            := sam

# Add the path for including the Arduino.h file in C++ files
CPPFLAGS                += -I$(ALTERNATE_CORE_PATH)/cores/arduino

# Override the preferred optimization level (default: 's')
OPTIMIZATION_LEVEL      ?= 3

# Package the dilithium code in a static library
USER_LIB_PATH           := ./libraries
LOCAL_C_SRCS            ?= $(wildcard *.c) $(wildcard $(CRYPTO_PATH)/*.c) $(wildcard common/*.c)
LOCAL_CPP_SRCS          ?= $(wildcard *.cpp)
LOCAL_CC_SRCS           ?= $(wildcard *.cc)
LOCAL_PDE_SRCS          ?= $(wildcard *.pde)
LOCAL_INO_SRCS          ?= $(wildcard *.ino)
LOCAL_AS_SRCS           ?= $(wildcard *.S) $(wildcard $(CRYPTO_PATH)/*.S) $(wildcard common/*.S) $(wildcard m3/*.S)

CFLAGS += -Icommon -I$(CRYPTO_PATH)
CPPFLAGS += -Icommon -I$(CRYPTO_PATH) -DCRYPTO_ITERATIONS=$(CRYPTO_ITERATIONS)

# Let Arduino-Makefile do its magic
include $(ARDMK_DIR)/Sam.mk

# Override the compilation for the following files to use clang
CLANG                   ?= $(shell which clang)
CLANG_FLAGS             ?= --target=arm-none-eabi -mcpu=cortex-m3
CLANG_CPPFLAGS          ?= $(CPPFLAGS)
CLANG_CFLAGS            ?= $(CFLAGS) $(OPTIMIZATION_FLAGS)
CLANG_CXXFLAGS          ?= $(CXXFLAGS) $(OPTIMIZATION_FLAGS)
CLANG_ASFLAGS           ?= $(ASFLAGS)

# Flags to enforce compatibility with the GNU linker
CLANG_CFLAGS            += -fshort-enums -fno-lto
CLANG_CXXFLAGS          += -fshort-enums -fno-lto

# Disable lto for the benchmarking setup, because it screws up the measurements.
$(OBJDIR)/benchmark.c.o: CFLAGS += -fno-lto

tidy:
	rm -rf build-arduino_due_x

# Compile objects using clang if enabled
ifdef USE_CLANG
$(OBJDIR)/%.cc.o: %.cc $(COMMON_DEPS) | $(OBJDIR)
	@$(MKDIR) $(dir $@)
	$(CLANG) $(CLANG_FLAGS) -MMD -c $(CLANG_CPPFLAGS) $(CLANG_CXXFLAGS) $< -o $@

$(OBJDIR)/%.cpp.o: %.cpp $(COMMON_DEPS) | $(OBJDIR)
	@$(MKDIR) $(dir $@)
	$(CLANG) $(CLANG_FLAGS) -MMD -c $(CLANG_CPPFLAGS) $(CLANG_CXXFLAGS) $< -o $@

$(OBJDIR)/%.c.o: %.c $(COMMON_DEPS) | $(OBJDIR)
	@$(MKDIR) $(dir $@)
	$(CLANG) $(CLANG_FLAGS) -MMD -c $(CLANG_CPPFLAGS) $(CLANG_CFLAGS) $< -o $@

$(OBJDIR)/%.S.o: %.S $(COMMON_DEPS) | $(OBJDIR)
	@$(MKDIR) $(dir $@)
	$(CLANG) $(CLANG_FLAGS) -MMD -c $(CLANG_CPPFLAGS) $(CLANG_ASFLAGS) $< -o $@

$(OBJDIR)/%.s.o: %.s $(COMMON_DEPS) | $(OBJDIR)
	@$(MKDIR) $(dir $@)
	$(CLANG) $(CLANG_FLAGS) -c $(CLANG_CPPFLAGS) $(CLANG_ASFLAGS) $< -o $@
endif
