##############################################################################
# Build global options
# NOTE: Can be overridden externally.
#

# Compiler options here.
ifeq ($(USE_OPT),)
	USE_OPT = -O2 -ggdb -fomit-frame-pointer -falign-functions=16
# 	USE_OPT += -nostdlib # enable to find all __throw_* functions
endif

# C specific options here (added to USE_OPT).
ifeq ($(USE_COPT),)
	USE_COPT =
endif

# C++ specific options here (added to USE_OPT).
ifeq ($(USE_CPPOPT),)
	USE_CPPOPT = -fno-rtti
	USE_CPPOPT += -std=gnu++11
	USE_CPPOPT += -fno-use-cxa-atexit
	USE_CPPOPT += -fno-exceptions -fno-unwind-tables -fno-threadsafe-statics
# 	USE_CPPOPT += -faligned-new
endif

# Enable this if you want the linker to remove unused code and data.
ifeq ($(USE_LINK_GC),)
	USE_LINK_GC = yes
endif

# Linker extra options here.
ifeq ($(USE_LDOPT),)
	USE_LDOPT =
endif

# Enable this if you want link time optimizations (LTO).
ifeq ($(USE_LTO),)
	USE_LTO = no
endif

# Enable this if you want to see the full log while compiling.
ifeq ($(USE_VERBOSE_COMPILE),)
	USE_VERBOSE_COMPILE = no
endif

# If enabled, this option makes the build process faster by not compiling
# modules not used in the current configuration.
ifeq ($(USE_SMART_BUILD),)
	USE_SMART_BUILD = yes
endif

#
# Build global options
##############################################################################

##############################################################################
# Architecture or project specific options
#

# Stack size to be allocated to the Cortex-M process stack. This stack is
# the stack used by the main() thread.
ifeq ($(USE_PROCESS_STACKSIZE),)
	# USE_PROCESS_STACKSIZE = 0x400
	USE_PROCESS_STACKSIZE = 0x10000
endif

# Stack size to the allocated to the Cortex-M main/exceptions stack. This
# stack is used for processing interrupts and exceptions.
ifeq ($(USE_EXCEPTIONS_STACKSIZE),)
	USE_EXCEPTIONS_STACKSIZE = 0x400
endif

# Enables the use of FPU (no, softfp, hard).
ifeq ($(USE_FPU),)
	USE_FPU = hard
endif

# FPU-related options.
ifeq ($(USE_FPU_OPT),)
	USE_FPU_OPT = -mfloat-abi=$(USE_FPU) -mfpu=fpv5-d16
	# USE_FPU_OPT = -mfloat-abi=$(USE_FPU) -mfpu=fpv5-sp-d16
endif

#
# Architecture or project specific options
##############################################################################

##############################################################################
# Project, target, sources and paths
#

# Define project name here
PROJECT = ch

# Target settings.
#MCU  = cortex-m4
MCU  = cortex-m7

# Imported source files and paths.
CHIBIOS  := lib/ChibiOS
CONFDIR  := ./cfg
BUILDDIR := ./build
DEPDIR   := ./.dep

# Licensing files.
include $(CHIBIOS)/os/license/license.mk
# Startup files.
include $(CHIBIOS)/os/common/startup/ARMCMx/compilers/GCC/mk/startup_stm32f7xx.mk
# HAL-OSAL files (optional).
include $(CHIBIOS)/os/hal/hal.mk
include $(CHIBIOS)/os/hal/ports/STM32/STM32F7xx/platform.mk
include $(CHIBIOS)/os/hal/boards/ST_NUCLEO144_F767ZI/board.mk
include $(CHIBIOS)/os/hal/osal/rt/osal.mk
# RTOS files (optional).
include $(CHIBIOS)/os/rt/rt.mk
include $(CHIBIOS)/os/common/ports/ARMCMx/compilers/GCC/mk/port_v7m.mk
# Auto-build files in ./source recursively.
include $(CHIBIOS)/tools/mk/autobuild.mk
# Other files (optional).
#include $(CHIBIOS)/test/lib/test.mk
#include $(CHIBIOS)/test/rt/rt_test.mk
#include $(CHIBIOS)/test/oslib/oslib_test.mk
include $(CHIBIOS)/os/hal/lib/streams/streams.mk

# Define linker script file here
# LDSCRIPT= $(STARTUPLD)/STM32F76xxI.ld
LDSCRIPT= ./STM32F76xxI.ld

# C sources that can be compiled in ARM or THUMB mode depending on the global
# setting.
CSRC = $(ALLCSRC) \
		$(TESTSRC) \
		$(CHIBIOS)/os/various/syscalls.c \
		src/malloc_lock.c \
		src/main.c

# C++ sources that can be compiled in ARM or THUMB mode depending on the global
# setting.
CPPSRC = $(ALLCPPSRC) \
		 $(CHIBIOS)/os/various/cpp_wrappers/syscalls_cpp.cpp \
		 src/stubs.cpp \
		 src/nmpc_test.cpp

# List ASM source files here.
ASMSRC = $(ALLASMSRC)

# List ASM with preprocessor source files here.
ASMXSRC = $(ALLXASMSRC)

# Inclusion directories.
INCDIR = $(CONFDIR) $(ALLINC) $(TESTINC)
INCDIR += lib/eigen
INCDIR += lib/polympc/src
INCDIR += ./src

# Define C warning options here.
CWARN = -Wall -Wextra -Wundef -Wstrict-prototypes

# Define C++ warning options here.
CPPWARN = -Wall -Wextra -Wundef
CPPWARN += -Wno-unused-parameter

#
# Project, target, sources and paths
##############################################################################

##############################################################################
# Start of user section
#

# List all user C define here, like -D_DEBUG=1
# UDEFS = -DEIGEN_NO_MALLOC
# UDEFS += -DEIGEN_NO_DEBUG

# Define ASM defines here
UADEFS =

# List all user directories here
UINCDIR =

# List the user directory to look for the libraries here
ULIBDIR =

# List all user libraries here
ULIBS =

#
# End of user section
##############################################################################

##############################################################################
# Common rules
#

RULESPATH = $(CHIBIOS)/os/common/startup/ARMCMx/compilers/GCC/mk
include $(RULESPATH)/arm-none-eabi.mk
LD = $(TRGT)g++ # overwrite linker to g++
include $(RULESPATH)/rules.mk

#
# Common rules
##############################################################################

##############################################################################
# Custom rules
#

POST_MAKE_ALL_RULE_HOOK: mem_info

# overwrite default asm listing rule
%.list: %.elf
ifeq ($(USE_VERBOSE_COMPILE),yes)
	$(OD) -d $< > $@
else
	@echo Creating $@
	@$(OD) -d $< > $@
	@echo
	@echo Done
endif

.PHONY: mem_info
mem_info: $(BUILDDIR)/$(PROJECT).elf
	arm-none-eabi-nm -C --size-sort --print-size $(BUILDDIR)/$(PROJECT).elf > $(BUILDDIR)/$(PROJECT).size
	arm-none-eabi-nm -C --numeric-sort --print-size $(BUILDDIR)/$(PROJECT).elf > $(BUILDDIR)/$(PROJECT).addr

.PHONY: flash
flash: $(BUILDDIR)/$(PROJECT).elf
	openocd -f openocd.cfg -c "program $(BUILDDIR)/$(PROJECT).elf verify reset" -c "shutdown"

#
# Custom rules
##############################################################################
