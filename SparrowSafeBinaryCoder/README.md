# SparrowSafeBinaryCoder

A binary coder for Swift structures. The encoding allows for changing structures by storing keys within the format to do matching.

This package currently uses CBOR coding implementation.

## Features

Supports binary coding of:
- Primitives
- Arrays
- Strings
- Data
- Optionals
- SIMD vectors and matrices (partially)

Keys are saved, so adding new fields is possible. They do need to be an optional though, because otherwise the value is required in the input. Removing fields is always allowed.

## Limitations

When adding fields and keeping binary compatibility, the field has to be an optional.
