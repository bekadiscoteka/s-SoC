#!/bin/sh
# Собирает fw/test.S в fw/test.hex для $readmemh. Запуск: sh fw/build.sh
set -e
cd "$(dirname "$0")"

PREFIX=riscv64-unknown-elf-
TEST=test_uart
OUT=test_uart

# -march/-mabi: только базовые инструкции, как в ядре. -nostdlib: без библиотек.
# -Ttext=0: код начинается с адреса 0, откуда стартует CPU после сброса.
${PREFIX}gcc -march=rv32i -mabi=ilp32 -nostdlib -Ttext=0 -o ${OUT}.elf ${TEST}.S

# data-width=4: в hex по одному 32-битному слову, как mem[] в ram.sv.
${PREFIX}objcopy -O verilog --verilog-data-width=4 ${OUT}.elf test.hex

# Листинг: реальные инструкции и их адреса.
${PREFIX}objdump -d ${OUT}.elf > ${OUT}.lst

echo "OK: fw/test.hex, листинг в fw/${OUT}.lst"
