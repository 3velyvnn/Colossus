--!strict

local totp = require("./src/totp")

local secret = totp.generateSecret()
local code = totp.generate(secret)

-- you're not getting the secret from me, but you can use this to test your own TOTP implementation
print("Secret length:", #secret)
print("TOTP code:", string.format("%06d", code))