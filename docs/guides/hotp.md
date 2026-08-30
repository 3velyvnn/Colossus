---
sidebar_position: 2
---

# HOTP

**HMAC-based One-Time Password (HOTP)** generates one-time-password codes from a shared secret and a counter.

Colossus implements HOTP using **HMAC-SHA1** and lets you choose the length of the generated code.

## Generating an HOTP Code

The basic usage looks like this:

```lua
local totp = require("./src/totp")

local secret = buffer.fromstring("12345678901234567890")
local counter = 0

local code = totp.hotp(secret, counter)

print(string.format("%06d", code))
```

`hotp()` takes a secret, a counter, and an optional digit count.

Under the hood, the process looks like this:

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

Unlike TOTP, HOTP doesn't use the current time. The counter is supplied directly:

```lua
local code = totp.hotp(secret, 0)
```

Changing the counter produces a different code:

```lua
local code1 = totp.hotp(secret, 0)
local code2 = totp.hotp(secret, 1)
```

The counter is represented as an 8-byte value before being passed to HMAC-SHA1.

In a real application, the counter needs to be tracked and incremented according to whatever authentication flow you're implementing.

## Code Length

HOTP generates 6-digit codes by default.

You can choose a different length:

```lua
local code = totp.hotp(secret, counter, 8)

print(string.format("%08d", code))
```

Colossus supports between **1 and 9 digits**:

```lua
local code = totp.hotp(secret, counter, 9)
```

Passing a value outside that range raises an error.

The returned value is a number, so if you need leading zeroes when displaying the code, format it yourself.

## Using a Secret

`hotp()` expects its secret as a `buffer`, rather than the Base32-encoded string used by `totp.generate()`.

For example:

```lua
local secret = buffer.fromstring("12345678901234567890")

local code = totp.hotp(secret, 0)
```

The two functions therefore expect different secret formats:

| Function | Secret |
|---|---|
| `totp.hotp()` | `buffer` |
| `totp.generate()` | Base32-encoded `string` |

`totp.generate()` decodes its Base32 secret before passing it to `hotp()` internally.

## RFC 4226

HOTP is defined by **RFC 4226**.

Colossus follows the algorithm described in the specification, including:

- HMAC-SHA1
- An 8-byte counter
- Dynamic truncation
- Configurable decimal code lengths

The implementation can be tested against the known test vectors provided by RFC 4226.

## API

### `totp.hotp`

```lua
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

The returned value is a number rather than a zero-padded string.

If you want to display a 6-digit code:

```lua
local code = totp.hotp(secret, counter)
local formatted = string.format("%06d", code)
```

## HOTP vs TOTP

HOTP and TOTP use the same underlying HOTP algorithm. The difference is where the counter comes from.

With HOTP, you provide the counter directly:

```text
HOTP
secret + counter
       │
       ▼
      HOTP
```

TOTP derives the counter from a timestamp:

```text
TOTP
secret + timestamp
       │
       ▼
timestamp / timeStep
       │
       ▼
    counter
       │
       ▼
      HOTP
```

This is why Colossus builds TOTP on top of its `hotp()` implementation.