---
sidebar_position: 2
---

# HOTP

**HMAC-based One-Time Password (HOTP)** generates one-time passwords from a shared secret and a counter.

Colossus implements HOTP using **HMAC-SHA1** and supports configurable code lengths.

## Generating an HOTP Code

The basic usage is:

```luau
local totp = require("./src/totp")

local secret = -- a secret as a buffer
local counter = 0

local code = totp.hotp(secret, counter)

print(string.format("%06d", code))
```

`hotp()` takes a secret, a counter, and an optional number of digits.

```text
HOTP(secret, counter)
       │
       ▼
   HMAC-SHA1
       │
       ▼
Dynamic truncation
       │
       ▼
  Digit reduction
       │
       ▼
     Code
```

## The Counter

Unlike TOTP, HOTP does not use the current time.

The counter is supplied directly:

```luau
local code = totp.hotp(secret, 0)
```

Incrementing the counter produces a different HOTP value:

```luau
local code1 = totp.hotp(secret, 0)
local code2 = totp.hotp(secret, 1)
```

The counter is encoded as an 8-byte value before being passed to HMAC-SHA1.

## Code Length

HOTP generates 6-digit codes by default.

You can specify a different length:

```luau
local code = totp.hotp(secret, counter, 8)

print(string.format("%08d", code))
```

Colossus accepts between **1 and 9 digits**.

```luau
local code = totp.hotp(secret, counter, 9)
```

Passing a value outside that range raises an error.

## Using a Known Secret

`hotp()` expects its secret as a `buffer`, rather than the Base32-encoded string accepted by `totp.generate()`.

For example:

```luau
local secret = buffer.fromstring("12345678901234567890")

local code = totp.hotp(secret, 0)
```

This distinction is important:

| Function | Secret |
|---|---|
| `totp.hotp()` | `buffer` |
| `totp.generate()` | Base32-encoded `string` |

`totp.generate()` decodes its Base32 secret before passing it to HOTP internally.

## RFC 4226

HOTP is specified by **RFC 4226**.

Colossus's HOTP implementation is designed around the algorithm described by that specification, including:

- HMAC-SHA1
- An 8-byte counter
- Dynamic truncation
- Configurable decimal output length

Known RFC test vectors can therefore be used to verify the implementation.

## API

### `totp.hotp`

```luau
totp.hotp(
    secret: buffer,
    counter: number,
    digits: number?
): number
```

Generates an HOTP code.

| Parameter | Type | Default |
|---|---|---|
| `secret` | `buffer` | — |
| `counter` | `number` | — |
| `digits` | `number?` | `6` |

The returned value is a number rather than a zero-padded string. If leading zeroes are required, format the result when displaying it:

```luau
local code = totp.hotp(secret, counter)

local formatted = string.format("%06d", code)
```

## HOTP vs TOTP

HOTP and TOTP share the same underlying HOTP algorithm.

The difference is what provides the counter:

```text
HOTP
secret + counter
       ↓
      HOTP


TOTP
secret + timestamp
       ↓
 timestamp / timeStep
       ↓
     counter
       ↓
      HOTP
```

This is why Colossus implements TOTP in terms of its `hotp()` function.