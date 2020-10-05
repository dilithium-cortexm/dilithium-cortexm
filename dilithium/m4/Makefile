# 4 for Cortex-M4
PLATFORM           ?= 4

# dilithium2, dilithium3, or diltihium4 
TARGET_NAME        ?= dilithium3
# 2 for Dilithium2; 3 for Dilithium3; 4 for Dilithium4
DILITHIUM_MODE     ?= 3

# 1 for Strategy 1 (A in Flash)
# 2 for Strategy 2 (A in RAM)
# 3 for Strategy 3 (Streaming A) 
SIGN_STACKSTRATEGY ?= 2
 
# test, testvectors, speed, stack, or profile
TEST ?= test

# Number of iterations; use at least 10000 for benchmarking
CRYPTO_ITERATIONS ?= 1


OPENCM3DIR  = ../../libopencm3
OPENCM3NAME = opencm3_stm32f4
OPENCM3FILE = $(OPENCM3DIR)/lib/lib$(OPENCM3NAME).a
LDSCRIPT    = stm32f405x6.ld # This is also valid for the stm32f407xx chips

PREFIX     ?= arm-none-eabi
CC          = $(PREFIX)-gcc
LD          = $(PREFIX)-gcc
OBJCOPY     = $(PREFIX)-objcopy

ARCH_FLAGS  = -mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16
DEFINES     = -DSTM32F4

CFLAGS     += -O3 \
              -Wall -Wextra -Wimplicit-function-declaration \
              -Wredundant-decls -Wmissing-prototypes -Wstrict-prototypes \
              -Wundef -Wshadow \
              -I$(OPENCM3DIR)/include \
              -fno-common $(ARCH_FLAGS) -MD $(DEFINES) -DSIGN_STACKSTRATEGY=$(SIGN_STACKSTRATEGY)


IMPLEMENTATION_PATH = ../dilithium/
IMPLEMENTATION_SOURCES = $(wildcard $(IMPLEMENTATION_PATH)/*.c) *.s
IMPLEMENTATION_HEADERS = $(wildcard $(IMPLEMENTATION_PATH)/*.h)

COMMONSOURCES=../common/fips202.c ../common/keccakf1600.S
COMMONINCLUDES=-I$(IMPLEMENTATION_PATH) -I../common/ -I.
DEST=bin



LDFLAGS    += --static -Wl,--start-group -lc -lgcc -lnosys -Wl,--end-group \
              -T$(LDSCRIPT) -nostartfiles -Wl,--gc-sections \
               $(ARCH_FLAGS) -L$(OPENCM3DIR)/lib -lm -l$(OPENCM3NAME)

.PHONY: all
all: $(DEST)/$(TARGET_NAME)_$(TEST).bin

$(DEST)/%.bin: elf/%.elf
	mkdir -p $(DEST)
	$(OBJCOPY) -Obinary $^ $@

elf/$(TARGET_NAME)_%.elf: %.c $(IMPLEMENTATION_SOURCES)  $(IMPLEMENTATION_HEADERS) randombytes.c $(OPENCM3FILE) hal-stm32f4.c
	mkdir -p elf
	$(CC) -o $@ $(CFLAGS) -DDILITHIUM_MODE=$(DILITHIUM_MODE) -DPLATFORM=$(PLATFORM) -DCRYPTO_ITERATIONS=$(CRYPTO_ITERATIONS)\
		$< $(COMMONSOURCES) randombytes.c $(IMPLEMENTATION_SOURCES) hal-stm32f4.c \
		$(COMMONINCLUDES) $(LDFLAGS)

elf/$(TARGET_NAME)_profile.elf: profile.c $(IMPLEMENTATION_SOURCES)  $(IMPLEMENTATION_HEADERS) randombytes.c $(OPENCM3FILE) hal-stm32f4.c
	mkdir -p elf
	$(CC) -o $@ -g $(CFLAGS) -DDILITHIUM_MODE=$(DILITHIUM_MODE) -DPLATFORM=$(PLATFORM) -DCRYPTO_ITERATIONS=$(CRYPTO_ITERATIONS)\
		$< $(COMMONSOURCES) randombytes.c $(IMPLEMENTATION_SOURCES) hal-stm32f4.c \
		$(COMMONINCLUDES) $(LDFLAGS)

elf/$(TARGET_NAME)_testvectors.elf: testvectors.c $(IMPLEMENTATION_SOURCES)  $(IMPLEMENTATION_HEADERS) randombytes.c $(OPENCM3FILE) hal-stm32f4.c
	mkdir -p elf
	$(CC) -o $@ $(CFLAGS) -DDILITHIUM_MODE=$(DILITHIUM_MODE) -DPLATFORM=$(PLATFORM)\
		testvectors.c $(COMMONSOURCES) $(IMPLEMENTATION_SOURCES) hal-stm32f4.c \
		$(COMMONINCLUDES) $(LDFLAGS)



$(OPENCM3FILE):
	@if [ ! "`ls -A $(OPENCM3_DIR)`" ] ; then \
		printf "######## ERROR ########\n"; \
		printf "\tlibopencm3 is not initialized.\n"; \
		printf "\tPlease run (in the root directory):\n"; \
		printf "\t$$ git submodule init\n"; \
		printf "\t$$ git submodule update\n"; \
		printf "\tbefore running make.\n"; \
		printf "######## ERROR ########\n"; \
		exit 1; \
		fi
	make -C $(OPENCM3DIR)

.PHONY: clean libclean

clean:
	rm -rf elf/
	rm -rf bin/
	rm -rf bin-host/

libclean:
	make -C $(OPENCM3DIR) clean
