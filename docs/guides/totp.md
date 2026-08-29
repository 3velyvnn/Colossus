---
sidebar_position: 1
---

# TOTP

**Time-based One-Time Password (TOTP)** is an extension of HOTP that replaces the counter with the current time.

Colossus implements TOTP using **HMAC-SHA1**, with Base32-encoded secrets and a configurable time step.

## Generating a TOTP Secret

Use `generateSecret()` to create a new cryptographically random secret:

```luau
local totp = require("./src/totp")

local secret = totp.generateSecret()

print(secret)
```

The returned value is a **Base32-encoded string**.

Keep the secret private. It is the shared value used to generate TOTP codes.

## Generating a Code

Pass the secret to `generate()`:

```luau
local code = totp.generate(secret)

print(string.format("%06d", code))
```

When no optional arguments are supplied, Colossus uses the current Unix timestamp, a 30-second time step, and 6-digit codes.

## Verifying a Code

Use `verifyTOTP()` to check whether a supplied code matches the code generated for a secret and timestamp:

```luau
local valid = totp.verifyTOTP(secret, code)

print(valid)
```

It returns `true` when the supplied code matches and `false` otherwise.

You can provide the same optional timestamp, time step, and digit count used by `generate()`:

```luau
local valid = totp.verifyTOTP(secret, code, timestamp, 30, 6)
```

For deterministic verification, provide an explicit timestamp:

```luau
local timestamp = os.time()
local code = totp.generate(secret, timestamp)

local valid = totp.verifyTOTP(secret, code, timestamp)
```

## Custom Timestamp

A timestamp can be supplied explicitly to `generate()` or `verifyTOTP()`.

```luau
local timestamp = os.time()
local code = totp.generate(secret, timestamp)
local valid = totp.verifyTOTP(secret, code, timestamp)
```

This is useful when you need deterministic behavior, such as testing against known TOTP test vectors.

## Custom Time Step

The time step controls how frequently the TOTP counter changes.

```luau
local code = totp.generate(secret, os.time(), 60)
```

This example uses a 60-second time step instead of the default 30 seconds.

The same time step must be supplied when verifying the code:

```luau
local valid = totp.verifyTOTP(secret, code, os.time(), 60)
```

The time step must be greater than zero.

## Custom Code Length

Colossus allows TOTP codes from 1 to 9 digits:

```luau
local code = totp.generate(secret, os.time(), 30, 8)
local valid = totp.verifyTOTP(secret, code, os.time(), 30, 8)
```

The default is 6 digits.

## How It Works

Internally, `generate()` performs these steps:

1. Decodes the Base32 secret into a byte buffer.
2. Determines the timestamp to use.
3. Divides the timestamp by the configured time step.
4. Floors the result to produce the HOTP counter.
5. Passes the decoded secret and counter to `hotp()`.
6. HOTP computes the HMAC-SHA1 digest and dynamically truncates it.
7. The resulting integer is reduced to the requested number of digits.

`verifyTOTP()` generates the expected code using the same parameters and compares it with the supplied code.

Conceptually:

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

## API

### `totp.generate`

```luau
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

```luau
totp.verifyTOTP(
    secret: string,
    code: number,
    timeStamp: number?,
    timeStep: number?,
    digits: number?
): boolean
```

Verifies a TOTP code using the same generation parameters as `totp.generate()`.

### `totp.generateSecret`

```luau
totp.generateSecret(): string
```

Generates a cryptographically random TOTP secret encoded as Base32.
