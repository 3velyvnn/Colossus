---
sidebar_position: 2
---

# Base32

The `base32` module provides Base32 encoding and decoding utilities used by Colossus.

Base32 is particularly useful for TOTP secrets because the encoded representation is easy to store and enter into authenticator applications.

## Encoding

`encode()` converts a buffer into a Base32-encoded string:

```lua
local base32 = require("../../src/base32")

local data = buffer.fromstring("Hello")
local encoded = base32.encode(data)

print(encoded)
```

The returned value is a string containing the Base32 representation of the input data.

## Decoding

`decode()` converts a Base32-encoded string back into a buffer:

```lua
local base32 = require("../../src/base32")

local encoded = "JBSWY3DP"
local decoded = base32.decode(encoded)
```

This is the operation used by the TOTP module to turn a Base32-encoded secret into the binary secret used by HOTP.

## API

### `base32.encode`

```lua
base32.encode(data: buffer): string
```

Encodes a buffer as Base32.

### `base32.decode`

```lua
base32.decode(data: string): buffer
```

Decodes a Base32 string into a buffer.

For the complete parameter and return-value documentation, see the generated **API Reference**.
