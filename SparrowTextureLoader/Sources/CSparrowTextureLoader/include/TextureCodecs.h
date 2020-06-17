//
//  TextureCodecs.h
//  SparrowTextureLoader
//
//  Created by Jos Kuijpers on 16/06/2020.
//

#include <stdint.h>

typedef struct __attribute__((packed)) {
    uint32_t magic;
    unsigned char blockDimX;
    unsigned char blockDimY;
    unsigned char blockDimZ;
    unsigned char xSize[3];
    unsigned char ySize[3];
    unsigned char zSize[3];
} ASTCHeader;

typedef struct __attribute__((packed)) {
    uint8_t identifier[12];
    uint32_t endianness;
    uint32_t glType;
    uint32_t glTypeSize;
    uint32_t glFormat;
    uint32_t glInternalFormat;
    uint32_t glBaseInternalFormat;
    uint32_t width;
    uint32_t height;
    uint32_t depth;
    uint32_t arrayElementCount;
    uint32_t faceCount;
    uint32_t mipmapCount;
    uint32_t keyValueDataLength;
} KTXHeader;
