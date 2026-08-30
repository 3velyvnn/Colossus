---
sidebar_position: 1
---

# Crypt

The `crypt` module contains the low-level cryptographic primitives used by Colossus.

It currently provides HMAC-SHA1 and cryptographically random key generation.

## HMAC-SHA1

`hmacSha1()` computes an HMAC-SHA1 digest from a key and message.

```lua
local crypt = require("../../src/crypt")

local key = buffer.fromstring("secret")
local message = buffer.fromstring("hello")

local digest = crypt.hmacSha1(key, message)
```

The result is returned as a `buffer` containing the 20-byte SHA-1 digest.

Colossus uses HMAC-SHA1 as the cryptographic primitive for HOTP, and therefore TOTP as well.

## Generating Keys

`generateKey()` creates a cryptographically random 32-byte key:

```lua
local crypt = require("../../src/crypt")

local key = crypt.generateKey()
```

This is used by Colossus when generating new TOTP secrets.

## API

### `crypt.hmacSha1`

```lua
crypt.hmacSha1(key: buffer, message: buffer): buffer
```

Computes an HMAC-SHA1 digest.

### `crypt.generateKey`

```lua
crypt.generateKey(): buffer
```

Generates a cryptographically random 32-byte key.

For the complete parameter and return-value documentation, see the generated **API Reference**.
