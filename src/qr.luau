--!strict
--@creator 3velyvnn
--@description QR code generation utilities

--[=[
	@class qr

	Utilities for generating QR codes.
]=]

local qr = {}

--[=[
	@section Type Definitions
	@description Core types used throughout the QR code generation.
]=]

type Matrix = {
	{boolean}
}

type ReservedMatrix = {
	{boolean}
}

--[=[
	Error correction levels for QR codes.
]=]
qr.ecc = {
	low = "L",
	medium = "M",
	quartile = "Q",
	high = "H",
}

--[=[
	@section Matrix Utilities
	@description Functions for creating and initializing QR code matrices.
]=]

local function createMatrix(size: number): Matrix
	local matrix: Matrix = table.create(size)

	for y = 1, size do
		matrix[y] = table.create(size, false)
	end

	return matrix
end

local function createReservedMatrix(size: number): ReservedMatrix
	local reserved: ReservedMatrix = table.create(size)

	for y = 1, size do
		reserved[y] = table.create(size, false)
	end

	return reserved
end

--[=[
	@section Finder and Timing Patterns
	@description Functions to add finder patterns (position markers) and timing patterns to the QR matrix.
]=]

local function addFinderPattern(matrix: Matrix, reserved: ReservedMatrix, x: number, y: number)
	for dy = -1, 7 do 
		for dx = -1, 7 do
			local px = x + dx
			local py = y + dy

			if px >= 1 and py >= 1
				and px <= #matrix
				and py <= #matrix
			then
				reserved[py][px] = true

				local dark =
					dx >= 0 and dx <= 6
					and dy >= 0 and dy <= 6
					and (
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
					)

				matrix[py][px] = dark
			end
		end
	end
end

-- Adds timing patterns (alternating black and white lines) to the QR matrix.
local function addTimingPatterns(matrix: Matrix, reserved: ReservedMatrix)
	local size = #matrix

	for x = 9, size - 8 do
		reserved[7][x] = true
		matrix[7][x] = x % 2 == 1
	end

	for y = 9, size - 8 do
		reserved[y][7] = true
		matrix[y][7] = y % 2 == 1
	end
end

--[=[
	@section Galois Field (GF(256)) Operations
	@description Implements finite field arithmetic used for Reed-Solomon error correction.
	The QR code standard uses GF(256) with the primitive polynomial x^8 + x^4 + x^3 + x^2 + 1.
]=]

-- GF(256) using the QR Code primitive polynomial x^8 + x^4 + x^3 + x^2 + 1
local EXP = table.create(512)
local LOG = table.create(256)

do
	local value = 1

	for i = 0, 254 do
		EXP[i + 1] = value
		LOG[value + 1] = i

		value *= 2

		if value >= 256 then
			value = bit32.bxor(value, 0x11D)
		end
	end

	for i = 255, 511 do
		EXP[i + 1] = EXP[(i - 255) + 1]
	end
end

-- Multiplies two elements in GF(256) using precomputed logarithm and exponentiation tables.
local function multiplyGF256(a: number, b: number): number
	if a == 0 or b == 0 then
		return 0
	end

	local logA = LOG[a + 1]
	local logB = LOG[b + 1]

	return EXP[(logA + logB) % 255 + 1]
end

-- Creates a generator polynomial for Reed-Solomon error correction.
local function createGeneratorPolynomial(errorCorrectionCodewords: number): {number}
	local polynomial = table.create(errorCorrectionCodewords, 0)

	-- Polynomial coefficients are stored from highest to lowest power,
	-- excluding the implicit leading coefficient of 1.
	-- Start with the monomial x^0.
	polynomial[errorCorrectionCodewords] = 1

	-- Compute:
	-- (x - α^0)(x - α^1)...(x - α^(degree - 1))
	-- where α = 0x02 in GF(256).
	local root = 1

	for _ = 1, errorCorrectionCodewords do
		for j = 1, errorCorrectionCodewords do
			polynomial[j] = multiplyGF256(
				polynomial[j],
				root
			)

			if j < errorCorrectionCodewords then
				polynomial[j] = bit32.bxor(
					polynomial[j],
					polynomial[j + 1]
				)
			end
		end

		root = multiplyGF256(root, 0x02)
	end

	return polynomial
end

-- Encodes data using Reed-Solomon error correction.
-- Encodes data using Reed-Solomon error correction.
local function reedSolomonEncode(data: {number}, errorCorrectionCodewords: number): {number}
	local generator = createGeneratorPolynomial(
		errorCorrectionCodewords
	)

	local remainder = table.create(
		errorCorrectionCodewords,
		0
	)

	for _, value in data do
		local factor = bit32.bxor(
			value,
			remainder[1]
		)

		-- Shift the remainder left by one coefficient.
		for i = 1, errorCorrectionCodewords - 1 do
			remainder[i] = remainder[i + 1]
		end

		remainder[errorCorrectionCodewords] = 0

		-- Subtract the generator * factor.
		-- In GF(256), subtraction is XOR.
		for i = 1, errorCorrectionCodewords do
			remainder[i] = bit32.bxor(
				remainder[i],
				multiplyGF256(
					generator[i],
					factor
				)
			)
		end
	end

	return remainder
end
--[=[
	@section Data Encoding
	@description Functions to encode text data into QR code format with error correction.
]=]

-- Encodes a string in byte mode for QR code generation.
local function encodeByteMode(text: string): {number}
	local bytes = table.create(#text)

	for i = 1, #text do
		bytes[i] = string.byte(text, i)
	end

	local dataBits = 4 + 8 + (#bytes * 8)

	assert(
		dataBits <= 152,
		"text is too long for a Version 1-L QR code"
	)

	local bits = table.create(152)
	local bitCount = 0

	local function appendBits(value: number, count: number)
		for i = count - 1, 0, -1 do
			bitCount += 1

			bits[bitCount] = bit32.band(
				bit32.rshift(value, i),
				1
			)
		end
	end

	-- Byte mode.
	appendBits(0b0100, 4)

	-- Character count.
	appendBits(#bytes, 8)

	-- Data.
	for _, byte in bytes do
		appendBits(byte, 8)
	end

	-- Terminator.
	local terminatorLength = math.min(4, 152 - bitCount)

	for _ = 1, terminatorLength do
		appendBits(0, 1)
	end

	-- Pad to byte boundary.
	while bitCount % 8 ~= 0 do
		appendBits(0, 1)
	end

	local codewords = table.create(19)

	for i = 1, 19 do
		local value = 0

		for j = 1, 8 do
			local bit = bits[(i - 1) * 8 + j] or 0

			value = bit32.bor(
				bit32.lshift(value, 1),
				bit
			)
		end

		codewords[i] = value
	end

	local padding = {
		0xEC,
		0x11,
	}

	local paddingIndex = 1

	while #codewords < 19 do
		codewords[#codewords + 1] = padding[paddingIndex]

		paddingIndex = if paddingIndex == 2 then 1 else 2
	end

	return codewords
end

--[=[
	@section Bit Manipulation
	@description Functions for converting codewords to bits and placing data in the matrix.
]=]

-- Converts codewords to a sequence of bits.
local function codewordsToBits(codewords: {number}): {number}
	local bits = table.create(#codewords * 8)
	local index = 0

	for _, codeword in codewords do
		for bit = 7, 0, -1 do
			index += 1

			bits[index] = bit32.band(
				bit32.rshift(codeword, bit),
				1
			)
		end
	end

	return bits
end

--[=[
	@section Format Information and Matrix Masking
	@description Functions to handle format information, mask patterns, and data placement.
]=]

-- Reserves the format information area in the QR code matrix.
local function reserveFormatInformation(reserved: ReservedMatrix)
	local size = #reserved

	-- Format information around the top-left finder.
	for i = 1, 9 do
		reserved[8][i] = true
		reserved[i][8] = true
	end

	-- Format information beside the top-right finder.
	for x = size - 7, size do
		reserved[8][x] = true
	end

	-- Format information above the bottom-left finder.
	for y = size - 7, size do
		reserved[y][8] = true
	end

	-- Fixed dark module.
	reserved[size - 7][9] = true
end

-- Determines if a mask applies to a given position.
local function maskApplies(mask: number, x: number, y: number): boolean
	if mask == 0 then
		return (x + y) % 2 == 0
	elseif mask == 1 then
		return y % 2 == 0
	elseif mask == 2 then
		return x % 3 == 0
	elseif mask == 3 then
		return (x + y) % 3 == 0
	elseif mask == 4 then
		return (math.floor(y / 2) + math.floor(x / 3)) % 2 == 0
	elseif mask == 5 then
		return (x * y) % 2 + (x * y) % 3 == 0
	elseif mask == 6 then
		return ((x * y) % 2 + (x * y) % 3) % 2 == 0
	elseif mask == 7 then
		return ((x * y) % 3 + (x + y) % 2) % 2 == 0
	end

	error("invalid QR mask")
end

-- Applies a mask to the QR code matrix, inverting bits where the mask pattern applies.
local function applyMask(matrix: Matrix, reserved: ReservedMatrix, mask: number): Matrix
	local result = createMatrix(#matrix)

	for y = 1, #matrix do
		for x = 1, #matrix do
			result[y][x] = matrix[y][x]

			if not reserved[y][x] and maskApplies(mask, x - 1, y - 1) then
				result[y][x] = not result[y][x]
			end
		end
	end

	return result
end

-- Places data bits into the QR code matrix, skipping reserved areas.
local function placeData(matrix: Matrix, reserved: ReservedMatrix, bits: {number})
	local size = #matrix
	local bitIndex = 1

	-- Start at the rightmost column pair and work toward the left.
	for right = size, 2, -2 do
		-- Column 7 (index 7 in one-based coordinates) contains
		-- the vertical timing pattern, so skip it.
		if right <= 7 then
			right -= 1
		end

		-- Alternate traversal direction for each column pair.
		local upward = bit32.band(right + 1, 2) == 0

		for vert = 0, size - 1 do
			local y = if upward
				then size - vert
				else vert + 1

			-- Visit both columns in the pair.
			for j = 0, 1 do
				local x = right - j

				if not reserved[y][x]
					and bitIndex <= #bits
				then
					matrix[y][x] = bits[bitIndex] == 1
					bitIndex += 1
				end
			end
		end
	end

	-- All data bits should have been placed.
	assert(
		bitIndex == #bits + 1,
		"QR data placement did not consume all bits"
	)
end

-- Calculates the BCH code for a given value and polynomial.
local function calculateBCH(value: number, polynomial: number): number
	local valueBits = 0
	local polynomialBits = 0

	local temp = value
	while temp ~= 0 do
		valueBits += 1
		temp = bit32.rshift(temp, 1)
	end

	temp = polynomial
	while temp ~= 0 do
		polynomialBits += 1
		temp = bit32.rshift(temp, 1)
	end

	local result = bit32.lshift(value, polynomialBits - 1)

	while true do
		local resultBits = 0
		temp = result

		while temp ~= 0 do
			resultBits += 1
			temp = bit32.rshift(temp, 1)
		end

		if resultBits < polynomialBits then
			break
		end

		result = bit32.bxor(
			result,
			bit32.lshift(
				polynomial,
				resultBits - polynomialBits
			)
		)
	end

	return bit32.rshift(
		bit32.bxor(
			bit32.lshift(value, polynomialBits - 1),
			result
		),
		0
	)
end

-- Calculates the format bits for a given error correction level and mask.
local function getFormatBits(errorCorrection: string, mask: number): number
	local ecBits = if errorCorrection == "L"
		then 0b01
		elseif errorCorrection == "M"
		then 0b00
		elseif errorCorrection == "Q"
		then 0b11
		elseif errorCorrection == "H"
		then 0b10
		else error("invalid error correction level")

	local data = bit32.bor(
		bit32.lshift(ecBits, 3),
		mask
	)

	local remainder = calculateBCH(data, 0x537)

	local format = bit32.bor(
		bit32.lshift(data, 10),
		remainder
	)

	-- QR format information mask.
	return bit32.bxor(format, 0x5412)
end

-- Adds format information to the QR code matrix based on error correction level and mask.
local function addFormatInformation(matrix: Matrix, errorCorrection: string, mask: number)
	local format = getFormatBits(errorCorrection, mask)

	local function getBit(index: number): boolean
		return bit32.band(
			bit32.rshift(format, index),
			1
		) ~= 0
	end

	-- Format information coordinates.
	--
	-- These are the 15 format modules surrounding the
	-- top-left finder pattern.
	local topLeft = {
		{ 8, 1 },
		{ 8, 2 },
		{ 8, 3 },
		{ 8, 4 },
		{ 8, 5 },
		{ 8, 6 },
		{ 8, 7 },
		{ 8, 8 },
		{ 7, 8 },
		{ 6, 8 },
		{ 5, 8 },
		{ 4, 8 },
		{ 3, 8 },
		{ 2, 8 },
		{ 1, 8 },
	}

	-- First copy.
	for i = 1, #topLeft do
		local coordinate = topLeft[i]

		matrix[coordinate[2]][coordinate[1]] =
			getBit(i - 1)
	end

	-- Second copy beside the other finder patterns.
	local size = #matrix

	-- Horizontal copy.
	for i = 0, 7 do
		matrix[8][size - i] = getBit(i)
	end

	-- Vertical copy.
	for i = 0, 6 do
		matrix[size - i][8] = getBit(8 + i)
	end

	-- Mandatory dark module.
	matrix[size - 7][9] = true
end

--[=[
	@section Penalty Scoring
	@description Functions to calculate penalties used for mask pattern selection.
	Lower penalty scores indicate better mask patterns for visual scanning.
]=]

local function penaltyRuns(matrix: Matrix): number
	local penalty = 0
	local size = #matrix

	-- Rows
	for y = 1, size do
		local runColor = matrix[y][1]
		local runLength = 1

		for x = 2, size do
			if matrix[y][x] == runColor then
				runLength += 1
			else
				if runLength >= 5 then
					penalty += 3 + (runLength - 5)
				end

				runColor = matrix[y][x]
				runLength = 1
			end
		end

		if runLength >= 5 then
			penalty += 3 + (runLength - 5)
		end
	end

	-- Columns
	for x = 1, size do
		local runColor = matrix[1][x]
		local runLength = 1

		for y = 2, size do
			if matrix[y][x] == runColor then
				runLength += 1
			else
				if runLength >= 5 then
					penalty += 3 + (runLength - 5)
				end

				runColor = matrix[y][x]
				runLength = 1
			end
		end

		if runLength >= 5 then
			penalty += 3 + (runLength - 5)
		end
	end

	return penalty
end

-- Calculates penalty for 2x2 blocks of the same color.
local function penaltyBlocks(matrix: Matrix): number
	local penalty = 0
	local size = #matrix

	for y = 1, size - 1 do
		for x = 1, size - 1 do
			local value = matrix[y][x]

			if matrix[y][x + 1] == value
				and matrix[y + 1][x] == value
				and matrix[y + 1][x + 1] == value
			then
				penalty += 3
			end
		end
	end

	return penalty
end

-- Calculates penalty for finder-like patterns that appear outside the actual finder patterns.
local function penaltyFinderPatterns(matrix: Matrix): number
	local penalty = 0
	local size = #matrix

	local function isFinderPattern(
		get: (number) -> boolean,
		start: number
	): boolean
		local pattern = {
			false,
			false,
			false,
			false,
			true,
			false,
			true,
			true,
			true,
			false,
			true,
		}

		for i = 1, #pattern do
			if get(start + i - 1) ~= pattern[i] then
				return false
			end
		end

		return true
	end

	--> Horizontal patterns
	for y = 1, size do
		for x = 1, size - 10 do
			if isFinderPattern(
				function(index)
					return matrix[y][index]
				end,
				x
			) then
				penalty += 40
			end
		end
	end

	--> Vertical patterns
	for x = 1, size do
		for y = 1, size - 10 do
			if isFinderPattern(
				function(index)
					return matrix[index][x]
				end,
				y
			) then
				penalty += 40
			end
		end
	end

	return penalty
end

-- Calculates penalty based on the balance of dark and light modules.
local function penaltyBalance(matrix: Matrix): number
	local size = #matrix
	local total = size * size
	local dark = 0

	for y = 1, size do
		for x = 1, size do
			if matrix[y][x] then
				dark += 1
			end
		end
	end

	local percentage = (dark * 100) / total
	local deviation = math.abs(percentage - 50)

	return math.floor(deviation / 5) * 10
end

local function calculatePenalty(matrix: Matrix): number
	return penaltyRuns(matrix)
		+ penaltyBlocks(matrix)
		+ penaltyFinderPatterns(matrix)
		+ penaltyBalance(matrix)
end

--[=[
	@section Public API
	@description Main functions exposed for QR code generation and visualization.
]=]


--[=[
	Returns the data and error correction codewords for a string.

	@param text string -- The text to encode.
	@return {number}, {number} -- Data codewords and error correction codewords.
]=]
function qr.getCodewords(text: string): ({number}, {number})
	local data = encodeByteMode(text)
	local ecc = reedSolomonEncode(data, 7)

	return data, ecc
end

--[=[
	Creates a Version 1 QR matrix.

	@return Matrix -- The QR code matrix.
]=]
function qr.createMatrix(): Matrix
	local matrix = createMatrix(21)
	local reserved = createReservedMatrix(21)

	addFinderPattern(matrix, reserved, 1, 1)
	addFinderPattern(matrix, reserved, 15, 1)
	addFinderPattern(matrix, reserved, 1, 15)

	addTimingPatterns(matrix, reserved)

	return matrix
end

--[=[
	Generates a QR code matrix from text.

	@param text string -- The text to encode.
	@param errorCorrection string? -- The error correction level.
	@return Matrix -- The generated QR code matrix.
]=]
function qr.encode(text: string, errorCorrection: string?): Matrix
	local data = encodeByteMode(text)

	local ecc = reedSolomonEncode(data, 7)

	local codewords = table.clone(data)

	for _, value in ecc do
		codewords[#codewords + 1] = value
	end

	local bits = codewordsToBits(codewords)

	local baseMatrix = createMatrix(21)
	local reserved = createReservedMatrix(21)

	addFinderPattern(baseMatrix, reserved, 1, 1)
	addFinderPattern(baseMatrix, reserved, 15, 1)
	addFinderPattern(baseMatrix, reserved, 1, 15)

	addTimingPatterns(baseMatrix, reserved)
	reserveFormatInformation(reserved)

	placeData(baseMatrix, reserved, bits)

	local bestMatrix: Matrix? = nil
	local bestPenalty = math.huge

	for mask = 0, 7 do
		local candidate = applyMask(
			baseMatrix,
			reserved,
			mask
		)

		addFormatInformation(
			candidate,
			errorCorrection or "L",
			mask
		)

		local penalty = calculatePenalty(candidate)

		if penalty < bestPenalty then
			bestPenalty = penalty
			bestMatrix = candidate
		end
	end

	assert(bestMatrix ~= nil)

	return bestMatrix
end

--[=[
	Prints a QR matrix to the terminal.

	@param matrix Matrix -- The QR code matrix.
]=]
function qr.printMatrix(matrix: Matrix)
	for y = 1, #matrix do
		local line = ""

		for x = 1, #matrix[y] do
			line ..= if matrix[y][x] then "██" else "  "
		end

		print(line)
	end
end

local function countDarkModules(matrix: Matrix): number
	local count = 0

	for y = 1, #matrix do
		for x = 1, #matrix[y] do
			if matrix[y][x] then
				count += 1
			end
		end
	end

	return count
end

--[=[
    Returns the size of the QR matrix.

    @param matrix Matrix -- The QR code matrix.
    @return number -- The size of the matrix (width/height).
]=]
function qr.getSize(matrix: Matrix): number
	return #matrix
end

--[=[
    Counts the number of dark modules in the QR matrix.

    @param matrix Matrix -- The QR code matrix.
    @return number -- The count of dark modules.
]=]
function qr.countDarkModules(matrix: Matrix): number
	return countDarkModules(matrix)
end

--[=[
	Multiplies two values in QR's GF(256) field.

	@param a number -- First field element.
	@param b number -- Second field element.
	@return number -- The field product.
]=]
function qr.multiplyGF256(a: number, b: number): number
	return multiplyGF256(a, b)
end

--[=[
	Returns the Reed-Solomon generator polynomial.

	@param errorCorrectionCodewords number -- Number of ECC codewords.
	@return {number} -- Generator polynomial coefficients.
]=]
function qr.getGeneratorPolynomial(errorCorrectionCodewords: number): {number}
	return createGeneratorPolynomial(errorCorrectionCodewords)
end

--[=[
	Generates a QR matrix before masking and format information.

	@param text string -- The text to encode.
	@return Matrix -- The unmasked QR matrix.
]=]
function qr.getUnmaskedMatrix(text: string): Matrix
	local data = encodeByteMode(text)
	local ecc = reedSolomonEncode(data, 7)

	local codewords = table.clone(data)

	for _, value in ecc do
		codewords[#codewords + 1] = value
	end

	local bits = codewordsToBits(codewords)

	local matrix = createMatrix(21)
	local reserved = createReservedMatrix(21)

	addFinderPattern(matrix, reserved, 1, 1)
	addFinderPattern(matrix, reserved, 15, 1)
	addFinderPattern(matrix, reserved, 1, 15)

	addTimingPatterns(matrix, reserved)
	reserveFormatInformation(reserved)

	placeData(matrix, reserved, bits)

	return matrix
end

return qr