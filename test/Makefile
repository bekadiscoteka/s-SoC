# Тесты в симуляции: make (оба), make uart, make boot.
# Запускать из этой папки или из корня: make tests.

PREFIX := riscv64-unknown-elf-
RTL    := $(addprefix ../rtl/, soc.sv picorv32.v uart.sv ram.sv rom.sv)

all: uart boot

uart: build/uart.vvp
	vvp -n $<

boot: build/boot.vvp
	vvp -n $<

build/uart.vvp: tb_uart.sv ../rtl/uart.sv | build
	iverilog -g2012 -o $@ $^

build/boot.vvp: tb_boot.sv $(RTL) ../fw/boot.hex build/frames.hex | build
	iverilog -g2012 -o $@ -DBOOT_HEX='"../fw/boot.hex"' -DFRAMES='"build/frames.hex"' tb_boot.sv $(RTL)

# Загрузчик собирает fw/Makefile, он же следит за его исходниками.
../fw/boot.hex: FORCE
	$(MAKE) -C ../fw boot.hex

# Тестовая программа -> кадры протокола тем же скриптом, что грузит плату.
build/app.bin: app.S | build
	$(PREFIX)gcc -march=rv32i -mabi=ilp32 -nostdlib -Wl,-Ttext=0x80000000 -o build/app.elf $<
	$(PREFIX)objcopy -O binary -j .text build/app.elf $@

build/frames.hex: build/app.bin ../tools/load.py
	python3 ../tools/load.py --emit $@ $<

build:
	mkdir -p $@

clean:
	rm -rf build *.vcd

FORCE:

.PHONY: all uart boot clean FORCE
