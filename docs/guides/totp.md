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

When no optional arguments are supplied, Colossus:

- Uses the current Unix timestamp.
- Uses a 30-second time step.
- Generates a 6-digit code.

## Custom Timestamp

A timestamp can be supplied explicitly.

```luau
local timestamp = os.time()
local code = totp.generate(secret, timestamp)
```

This is useful when you need deterministic code generation, such as testing against known TOTP test vectors.

## Custom Time Step

The time step controls how frequently the TOTP counter changes.

```luau
local code = totp.generate(secret, os.time(), 60)
```

This example uses a 60-second time step instead of the default 30 seconds.

The time step must be greater than zero.

## Custom Code Length

Colossus allows TOTP codes from 1 to 9 digits:

```luau
local code = totp.generate(secret, os.time(), 30, 8)

print(string.format("%08d", code))
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
```

## Testing With a Fixed Timestamp

Because `generate()` accepts a timestamp, you can use fixed timestamps when testing:

```luau
local code = totp.generate(
    secret,
    timestamp,
    30,
    6
)
```

This avoids relying on the current system time and makes test results reproducible.

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

### `totp.generateSecret`

```luau
totp.generateSecret(): string
```

Generates a cryptographically random TOTP secret encoded as Base32.