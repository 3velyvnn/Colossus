---
sidebar_position: 2
---

# Base32

The `base32` module provides the Base32 encoding and decoding functions used by Colossus.

Base32 is commonly used for TOTP secrets because the encoded values are easy to store, copy, and enter into authenticator applications.

## Encoding

`encode()` converts a `buffer` into a Base32-encoded string:

```lua id="c4y8pm"
local base32 = require("../../src/base32")

local data = buffer.fromstring("Hello")
local encoded = base32.encode(data)

print(encoded)
```

The result is a string containing the Base32 representation of the input data.

## Decoding

`decode()` converts a Base32-encoded string back into a `buffer`:

```lua id="7q2mxf"
local base32 = require("../../src/base32")

local encoded = "JBSWY3DP"
local decoded = base32.decode(encoded)
```

This is what the TOTP module uses to turn a Base32-encoded secret into the binary data used by HOTP.

## API

### `base32.encode`

```lua id="x1p7vd"
base32.encode(data: buffer): string
```

Encodes a buffer as a Base32 string.

### `base32.decode`

```lua id="k8n3rq"
base32.decode(data: string): buffer
```

Decodes a Base32 string into a buffer.

For complete parameter and return-value information, see the generated **API Reference**.