#!/bin/sh
# Собирает программу и testbench, запускает симуляцию. Запуск: sh test/run.sh
set -e

# Из корня проекта: пути fw/test.hex и sim.vcd считаются от текущей папки.
cd "$(dirname "$0")/.."
export PATH="$HOME/fpga/oss-cad-suite/bin:$PATH"

TB=test/tb.sv
TOP=tb
RTL="rtl/picorv32.v rtl/ram.sv rtl/reset.sv rtl/soc.sv"

sh fw/build.sh
iverilog -g2012 -s "$TOP" -o sim.vvp "$TB" $RTL
vvp sim.vvp
