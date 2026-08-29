--!strict
-- Base32 encoding/decoding tests

local base32 = require("../src/base32")

local input = buffer.fromstring("Hello!")
local encoded = base32.encode(input)
local decoded = base32.decode(encoded)

assert(
	encoded == "JBSWY3DPEE",
	`Expected JBSWY3DPEE, got {encoded}`
)

assert(
	buffer.tostring(decoded) == "Hello!",
	"Base32 round-trip failed"
)

print("Base32: ✓")

return true