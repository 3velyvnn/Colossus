---
sidebar_position: 1
---

# Crypt

The `crypt` module contains the low-level cryptographic functions used by Colossus.

It currently provides **HMAC-SHA1** and random key generation.

## HMAC-SHA1

`hmacSha1()` calculates an HMAC-SHA1 digest from a key and a message:

```lua id="q5m8xk"
local crypt = require("../../src/crypt")

local key = buffer.fromstring("secret")
local message = buffer.fromstring("hello")

local digest = crypt.hmacSha1(key, message)
```

The result is returned as a `buffer` containing the 20-byte SHA-1 digest.

HMAC-SHA1 is the cryptographic primitive used by Colossus's HOTP implementation, and therefore by TOTP as well.

## Generating Keys

`generateKey()` generates a random 32-byte key:

```lua id="2a7rj4"
local crypt = require("../../src/crypt")

local key = crypt.generateKey()
```

Colossus uses this when generating new TOTP secrets.

## API

### `crypt.hmacSha1`

```lua id="4b8n2p"
crypt.hmacSha1(key: buffer, message: buffer): buffer
```

Calculates an HMAC-SHA1 digest from the provided key and message.

### `crypt.generateKey`

```lua id="v9c1ds"
crypt.generateKey(): buffer
```

Generates a random 32-byte key.

For complete parameter and return-value information, see the generated **API Reference**.