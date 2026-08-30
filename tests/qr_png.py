from pathlib import Path
import struct
import zlib

INPUT = Path("qr.matrix")
OUTPUT = Path("qr.png")
SCALE = 20
QUIET_ZONE = 4

rows = [line.strip() for line in INPUT.read_text(encoding="utf-8").splitlines() if line.strip()]

if not rows or any(len(row) != len(rows[0]) for row in rows):
    raise SystemExit("qr.matrix is missing or malformed")

if len(rows) != len(rows[0]):
    raise SystemExit("QR matrix must be square")

if any(char not in "01" for row in rows for char in row):
    raise SystemExit("QR matrix may only contain 0 and 1")

size = len(rows)
image_modules = size + QUIET_ZONE * 2
width = image_modules * SCALE

# Grayscale, 8-bit PNG. Each scanline starts with filter type 0.
raw = bytearray()
for y in range(image_modules):
    raw.append(0)
    qr_y = y - QUIET_ZONE
    for _ in range(SCALE):
        for x in range(image_modules):
            qr_x = x - QUIET_ZONE
            dark = (
                0 <= qr_y < size
                and 0 <= qr_x < size
                and rows[qr_y][qr_x] == "1"
            )
            raw.extend(bytes([0 if dark else 255]) * SCALE)


def chunk(kind: bytes, data: bytes) -> bytes:
    return (
        struct.pack(">I", len(data))
        + kind
        + data
        + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF)
    )

png = bytearray(b"\x89PNG\r\n\x1a\n")
png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, width, 8, 0, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(bytes(raw), level=9))
png += chunk(b"IEND", b"")

OUTPUT.write_bytes(png)
print(f"Wrote {OUTPUT} ({width}x{width}) with a {QUIET_ZONE}-module quiet zone.")
