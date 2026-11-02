#!/bin/sh
# Собирает fw/test.S в fw/test.hex для $readmemh. Запуск: sh fw/build.sh
set -e
cd "$(dirname "$0")"

PREFIX=riscv64-unknown-elf-

# -march/-mabi: только базовые инструкции, как в ядре. -nostdlib: без библиотек.
# -Ttext=0: код начинается с адреса 0, откуда стартует CPU после сброса.
${PREFIX}gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttext=0 -o test.elf test.S

# data-width=4: в hex по одному 32-битному слову, как mem[] в ram.sv.
${PREFIX}objcopy -O verilog --verilog-data-width=4 test.elf test.hex

# Листинг: реальные инструкции и их адреса.
${PREFIX}objdump -d test.elf > test.lst

echo "OK: fw/test.hex, листинг в fw/test.lst"
