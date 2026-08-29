--!strict

local base32 = {}
const BASE32_ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"

--[=[
	Decodes a Base32-encoded string into a buffer.

	@param input The Base32-encoded string.
	@return The decoded bytes as a buffer.
]=]

function base32.decode(input: string): buffer
	input = string.upper(input)
	input = string.gsub(input, "[= ]", "")

	local output = buffer.create(math.floor(#input * 5 / 8))
	local outputIndex = 0

	local bitBuffer = 0
	local bitCount = 0

	for i = 1, #input do
		local character = string.sub(input, i, i)
		local value = string.find(BASE32_ALPHABET, character, 1, true)

		assert(value ~= nil, `Invalid Base32 character: {character}`)

		value -= 1

		bitBuffer = bit32.bor(bit32.lshift(bitBuffer, 5), value)
		bitCount += 5

		while bitCount >= 8 do
			bitCount -= 8

			local byte = bit32.band(
				bit32.rshift(bitBuffer, bitCount),
				0xFF
			)

			buffer.writeu8(output, outputIndex, byte)
			outputIndex += 1
		end
	end

	return output
end

--[=[
	Encodes a buffer as a Base32 string.

	@param input The bytes to encode.
	@return The Base32-encoded string.
]=]

function base32.encode(input: buffer): string
	local output = ""
	local bitBuffer = 0
	local bitCount = 0

	for i = 0, buffer.len(input) - 1 do
		bitBuffer = bit32.bor(
			bit32.lshift(bitBuffer, 8),
			buffer.readu8(input, i)
		)
		bitCount += 8

		while bitCount >= 5 do
			bitCount -= 5

			local index = bit32.band(
				bit32.rshift(bitBuffer, bitCount),
				0x1F
			) + 1

			output ..= string.sub(BASE32_ALPHABET, index, index)
		end
	end

	if bitCount > 0 then
		local index = bit32.band(
			bit32.lshift(bitBuffer, 5 - bitCount),
			0x1F
		) + 1

		output ..= string.sub(BASE32_ALPHABET, index, index)
	end

	return output
end

return base32