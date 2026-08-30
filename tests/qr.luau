--!strict

local qr = require("../src/qr")
local fs = require("@lute/fs")

local matrix = qr.encode("Hello")

assert(qr.getSize(matrix) == 21, "QR must be Version 1 (21x21)")
assert(qr.countDarkModules(matrix) > 0, "QR must contain dark modules")

-- Check the three finder patterns.
local function assertFinderPattern(
	x: number,
	y: number
)
	for dy = 0, 6 do
		for dx = 0, 6 do
			local expected =
				dx == 0
				or dx == 6
				or dy == 0
				or dy == 6
				or (
					dx >= 2
					and dx <= 4
					and dy >= 2
					and dy <= 4
				)

			assert(
				matrix[y + dy][x + dx] == expected,
				("Finder pattern mismatch at %d,%d"):format(
					x + dx,
					y + dy
				)
			)
		end
	end
end

assertFinderPattern(1, 1)
assertFinderPattern(15, 1)
assertFinderPattern(1, 15)

print("QR structural tests passed.")
print("Size:", qr.getSize(matrix))
print("Dark modules:", qr.countDarkModules(matrix))

-- Check the encoded codewords.
local data, ecc = qr.getCodewords("Hello")

assert(
	#data == 19,
	"Version 1-L must contain 19 data codewords"
)

assert(
	#ecc == 7,
	"Version 1-L must contain 7 ECC codewords"
)

print("Data codewords:")

for i, value in data do
	print(
		i,
		string.format("%02X", value)
	)
end

print("ECC codewords:")

for i, value in ecc do
	print(
		i,
		string.format("%02X", value)
	)
end

-- Verify GF(256) multiplication against QR reference vectors.
local gfTests = {
	{ 0x00, 0x00, 0x00 },
	{ 0x01, 0x01, 0x01 },
	{ 0x02, 0x02, 0x04 },
	{ 0xB2, 0xDD, 0xE6 },
	{ 0x41, 0x11, 0x25 },
	{ 0xB0, 0x1F, 0x11 },
	{ 0x05, 0x75, 0xBC },
	{ 0x52, 0xB5, 0xAE },
}

for _, test in gfTests do
	assert(
		qr.multiplyGF256(test[1], test[2]) == test[3],
		("GF(256) multiplication failed: %02X × %02X")
			:format(test[1], test[2])
	)
end

print("GF(256) tests passed.")

-- Verify the Version 1-L Reed-Solomon generator polynomial.
local generator = qr.getGeneratorPolynomial(7)

print("Generator polynomial:")

for i, value in generator do
	print(
		i,
		string.format("%02X", value)
	)
end

assert(
	#generator == 7,
	"Version 1-L must use 7 generator coefficients"
)

-- Inspect the matrix before masking and format information.
local unmasked = qr.getUnmaskedMatrix("Hello")

print("Unmasked QR:")
qr.printMatrix(unmasked)

-- Print the actual matrix returned by qr.encode(), including
-- mask selection and format information.
print("Final masked QR:")
qr.printMatrix(matrix)

-- Export the final matrix as 0/1 rows for the PNG renderer.
local file = fs.open("qr.matrix", "w")

for y = 1, #matrix do
	for x = 1, #matrix[y] do
		fs.write(file, if matrix[y][x] then "1" else "0")
	end

	fs.write(file, "\n")
end

fs.close(file)
print("Matrix written to qr.matrix")
