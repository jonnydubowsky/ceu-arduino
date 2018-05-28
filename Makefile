include Makefile.conf

# make ARD_BOARD=mega ARD_CPU=atmega2560    ARD_PORT=/dev/ttyACM1 CEU_SRC=...
# make ARD_BOARD=pro  ARD_CPU=8MHzatmega328 ARD_PORT=/dev/ttyUSB0 CEU_SRC=...

ifdef CEU_SRC
CEU_SRC_ = $(CEU_SRC)
ifneq ("$(wildcard $(CEU_SRC)/main.ceu)","")
	CEU_SRC_ = $(CEU_SRC)/main.ceu
endif
else
$(error missing `CEU_SRC` path to compile)
endif

ENV_DIR   ?= env
LIBRARIES ?= libraries

PRESERVE = --preserve-temp-files

ARD_ARCH_UPPER  = $(shell echo $(ARD_ARCH)  | tr a-z A-Z)
ARD_CPU_UPPER   = $(shell echo $(ARD_CPU)   | tr a-z A-Z)
ARD_BOARD_UPPER = $(shell echo $(ARD_BOARD) | tr a-z A-Z)

LIBRARIES := $(sort $(dir $(wildcard $(LIBRARIES)/*/)))
CEU_INCS  = $(addprefix -I./, $(addsuffix $(ARD_ARCH)/$(ARD_BOARD)/$(ARD_CPU), $(LIBRARIES))) \
            $(addprefix -I./, $(addsuffix $(ARD_ARCH)/$(ARD_BOARD), $(LIBRARIES)))            \
            $(addprefix -I./, $(addsuffix $(ARD_ARCH), $(LIBRARIES)))                         \
            $(addprefix -I./, $(LIBRARIES))

ifdef ARD_CPU
	ARD_CPU_ := :cpu=$(ARD_CPU)
endif

ARD_PREFS = --pref compiler.cpp.extra_flags="$(CEU_INCS) $(CEU_DEFS)"

all: ceu c

c:
	$(ARD_EXE) --verbose $(PRESERVE) $(ARD_PREFS)                              \
	           --board arduino:$(ARD_ARCH):$(ARD_BOARD)$(ARD_CPU_)             \
	           --port $(ARD_PORT)                                              \
	           --upload $(ENV_DIR)/env.ino

ceu:
	$(CEU_EXE) --pre --pre-args="-include ./ceu/include/arduino/arduino.ceu -I./include/ $(CEU_INCS) -include pm.ceu $(CEU_DEFS) -DCEUMAKER_ARDUINO -DARDUINO_ARCH_$(ARD_ARCH_UPPER) -DARDUINO_MCU_$(ARD_MCU_UPPER) -DARDUINO_BOARD_$(ARD_BOARD_UPPER)" \
	          --pre-input=$(CEU_SRC_)                                           \
	    --ceu --ceu-err-unused=pass --ceu-err-uninitialized=pass               \
	          --ceu-line-directives=true                                       \
	          --ceu-features-lua=false --ceu-features-thread=false             \
	          --ceu-features-isr=static                                        \
	    --env --env-types=$(ENV_DIR)/types.h                                          \
	          --env-output=$(ENV_DIR)/_ceu_app.c.h

pre:
	ceu --pre --pre-args="-include ./include/arduino/arduino.ceu -include ./libraries/arch-$(ARD_ARCH)/$(ARD_ARCH).ceu -I$(CEU_DIR)/include/ -I./include/ $(CEU_INCS) $(CEU_DEFS) -DCEUMAKER_ARDUINO -DARDUINO_ARCH_$(ARD_ARCH_UPPER) -DARDUINO_MCU_$(ARD_MCU_UPPER) -DARDUINO_BOARD_$(ARD_BOARD_UPPER)" --pre-input=$(CEU_SRC_)

.PHONY: all ceu c
