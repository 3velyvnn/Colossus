---
sidebar_position: 2
---

# Getting Started

Colossus gives you the pieces needed to work with **HOTP** and **TOTP** in Luau, from generating secrets to creating one-time-password codes.

## TOTP

TOTP is probably the easiest place to start. Generate a secret, then use that secret to create a code:

```lua
local totp = require("./src/totp")

local secret = totp.generateSecret()
local code = totp.generate(secret)

print("Secret:", secret)
print(string.format("%06d", code))
```

### Generating a Secret

`generateSecret()` creates a randomly generated secret and returns it as a Base32-encoded string:

```lua
local secret = totp.generateSecret()
```

Keep this secret private. You'll reuse it whenever you need to generate or verify codes for the same authenticator.

### Generating a Code

Pass the secret to `generate()` to create a TOTP code:

```lua
local code = totp.generate(secret)
```

By default, Colossus uses:

- The current Unix timestamp
- A 30-second time step
- 6-digit codes

You can provide your own values when needed:

```lua
local code = totp.generate(secret, timestamp, 30, 6)
```

Both the timestamp and time step are measured in seconds.

## HOTP

HOTP works similarly to TOTP, but uses a counter instead of the current time:

```lua
local code = totp.hotp(secret, counter)
```

You can also choose the number of digits:

```lua
local code = totp.hotp(secret, counter, 8)
```

Both `hotp()` and `generate()` return the code as a number.

## Lower-Level Utilities

Colossus keeps its lower-level building blocks available as separate modules, so you can use them directly if you need them.

### HMAC-SHA1

The `crypt` module provides HMAC-SHA1:

```lua
local crypt = require("./src/crypt")

local digest = crypt.hmacSha1(key, message)
```

You can also generate a random 32-byte key:

```lua
local key = crypt.generateKey()
```

### Base32

The `base32` module handles encoding and decoding between strings and buffers:

```lua
local base32 = require("./src/base32")

local encoded = base32.encode(data)
local decoded = base32.decode(encoded)
```

These utilities are used internally by TOTP, but they're available independently if you need them for something else.

## Where to Go Next

- **TOTP** — Learn more about time-based one-time passwords.
- **HOTP** — Learn more about counter-based one-time passwords.
- **Cryptography** — Explore the HMAC-SHA1 and Base32 building blocks.
- **API Reference** — Browse the complete generated API documentation.