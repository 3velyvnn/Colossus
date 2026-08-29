# Colossus

A modular Luau authentication library implementing HOTP and TOTP from the ground up.

## Features

- HOTP
- TOTP
- HMAC-SHA1
- Base32 encoding and decoding
- Cryptographically random TOTP secrets
- RFC 4226 and RFC 6238 test vectors

## Usage

```lua
local totp = require("./src/totp")

local secret = totp.generateSecret()
local code = totp.generate(secret)

print(string.format("%06d", code))
```