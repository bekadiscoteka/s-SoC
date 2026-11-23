# Прошивки:
#   boot.hex  загрузчик, лежит в ROM и попадает в битстрим ($readmemh в rom.sv)
#   app.bin   программа пользователя, грузится в RAM по UART (make load)

PREFIX := riscv64-unknown-elf-
CFLAGS := -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -O2 -Wall

BOOT_SRC := boot.S boot.c
APP_LD   := app.ld
APP_SRC  := crt0.S main.c wait.S

all: boot.hex app.bin

boot.elf: boot.ld $(BOOT_SRC)
	$(PREFIX)gcc $(CFLAGS) -Tboot.ld -o $@ $(BOOT_SRC)

app.elf: $(APP_LD) $(APP_SRC)
	$(PREFIX)gcc $(CFLAGS) -T$(APP_LD) -o $@ $(APP_SRC)

boot.hex: boot.elf
	$(PREFIX)objcopy -O verilog --verilog-data-width=4 $< $@

app.bin: app.elf
	$(PREFIX)objcopy -O binary $< $@

# Листинг для отладки: make boot.lst / make app.lst
%.lst: %.elf
	$(PREFIX)objdump -h -d $< > $@

clean:
	rm -f *.elf *.hex *.bin *.lst

.PHONY: all clean
