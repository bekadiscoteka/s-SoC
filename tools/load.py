#!/usr/bin/env python3
"""Загрузка программы в picoSoC по UART (протокол: doc/bootloader.md), затем терминал.

    python3 tools/load.py --port /dev/ttyUSB1 fw/app.bin   загрузить и открыть терминал
    python3 tools/load.py --emit frames.hex app.bin        кадры протокола для test/tb_boot.sv

Выход из терминала: Ctrl+].
"""
import argparse
import struct
import sys
import time
import zlib

MAGIC = b"listen"
ADDR = 0x80000000
SIZE_LIMIT = 30720  # boot.c принимает size < RAM_SIZE
BAUD = 115200


def frames(data):
    """Заголовок (16 байт) и тело (программа + CRC32), little-endian, CRC как zlib.crc32."""
    if not 0 < len(data) < SIZE_LIMIT:
        sys.exit(f"размер программы {len(data)} байт, допустимо 1..{SIZE_LIMIT - 1}")
    head = MAGIC + struct.pack("<IH", ADDR, len(data))
    head += struct.pack("<I", zlib.crc32(head))
    body = data + struct.pack("<I", zlib.crc32(data))
    return head, body


def wait_byte(ser, wanted, timeout):
    """Ждать один из байтов wanted; всё остальное показать как вывод платы."""
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        b = ser.read(1)
        if b and b in wanted:
            return b
        if b:
            sys.stdout.buffer.write(b)
            sys.stdout.flush()
    return None


def load(ser, head, body):
    for _ in range(3):
        ser.reset_input_buffer()
        ser.write(head)
        r = wait_byte(ser, b"YN", 0.5)
        if r is None:
            print("\n[load] загрузчик молчит, нажми S1 на плате", file=sys.stderr)
            if not wait_byte(ser, b">", 30):
                sys.exit("[load] нет приглашения '>'")
            continue
        if r == b"N":
            wait_byte(ser, b">", 1)  # после N загрузчик ждёт тишину и печатает '>'
            continue

        ser.write(body)
        r = wait_byte(ser, b"YN", 1 + 2 * len(body) * 10 / BAUD)
        if r == b"Y":
            print(f"[load] загружено {len(body) - 4} байт", file=sys.stderr)
            return
        if r is None:
            sys.exit("[load] нет ответа на данные")
        wait_byte(ser, b">", 1)
    sys.exit("[load] не удалось загрузить за 3 попытки")


def terminal(ser):
    from serial.tools.miniterm import Miniterm

    term = Miniterm(ser, eol="lf", filters=["direct"])
    term.exit_character = "\x1d"  # Ctrl+]
    term.set_rx_encoding("utf-8")
    term.set_tx_encoding("utf-8")
    print("[load] терминал, выход: Ctrl+]", file=sys.stderr)
    term.start()
    try:
        term.join(True)
    except KeyboardInterrupt:
        pass
    term.join()
    term.close()


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("bin", help="программа: сырой .bin, слинкованный на 0x80000000")
    p.add_argument("--port", default="/dev/ttyUSB1")
    p.add_argument("--emit", metavar="FILE", help="не грузить, а записать кадры в hex по байту на строку")
    p.add_argument("--no-term", action="store_true", help="не открывать терминал после загрузки")
    a = p.parse_args()

    with open(a.bin, "rb") as f:
        head, body = frames(f.read())

    if a.emit:
        with open(a.emit, "w") as f:
            f.writelines(f"{b:02x}\n" for b in head + body)
        return

    import serial

    with serial.Serial(a.port, BAUD, timeout=0.05) as ser:
        load(ser, head, body)
        if not a.no_term:
            terminal(ser)


if __name__ == "__main__":
    main()
