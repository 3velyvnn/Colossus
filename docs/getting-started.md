---
sidebar_position: 2
---

# Getting Started

Colossus provides HOTP and TOTP primitives for Luau, along with the cryptographic and encoding utilities they rely on.

## TOTP

The simplest way to use Colossus is to generate a secret and create a TOTP code from it.

```luau
local totp = require("./src/totp")

local secret = totp.generateSecret()
local code = totp.generate(secret)

print("Secret:", secret)
print(string.format("%06d", code))
```

### Generating a Secret

`generateSecret()` creates a cryptographically random secret and returns it as a Base32-encoded string.

```luau
local secret = totp.generateSecret()
```

The secret is intended to be kept private and reused when generating codes for the same authenticator.

### Generating a Code

Pass the Base32-encoded secret to `generate()`:

```luau
local code = totp.generate(secret)
```

By default, Colossus uses:

- The current Unix timestamp
- A 30-second time step
- 6-digit codes

These values can be overridden:

```luau
local code = totp.generate(secret, timestamp, 30, 6)
```

The timestamp and time step are measured in seconds.

## HOTP

Colossus also exposes HOTP directly:

```luau
local code = totp.hotp(secret, counter)
```

Unlike TOTP, HOTP is based on a counter rather than the current time.

The number of digits can also be customized:

```luau
local code = totp.hotp(secret, counter, 8)
```

Both `hotp()` and `generate()` return the code as a number.

## Lower-Level Utilities

Colossus exposes the underlying building blocks as separate modules.

### HMAC-SHA1

The `crypt` module provides HMAC-SHA1:

```luau
local crypt = require("./src/crypt")

local digest = crypt.hmacSha1(key, message)
```

It also provides cryptographically random 32-byte keys:

```luau
local key = crypt.generateKey()
```

### Base32

The `base32` module provides encoding and decoding between strings and buffers:

```luau
local base32 = require("./src/base32")

local encoded = base32.encode(data)
local decoded = base32.decode(encoded)
```

These utilities are used internally by the TOTP implementation, but are also available independently when needed.

## Next Steps

- **TOTP** — Learn how time-based one-time passwords work with Colossus.
- **HOTP** — Learn how counter-based one-time passwords work.
- **Cryptography** — Explore Colossus's HMAC-SHA1 and Base32 primitives.
- **API Reference** — Browse the complete generated API documentation.