--!strict
--@creator 3velyvnn
--@description QR code generation utilities

local qr = {}

type Matrix = {{boolean}}
type ReservedMatrix = {{boolean}}

qr.ecc = { low = "L", medium = "M", quartile = "Q", high = "H" }

local function createMatrix(size: number): Matrix
	local matrix: Matrix = table.create(size)
	for y = 1, size do matrix[y] = table.create(size, false) end
	return matrix
end

local function createReservedMatrix(size: number): ReservedMatrix
	local reserved: ReservedMatrix = table.create(size)
	for y = 1, size do reserved[y] = table.create(size, false) end
	return reserved
end

local function addFinderPattern(matrix: Matrix, reserved: ReservedMatrix, x: number, y: number)
	for dy = -1, 7 do
		for dx = -1, 7 do
			local px, py = x + dx, y + dy
			if px >= 1 and py >= 1 and px <= #matrix and py <= #matrix then
				reserved[py][px] = true
				local dark = dx >= 0 and dx <= 6 and dy >= 0 and dy <= 6 and
					(dx == 0 or dx == 6 or dy == 0 or dy == 6 or
					(dx >= 2 and dx <= 4 and dy >= 2 and dy <= 4))
				matrix[py][px] = dark
			end
		end
	end
end

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

local EXP = table.create(512)
local LOG = table.create(256)

do
	local value = 1
	for i = 0, 254 do
		EXP[i + 1] = value
		LOG[value + 1] = i
		value *= 2
		if value >= 256 then value = bit32.bxor(value, 0x11D) end
	end
	for i = 255, 511 do EXP[i + 1] = EXP[(i - 255) + 1] end
end

local function multiplyGF256(a: number, b: number): number
	if a == 0 or b == 0 then return 0 end
	return EXP[(LOG[a + 1] + LOG[b + 1]) % 255 + 1]
end

local function createGeneratorPolynomial(errorCorrectionCodewords: number): {number}
	local polynomial = table.create(errorCorrectionCodewords, 0)
	polynomial[errorCorrectionCodewords] = 1
	local root = 1
	for _ = 1, errorCorrectionCodewords do
		for j = 1, errorCorrectionCodewords do
			polynomial[j] = multiplyGF256(polynomial[j], root)
			if j < errorCorrectionCodewords then
				polynomial[j] = bit32.bxor(polynomial[j], polynomial[j + 1])
			end
		end
		root = multiplyGF256(root, 0x02)
	end
	return polynomial
end

local function reedSolomonEncode(data: {number}, errorCorrectionCodewords: number): {number}
	local generator = createGeneratorPolynomial(errorCorrectionCodewords)
	local remainder = table.create(errorCorrectionCodewords, 0)
	for _, value in data do
		local factor = bit32.bxor(value, remainder[1])
		for i = 1, errorCorrectionCodewords - 1 do remainder[i] = remainder[i + 1] end
		remainder[errorCorrectionCodewords] = 0
		for i = 1, errorCorrectionCodewords do
			remainder[i] = bit32.bxor(remainder[i], multiplyGF256(generator[i], factor))
		end
	end
	return remainder
end

local function encodeByteMode(text: string): {number}
	local bytes = table.create(#text)
	for i = 1, #text do bytes[i] = string.byte(text, i) end
	local dataBits = 4 + 8 + (#bytes * 8)
	assert(dataBits <= 152, "text is too long for a Version 1-L QR code")
	local bits = table.create(152)
	local bitCount = 0
	local function appendBits(value: number, count: number)
		for i = count - 1, 0, -1 do
			bitCount += 1
			bits[bitCount] = bit32.band(bit32.rshift(value, i), 1)
		end
	end
	appendBits(0b0100, 4)
	appendBits(#bytes, 8)
	for _, byte in bytes do appendBits(byte, 8) end
	local terminatorLength = math.min(4, 152 - bitCount)
	for _ = 1, terminatorLength do appendBits(0, 1) end
	while bitCount % 8 ~= 0 do appendBits(0, 1) end
	local codewords = table.create(19)
	for i = 1, 19 do
		local value = 0
		for j = 1, 8 do
			value = bit32.bor(bit32.lshift(value, 1), bits[(i - 1) * 8 + j] or 0)
		end
		codewords[i] = value
	end
	local padding = {0xEC, 0x11}
	local paddingIndex = 1
	while #codewords < 19 do
		codewords[#codewords + 1] = padding[paddingIndex]
		paddingIndex = if paddingIndex == 2 then 1 else 2
	end
	return codewords
end

local function codewordsToBits(codewords: {number}): {number}
	local bits = table.create(#codewords * 8)
	local index = 0
	for _, codeword in codewords do
		for bit = 7, 0, -1 do
			index += 1
			bits[index] = bit32.band(bit32.rshift(codeword, bit), 1)
		end
	end
	return bits
end

local function reserveFormatInformation(reserved: ReservedMatrix)
	local size = #reserved
	for i = 1, 9 do
		reserved[8][i] = true
		reserved[i][8] = true
	end
	for x = size - 7, size do reserved[8][x] = true end
	for y = size - 7, size do reserved[y][8] = true end
	reserved[size - 7][9] = true
end

local function maskApplies(mask: number, x: number, y: number): boolean
	if mask == 0 then return (x + y) % 2 == 0
	elseif mask == 1 then return y % 2 == 0
	elseif mask == 2 then return x % 3 == 0
	elseif mask == 3 then return (x + y) % 3 == 0
	elseif mask == 4 then return (math.floor(y / 2) + math.floor(x / 3)) % 2 == 0
	elseif mask == 5 then return (x * y) % 2 + (x * y) % 3 == 0
	elseif mask == 6 then return ((x * y) % 2 + (x * y) % 3) % 2 == 0
	elseif mask == 7 then return ((x * y) % 3 + (x + y) % 2) % 2 == 0
	end
	error("invalid QR mask")
end

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

local function placeData(matrix: Matrix, reserved: ReservedMatrix, bits: {number})
	local size = #matrix
	local bitIndex = 1
	for right = size, 2, -2 do
		if right <= 7 then right -= 1 end
		local upward = bit32.band(right + 1, 2) == 0
		for vert = 0, size - 1 do
			local y = if upward then size - vert else vert + 1
			for j = 0, 1 do
				local x = right - j
				if not reserved[y][x] and bitIndex <= #bits then
					matrix[y][x] = bits[bitIndex] == 1
					bitIndex += 1
				end
			end
		end
	end
	assert(bitIndex == #bits + 1, "QR data placement did not consume all bits")
end

local function calculateBCH(value: number, polynomial: number): number
	local polynomialBits = 0
	local temp = polynomial
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
		if resultBits < polynomialBits then break end
		result = bit32.bxor(result, bit32.lshift(polynomial, resultBits - polynomialBits))
	end
	return bit32.rshift(bit32.bxor(bit32.lshift(value, polynomialBits - 1), result), 0)
end

local function getFormatBits(errorCorrection: string, mask: number): number
	local ecBits = if errorCorrection == "L" then 0b01 elseif errorCorrection == "M" then 0b00 elseif errorCorrection == "Q" then 0b11 elseif errorCorrection == "H" then 0b10 else error("invalid error correction level")
	local data = bit32.bor(bit32.lshift(ecBits, 3), mask)
	local remainder = calculateBCH(data, 0x537)
	return bit32.bxor(bit32.bor(bit32.lshift(data, 10), remainder), 0x5412)
end

local function addFormatInformation(matrix: Matrix, errorCorrection: string, mask: number)
	local format = getFormatBits(errorCorrection, mask)
	local function getBit(index: number): boolean
		return bit32.band(bit32.rshift(format, index), 1) ~= 0
	end
	local topLeft = {
		{8, 1}, {8, 2}, {8, 3}, {8, 4}, {8, 5}, {8, 6}, {8, 7}, {8, 8},
		{7, 8}, {6, 8}, {5, 8}, {4, 8}, {3, 8}, {2, 8}, {1, 8},
	}
	for i = 1, #topLeft do
		local coordinate = topLeft[i]
		matrix[coordinate[2]][coordinate[1]] = getBit(i - 1)
	end
	local size = #matrix
	for i = 0, 7 do matrix[8][size - i] = getBit(i) end
	for i = 0, 6 do matrix[size - i][8] = getBit(8 + i) end
	matrix[size - 7][9] = true
end

local function penaltyRuns(matrix: Matrix): number
	local penalty = 0
	local size = #matrix
	for y = 1, size do
		local runColor = matrix[y][1]
		local runLength = 1
		for x = 2, size do
			if matrix[y][x] == runColor then runLength += 1 else
				if runLength >= 5 then penalty += 3 + (runLength - 5) end
				runColor, runLength = matrix[y][x], 1
			end
		end
		if runLength >= 5 then penalty += 3 + (runLength - 5) end
	end
	for x = 1, size do
		local runColor = matrix[1][x]
		local runLength = 1
		for y = 2, size do
			if matrix[y][x] == runColor then runLength += 1 else
				if runLength >= 5 then penalty += 3 + (runLength - 5) end
				runColor, runLength = matrix[y][x], 1
			end
		end
		if runLength >= 5 then penalty += 3 + (runLength - 5) end
	end
	return penalty
end

local function penaltyBlocks(matrix: Matrix): number
	local penalty = 0
	for y = 1, #matrix - 1 do
		for x = 1, #matrix - 1 do
			local value = matrix[y][x]
			if matrix[y][x + 1] == value and matrix[y + 1][x] == value and matrix[y + 1][x + 1] == value then penalty += 3 end
		end
	end
	return penalty
end

-- QR penalty rule 3: find 00001011101 or 10111010000 in every row and column.
-- These are the 1:1:3:1:1 finder-like pattern with four light modules on one side.
local function penaltyFinderPatterns(matrix: Matrix): number
	local penalty = 0
	local size = #matrix
	local patternA = {false, false, false, false, true, false, true, true, true, false, true}
	local patternB = {true, false, true, true, true, false, true, false, false, false, false}

	local function matches(get: (number) -> boolean, start: number, pattern: {boolean}): boolean
		for i = 1, 11 do
			if get(start + i - 1) ~= pattern[i] then return false end
		end
		return true
	end

	for y = 1, size do
		for x = 1, size - 10 do
			local get = function(index: number): boolean return matrix[y][index] end
			if matches(get, x, patternA) then penalty += 40 end
			if matches(get, x, patternB) then penalty += 40 end
		end
	end

	for x = 1, size do
		for y = 1, size - 10 do
			local get = function(index: number): boolean return matrix[index][x] end
			if matches(get, y, patternA) then penalty += 40 end
			if matches(get, y, patternB) then penalty += 40 end
		end
	end
	return penalty
end

local function penaltyBalance(matrix: Matrix): number
	local size = #matrix
	local dark = 0
	for y = 1, size do
		for x = 1, size do if matrix[y][x] then dark += 1 end end
	end
	local percentage = (dark * 100) / (size * size)
	return math.floor(math.abs(percentage - 50) / 5) * 10
end

local function calculatePenalty(matrix: Matrix): number
	return penaltyRuns(matrix) + penaltyBlocks(matrix) + penaltyFinderPatterns(matrix) + penaltyBalance(matrix)
end

function qr.getCodewords(text: string): ({number}, {number})
	local data = encodeByteMode(text)
	return data, reedSolomonEncode(data, 7)
end

function qr.createMatrix(): Matrix
	local matrix = createMatrix(21)
	local reserved = createReservedMatrix(21)
	addFinderPattern(matrix, reserved, 1, 1)
	addFinderPattern(matrix, reserved, 15, 1)
	addFinderPattern(matrix, reserved, 1, 15)
	addTimingPatterns(matrix, reserved)
	return matrix
end

function qr.encode(text: string, errorCorrection: string?): Matrix
	local data = encodeByteMode(text)
	local ecc = reedSolomonEncode(data, 7)
	local codewords = table.clone(data)
	for _, value in ecc do codewords[#codewords + 1] = value end
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
		local candidate = applyMask(baseMatrix, reserved, mask)
		addFormatInformation(candidate, errorCorrection or "L", mask)
		local penalty = calculatePenalty(candidate)
		if penalty < bestPenalty then
			bestPenalty = penalty
			bestMatrix = candidate
		end
	end
	assert(bestMatrix ~= nil)
	return bestMatrix
end

function qr.printMatrix(matrix: Matrix)
	for y = 1, #matrix do
		local line = ""
		for x = 1, #matrix[y] do line ..= if matrix[y][x] then "██" else "  " end
		print(line)
	end
end

local function countDarkModules(matrix: Matrix): number
	local count = 0
	for y = 1, #matrix do
		for x = 1, #matrix[y] do if matrix[y][x] then count += 1 end end
	end
	return count
end

function qr.getSize(matrix: Matrix): number return #matrix end
function qr.countDarkModules(matrix: Matrix): number return countDarkModules(matrix) end
function qr.multiplyGF256(a: number, b: number): number return multiplyGF256(a, b) end
function qr.getGeneratorPolynomial(errorCorrectionCodewords: number): {number} return createGeneratorPolynomial(errorCorrectionCodewords) end

function qr.getUnmaskedMatrix(text: string): Matrix
	local data = encodeByteMode(text)
	local ecc = reedSolomonEncode(data, 7)
	local codewords = table.clone(data)
	for _, value in ecc do codewords[#codewords + 1] = value end
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