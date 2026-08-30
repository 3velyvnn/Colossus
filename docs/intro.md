---
sidebar_position: 1
---

# Colossus

**A modular authentication library for Luau.**

Colossus is a small, dependency-free library for generating and verifying **HOTP** and **TOTP** codes. It implements the underlying algorithms directly in Luau and follows the standards defined by **RFC 4226** and **RFC 6238**.

## What is Colossus?

Colossus gives you the building blocks you need to add one-time-password authentication to a Luau application without relying on an external authentication service.

It currently includes:

- **HOTP** — Counter-based one-time passwords
- **TOTP** — Time-based one-time passwords
- **HMAC-SHA1** — Used internally by HOTP
- **Base32** — Encoding and decoding for authenticator-compatible secrets
- **Secret generation** — Securely generated secrets for TOTP

The implementations are tested against the official test vectors from **RFC 4226** and **RFC 6238**.

## Quick Start

Here's a basic example using TOTP:

```lua
local totp = require("./src/totp")

local secret = totp.generateSecret()
local code = totp.generate(secret)

print(string.format("%06d", code))
```

`generateSecret()` creates a new Base32-encoded secret, and `generate()` uses that secret and the current time to produce a TOTP code.

## Documentation

The documentation is split into two main sections.

### Guides

Learn how to use Colossus and put HOTP or TOTP authentication into your application.

### API Reference

Detailed documentation for Colossus's public modules, functions, parameters, and return values, generated directly from the source code.