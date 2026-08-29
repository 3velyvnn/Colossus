--!strict

local totp = require("../src/totp")

local secret = buffer.fromstring("12345678901234567890")

-- HOTP verification
assert(totp.verifyHOTP(secret, 0, 755224))
assert(totp.verifyHOTP(secret, 1, 287082))
assert(not totp.verifyHOTP(secret, 0, 287082))

-- TOTP verification using a fixed timestamp
local encodedSecret = "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ"
local timestamp = 59
local code = totp.generate(encodedSecret, timestamp)

assert(totp.verifyTOTP(encodedSecret, code, timestamp))
assert(not totp.verifyTOTP(encodedSecret, code + 1, timestamp))
assert(not totp.verifyTOTP(encodedSecret, code, timestamp + 30))

print("HOTP and TOTP verification tests passed ✓")

return true
