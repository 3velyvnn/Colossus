--!strict

local totp = require("./src/totp")

local secret = totp.generateSecret()
local code = totp.generate(secret)

print("Secret length:", #secret)
print("TOTP code:", string.format("%06d", code))