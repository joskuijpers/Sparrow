# SparrowBinaryCoder

A binary coder for Swift structures. The encoding is as small as possible. There is no overhead (unless you count the 8 bytes needed to store array length).

## Features

Supports binary coding of:
- Primitives
- Arrays
- Strings
- Data
- Optionals
- SIMD vectors and matrices (partially)

## Limitations

The results are not 'safe': the structure has to exactly match the contents of the file. If it does not, it _might_ throw an error. If a structure added a field after writing, it will not be able to read the file anymore as this new field is expected. The same with removing fields.

Always add a checksum to your structure to verify the integrity of the result.
