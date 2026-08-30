# Colossus

A modular Luau authentication library built from the ground up, with support for HOTP and TOTP.

Colossus is designed to keep the pieces of authentication separate and easy to work with, while implementing the underlying algorithms directly in Luau.

## Features

- HOTP (RFC 4226)
- TOTP (RFC 6238)
- HMAC-SHA1
- Base32 encoding and decoding
- Cryptographically secure TOTP secret generation
- RFC 4226 and RFC 6238 test vectors

## Why Colossus?

Colossus isn't built around a collection of black-box authentication helpers. The goal is to provide a modular implementation where the underlying pieces are easy to understand, reuse, and build on.