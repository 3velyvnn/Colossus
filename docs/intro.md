---
sidebar_position: 1
---

# Colossus

**A modular authentication library for Luau.**

Colossus provides implementations of **HOTP** and **TOTP** built from the ground up, with no dependency on external authentication services.

## What is Colossus?

Colossus is a Luau authentication library designed to make implementing one-time-password authentication straightforward.

It currently provides:

- **HOTP** — Counter-based one-time passwords
- **TOTP** — Time-based one-time passwords
- **HMAC-SHA1** — The cryptographic primitive used by HOTP
- **Base32** — Encoding and decoding for authenticator-compatible secrets
- **Secure secrets** — Cryptographically random TOTP secret generation

The implementations follow the algorithms and test vectors defined by **RFC 4226** and **RFC 6238**.

## Quick Start

Generate a secret and use it to create a TOTP code:

```lua
local totp = require("./src/totp")

local secret = totp.generateSecret()
local code = totp.generate(secret)

print(string.format("%06d", code))
```

`generateSecret()` creates a new Base32-encoded secret, while `generate()` produces a six-digit TOTP code using the current time.

## Documentation

Start with **Getting Started** if you're new to Colossus, or head straight to the **API Reference** if you're already familiar with the library.

### Guides

Learn how to use Colossus to build HOTP and TOTP authentication into your application.

### API Reference

Detailed documentation for every public module, function, parameter, and return value is generated automatically from the source code.
