---
sidebar_position: 3
---

# TOTP

The `totp` module contains Colossus's HOTP and TOTP implementations.

It handles the full flow from generating secrets to producing and verifying one-time-password codes. TOTP is built on top of the module's `hotp()` function, so both algorithms live together here.

```lua
local totp = require("./src/totp")
```

## HOTP

### `totp.hotp`

```lua
totp.hotp(
    secret: buffer,
    counter: number,
    digits: number?
): number
```

Generates an HOTP code from a binary secret and counter.

The secret must be provided as a `buffer`. The counter is encoded as an 8-byte value before being passed to HMAC-SHA1.

```lua
local secret = buffer.fromstring("12345678901234567890")

local code = totp.hotp(secret, 0)
```

`digits` controls the length of the generated code and defaults to `6`. Values from 1 through 9 are accepted.

The returned code is a number, not a zero-padded string.

### `totp.verifyHOTP`

```lua
totp.verifyHOTP(
    secret: buffer,
    counter: number,
    code: number,
    digits: number?
): boolean
```

Checks whether an HOTP code matches the code generated from the supplied secret and counter.

```lua
local valid = totp.verifyHOTP(secret, 0, code)

print(valid)
```

## TOTP

### `totp.generateSecret`

```lua
totp.generateSecret(): string
```

Generates a new random secret and returns it as a Base32-encoded string.

```lua
local secret = totp.generateSecret()

print(secret)
```

The returned string can be stored and shared with an authenticator application as the TOTP secret.

### `totp.generate`

```lua
totp.generate(
    secret: string,
    timeStamp: number?,
    timeStep: number?,
    digits: number?
): number
```

Generates a TOTP code from a Base32-encoded secret.

If no optional arguments are provided, it uses:

- `os.time()` for the timestamp
- `30` seconds for the time step
- `6` digits for the code

```lua
local code = totp.generate(secret)

print(string.format("%06d", code))
```

You can provide custom values when needed:

```lua
local timestamp = os.time()
local code = totp.generate(secret, timestamp, 60, 8)
```

The time step must be greater than zero, and the digit count must be between 1 and 9.

Internally, `generate()` decodes the Base32 secret and converts the timestamp into an HOTP counter:

```text
Base32 secret
      │
      ▼
  Base32 decode
      │
      ▼
 timestamp / timeStep
      │
      ▼
    counter
      │
      ▼
     HOTP
      │
      ▼
   TOTP code
```

### `totp.verifyTOTP`

```lua
totp.verifyTOTP(
    secret: string,
    code: number,
    timeStamp: number?,
    timeStep: number?,
    digits: number?
): boolean
```

Checks whether a TOTP code matches the code generated from the supplied secret and timestamp.

```lua
local valid = totp.verifyTOTP(secret, code)

print(valid)
```

The optional parameters use the same defaults as `totp.generate()`.

For deterministic verification, pass the same timestamp used to generate the code:

```lua
local timestamp = os.time()

local code = totp.generate(secret, timestamp)
local valid = totp.verifyTOTP(secret, code, timestamp)
```

## Function Overview

| Function | Purpose |
|---|---|
| `hotp()` | Generates an HOTP code |
| `verifyHOTP()` | Verifies an HOTP code |
| `generateSecret()` | Generates a Base32-encoded TOTP secret |
| `generate()` | Generates a TOTP code |
| `verifyTOTP()` | Verifies a TOTP code |

The module uses `crypt.hmacSha1()` for the underlying HMAC-SHA1 operation and `base32` for encoding and decoding TOTP secrets.