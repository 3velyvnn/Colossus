from pathlib import Path
from PIL import Image

matrix = Path("qr.matrix").read_text().splitlines()
matrix = [row.strip() for row in matrix if row.strip()]

size = len(matrix)
assert size == 21, f"Expected 21x21 matrix, got {size}x{len(matrix[0])}"

quiet_zone = 4
scale = 20

image_size = (size + quiet_zone * 2) * scale

image = Image.new("1", (image_size, image_size), 1)
pixels = image.load()

for y, row in enumerate(matrix):
    assert len(row) == size, "Matrix is not square"

    for x, value in enumerate(row):
        if value == "1":
            px = (x + quiet_zone) * scale
            py = (y + quiet_zone) * scale

            for dy in range(scale):
                for dx in range(scale):
                    pixels[px + dx, py + dy] = 0

image.save("qr.png")

print(f"QR PNG written to qr.png ({image_size}x{image_size})")