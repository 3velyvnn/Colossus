---
sidebar_position: 1
---

# TOTP

**Time-based One-Time Password (TOTP)** is a form of one-time-password authentication that uses the current time instead of a counter.

Colossus builds TOTP on top of **HMAC-SHA1**, using Base32-encoded secrets and a configurable time step.

## Generating a TOTP Secret

Use `generateSecret()` to create a new secret:

```lua
local totp = require("./src/totp")

local secret = totp.generateSecret()

print(secret)
```

The returned value is a **Base32-encoded string**.

The secret is shared between the system generating the codes and the authenticator verifying them, so it should be kept private.

## Generating a Code

Pass the secret to `generate()`:

```lua
local code = totp.generate(secret)

print(string.format("%06d", code))
```

By default, Colossus uses the current Unix timestamp, a 30-second time step, and 6-digit codes.

## Verifying a Code

Use `verifyTOTP()` to check whether a code is valid for a given secret:

```lua
local valid = totp.verifyTOTP(secret, code)

print(valid)
```

It returns `true` if the code matches and `false` otherwise.

The timestamp, time step, and digit count can be specified explicitly:

```lua
local valid = totp.verifyTOTP(secret, code, timestamp, 30, 6)
```

For deterministic verification, use the same timestamp when generating and verifying the code:

```lua
local timestamp = os.time()
local code = totp.generate(secret, timestamp)

local valid = totp.verifyTOTP(secret, code, timestamp)
```

## Custom Timestamp

Both `generate()` and `verifyTOTP()` accept an optional timestamp.

```lua
local timestamp = os.time()

local code = totp.generate(secret, timestamp)
local valid = totp.verifyTOTP(secret, code, timestamp)
```

Providing a timestamp explicitly is particularly useful when testing against known TOTP test vectors.

## Custom Time Step

The time step determines how often the TOTP counter changes.

```lua
local code = totp.generate(secret, os.time(), 60)
```

This uses a 60-second time step instead of the default 30 seconds.

The same time step needs to be used when verifying the code:

```lua
local valid = totp.verifyTOTP(secret, code, os.time(), 60)
```

The time step must be greater than zero.

## Custom Code Length

TOTP codes can be between 1 and 9 digits:

```lua
local code = totp.generate(secret, os.time(), 30, 8)
local valid = totp.verifyTOTP(secret, code, os.time(), 30, 8)
```

The default is 6 digits.

## How It Works

TOTP is built on top of HOTP. Instead of keeping a counter that increases after each use, TOTP derives the counter from the current Unix timestamp.

When `generate()` is called, Colossus:

1. Decodes the Base32 secret into a byte buffer.
2. Gets the provided timestamp, or the current time if none was provided.
3. Divides the timestamp by the configured time step.
4. Floors the result to obtain the HOTP counter.
5. Passes the secret and counter to `hotp()`.
6. HOTP calculates the HMAC-SHA1 digest and applies dynamic truncation.
7. The resulting value is reduced to the requested number of digits.

In simplified form:

```text
Unix timestamp
      │
      ▼
timestamp / timeStep
      │
      ▼
   floor(...)
      │
      ▼
   counter
      │
      ▼
     HOTP
      │
      ▼
   TOTP code
      │
      ▼
 verifyTOTP()
      │
      ▼
 true / false
```

`verifyTOTP()` follows the same process to generate the expected code, then compares it with the supplied value.

## API

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

| Parameter | Type | Default |
|---|---|---|
| `secret` | `string` | — |
| `timeStamp` | `number?` | `os.time()` |
| `timeStep` | `number?` | `30` |
| `digits` | `number?` | `6` |

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

Checks whether a TOTP code matches the code generated from the supplied secret and parameters.

### `totp.generateSecret`

```lua
totp.generateSecret(): string
```

Generates a randomly generated TOTP secret and returns it as a Base32-encoded string.