# picoSoC на Tang Nano 20K
#   make         битстрим top.fs (загрузчик fw/boot.hex внутри)
#   make prog    прошить битстрим в SRAM FPGA (до выключения питания)
#   make load    собрать fw/app.bin и загрузить по UART, затем терминал
#   make tests   тесты в симуляции (test/Makefile)

DEVICE := GW2AR-LV18QN88C8/I7
FAMILY := GW2A-18C
BOARD  := tangnano20k
CST    := tangnano20k.cst
PORT   ?= /dev/ttyUSB1
# Системный python: в нём есть pyserial, а python3 из oss-cad-suite его не видит.
PYTHON ?= /usr/bin/python3

RTL := rtl/soc.sv rtl/picorv32.v rtl/uart.sv rtl/ram.sv rtl/rom.sv

all: top.fs

fw/boot.hex fw/app.bin: FORCE
	$(MAKE) -C fw $(@F)

ysys/netlist.json: $(RTL) fw/boot.hex | ysys
	yosys -m slang -l ysys/ysys.log -p "read_slang $(RTL) --top picosoc; synth_gowin -top picosoc -json $@; stat"

nxtpnr/top_pnr.json: ysys/netlist.json $(CST) | nxtpnr
	nextpnr-himbaechel --json $< --write $@ \
		--device $(DEVICE) --vopt family=$(FAMILY) --vopt cst=$(CST) \
		--freq 27 --log nxtpnr/nxtpnr.log --quiet

top.fs: nxtpnr/top_pnr.json
	gowin_pack -d $(FAMILY) -o $@ $<

prog: top.fs
	openFPGALoader -b $(BOARD) $<

load: fw/app.bin
	$(PYTHON) tools/load.py --port $(PORT) $<

tests:
	$(MAKE) -C test

ysys nxtpnr:
	mkdir -p $@

clean:
	rm -rf ysys nxtpnr top.fs
	$(MAKE) -C fw clean
	$(MAKE) -C test clean

FORCE:

.PHONY: all prog load tests clean FORCE
