# Requires MAKEFTROM to be the command to execute makeftrom

.PHONY: all clean dir

JS65_ASM := js65 -Wno-jsr-rts-tail-call -c -g

PATCH_ROM := Legend_of_Zelda,_The_(USA)_(Rev_1).nes
BUILD_BASE_ROM := lozus1256k.nes
GAME_PRE := loz
COMPILE_OPTS := -D ROM_256KB
BHOP_COMPILE_OPTS := -D MMC=1
LINK_OPTS :=
MAKEFTROM_OPTS := --debug

SRCDIR := $(CURDIR)
STEM := $(GAME_PRE)ft
BHOPDIR := bhop
BUILDDIR := build\$(STEM)

# Assembler files, for building out the banks
ROOT_ASM_FILES := $(wildcard $(SRCDIR)/*.s)
BHOP_ASM_FILES := $(BHOPDIR)/bhop.s
O_FILES := \
  $(patsubst $(SRCDIR)/%.s,$(BUILDDIR)/%.o,$(ROOT_ASM_FILES)) \
  $(patsubst $(BHOPDIR)/%.s,$(BUILDDIR)/%.o,$(BHOP_ASM_FILES))

DEMO_STEM := $(GAME_PRE)ftdemo

ifeq ($(DEMO_CFG_NAME),)
DEMO_CFG_NAME := democfg.json5
endif

all: dir $(STEM).nes $(STEM).ips $(STEM).bps $(DEMO_STEM).nes $(DEMO_STEM).ips $(DEMO_STEM).bps

dir:
	-@mkdir -p $(BUILDDIR)

clean:
	-@rm -rf build
	-@rm -f $(STEM).nes
	-@rm -f $(STEM).dbg
	-@rm -f $(DEMO_STEM).nes
	-@rm -f $(DEMO_STEM).dbg

$(STEM).nes: $(O_FILES)
	js65 -r "$(BUILD_BASE_ROM)" -m $(BUILDDIR)/map.txt --dbgfile $(STEM).dbg -o $@ $(value LINK_OPTS) $^

$(BUILDDIR)/%.o: $(SRCDIR)/%.s $(BUILD_BASE_ROM)
	$(JS65_ASM) -I $(BUILDDIR) -I $(BHOPDIR)/bhop -o $@ $(value COMPILE_OPTS) $<

$(BUILDDIR)/%.o: $(BHOPDIR)/%.s
	$(JS65_ASM) -o $@ $(value BHOP_COMPILE_OPTS) $<

$(DEMO_STEM).nes: $(STEM).nes $(STEM).ftcfg $(DEMO_CFG_NAME)
	copy $(STEM).dbg $(DEMO_STEM).dbg
	$(MAKEFTROM) $(value MAKEFTROM_OPTS) --ftcfg $(STEM).ftcfg $(DEMO_CFG_NAME) --input-rom $(STEM).nes --output-rom $(DEMO_STEM).nes
	
%.ips: %.nes
#	Requires Lunar IPS 1.03 from https://fusoya.eludevisibility.org/lips/index.html
	"Lunar IPS.exe" -CreateIPS $@ "$(PATCH_ROM)" $<
	
%.bps: %.nes
#	Requires flips from https://www.romhacking.net/utilities/1040/
	flips --create --bps-delta-moremem --exact "$(PATCH_ROM)" $< $@
