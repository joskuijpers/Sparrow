//
//  SparrowBinaryCoderTests.swift
//  SparrowBinaryCoderTests
//
//  Created by Jos Kuijpers on 09/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import XCTest
@testable import SparrowBinaryCoder
import simd

class SparrowBinaryCoderTests: XCTestCase {
    struct Primitives: BinaryCodable {
        var a: Int8
        var b: UInt16
        var c: Int32
        var d: UInt64
        var e: Int
        var f: Float
        var g: Double
        var h: Bool
        var i: Bool
        var j: Int64
        var k: UInt
    }
    
    func testPrimitiveEncoding() throws {
        let s = Primitives(a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: false, i: true, j: 8, k: 9)
        let data = try BinaryEncoder.encode(s)
        XCTAssertEqual(data, [
            1,
            0, 2,
            0, 0, 0, 3,
            0, 0, 0, 0, 0, 0, 0, 4,
            0, 0, 0, 0, 0, 0, 0, 5,
            
            0x40, 0xC0, 0x00, 0x00,
            0x40, 0x1C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            
            0x00, 0x01,
            
            0, 0, 0, 0, 0, 0, 0, 8,
            0, 0, 0, 0, 0, 0, 0, 9,
        ])
    }
    
    func testPrimitiveDecoding() throws {
        let data: [UInt8] = [
            1,
            0, 2,
            0, 0, 0, 3,
            0, 0, 0, 0, 0, 0, 0, 4,
            0, 0, 0, 0, 0, 0, 0, 5,
            
            0x40, 0xC0, 0x00, 0x00,
            0x40, 0x1C, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            
            0x00, 0x01,
            
            0, 0, 0, 0, 0, 0, 0, 8,
            0, 0, 0, 0, 0, 0, 0, 9,
        ]
        let s = try BinaryDecoder.decode(Primitives.self, data: data)
        XCTAssertEqual(s.a, 1)
        XCTAssertEqual(s.b, 2)
        XCTAssertEqual(s.c, 3)
        XCTAssertEqual(s.d, 4)
        XCTAssertEqual(s.e, 5)
        XCTAssertEqual(s.f, 6)
        XCTAssertEqual(s.g, 7)
        XCTAssertEqual(s.h, false)
        XCTAssertEqual(s.i, true)
        XCTAssertEqual(s.j, 8)
        XCTAssertEqual(s.k, 9)
    }
    
    func testPrimitiveRoundtrip() throws {
        AssertRoundtrip(Primitives(a: 1, b: 2, c: 3, d: 4, e: 5, f: 6, g: 7, h: false, i: true, j: 8, k: 9))
    }
    
    func testString() throws {
        AssertRoundtrip("HelloWorld")
        
        let data = try BinaryEncoder.encode("hello")
        XCTAssertEqual(data.count, 5 + 8)
    }
    
    func testInvalidUTFString() throws {
        // See https://stackoverflow.com/questions/1301402/example-invalid-utf8-string for invalid utf8 examples
        let data: [UInt8] = [
            0, 0, 0, 0, 0, 0, 0, 2,
            0xc3, 0x28
        ]
        
        XCTAssertThrowsError(try BinaryDecoder.decode(String.self, data: data))
    }
    
    func testBool() throws {
        struct BoolStruct: BinaryCodable {
            let b: Bool
        }
        AssertRoundtrip(BoolStruct(b: true))
        AssertRoundtrip(BoolStruct(b: false))
        
        let data = try BinaryEncoder.encode(BoolStruct(b: true))
        XCTAssertEqual(data.count, 1)
        
        // Out of bounds
        let dataIn: [UInt8] = [0x2]
        XCTAssertThrowsError(try BinaryDecoder.decode(BoolStruct.self, data: dataIn))
    }
    
    func testArrayRoundtrip() throws {
        AssertRoundtrip([1,2,3])
    }
    
    func testInt() throws {
        AssertRoundtrip(Int(5))
        
        XCTAssertEqual(try BinaryEncoder.encode(Int(5)).count, 8)
    }
    
    func testUInt() throws {
        AssertRoundtrip(UInt(5))
        
        XCTAssertEqual(try BinaryEncoder.encode(UInt(5)).count, 8)
    }
    
    func testInt8() throws {
        AssertRoundtrip(Int8(6))
        XCTAssertEqual(try BinaryEncoder.encode(Int8(6)).count, 1)
        
        AssertRoundtrip(UInt8(6))
        XCTAssertEqual(try BinaryEncoder.encode(UInt8(6)).count, 1)
    }
    
    func testInt16() throws {
        AssertRoundtrip(Int16(7))
        XCTAssertEqual(try BinaryEncoder.encode(Int16(7)).count, 2)
        
        AssertRoundtrip(UInt16(7))
        XCTAssertEqual(try BinaryEncoder.encode(UInt16(7)).count, 2)
    }
    
    func testInt32() throws {
        AssertRoundtrip(Int32(7))
        XCTAssertEqual(try BinaryEncoder.encode(Int32(7)).count, 4)
        
        AssertRoundtrip(UInt32(7))
        XCTAssertEqual(try BinaryEncoder.encode(UInt32(7)).count, 4)
    }
    
    func testInt64() throws {
        AssertRoundtrip(Int64(7))
        XCTAssertEqual(try BinaryEncoder.encode(Int64(7)).count, 8)
        
        AssertRoundtrip(UInt64(7))
        XCTAssertEqual(try BinaryEncoder.encode(UInt64(7)).count, 8)
    }
    
    func testIntConversionFailure() throws {
        let data = try BinaryEncoder.encode(Int32(1000))
        
        // Decoding more than is in the data means a data-type mismatch
        XCTAssertThrowsError(try BinaryDecoder.decode(Int64.self, data: data))
        
        // Not all data parsed is indicator of faulty input type for the data
        XCTAssertThrowsError(try BinaryDecoder.decode(Int16.self, data: data))
    }
    
    func testStructWithString() throws {
        struct WithString: BinaryCodable {
            var a: String
            var b: String
            var c: Int
        }
        AssertRoundtrip(WithString(a: "hello", b: "world", c: 42))
    }
    
    func testIntArraySize() throws {
        let data = try BinaryEncoder.encode([1,2,3])
        XCTAssertEqual(data.count, 8 + 3 * 8)
    }
    
    func testArray() throws {
        AssertRoundtrip([1,2,3,4,5,6])
    }
    
    func testComplexStruct() {
        struct Company: BinaryCodable {
            var name: String
            var employees: [Employee]
        }
        
        struct Employee: BinaryCodable {
            var name: String
            var jobTitle: String
            var age: Int
        }
        
        let company = Company(name: "Joe's Discount Airbags", employees: [
            Employee(name: "Joe Johnson", jobTitle: "CEO", age: 27),
            Employee(name: "Stan Lee", jobTitle: "Janitor", age: 87),
            Employee(name: "Dracula", jobTitle: "Dracula", age: 41),
            Employee(name: "Steve Jobs", jobTitle: "Visionary", age: 56),
        ])
        AssertRoundtrip(company)
    }
    
    
    
    
    //MARK:- Optionals
    

    func testStructWithPrimitiveOptional() throws {
        struct MyOptional: BinaryCodable {
            var opt: Int?
        }
        
        AssertRoundtrip(MyOptional(opt: nil))
        AssertRoundtrip(MyOptional(opt: 5))
    }
    
    func testStructWithStringOptional() throws {
        struct MyOptional: BinaryCodable {
            var opt: String?
        }
        
        AssertRoundtrip(MyOptional(opt: nil))
        AssertRoundtrip(MyOptional(opt: "hello"))
    }
    
    func testStructWithComplexOptional() throws {
        struct MyValue: BinaryCodable {
            var opt: Bool
        }
        struct MyOptional: BinaryCodable {
            var opt: MyValue?
        }
        
        AssertRoundtrip(MyOptional(opt: nil))
        AssertRoundtrip(MyOptional(opt: MyValue(opt: true)))
        AssertRoundtrip(MyOptional(opt: MyValue(opt: false)))
    }
    
    func testArrayWithOptional() throws {
        let input: [Int?] = [1, 5, nil, 2]
        
        let data = try BinaryEncoder.encode(input)
        let expected: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 4, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 5, 0, 1, 0, 0, 0, 0, 0, 0, 0, 2]
        XCTAssertEqual(data, expected)

        let output = try BinaryDecoder.decode([Int?].self, data: expected)
        AssertEqual(input, output)
    }
    
    
    
    
    
    //MARK:- Data
    
    func testData() throws {
        struct DataContainer: BinaryCodable {
            let d: Data
        }
        
        let data: [UInt8] = [0,1,2,3,4,5,6,7,8,9]
        let input = DataContainer(d: Data(bytes: data, count: data.count))
        
        let output = try BinaryEncoder.encode(input)
        
        // Same size with length prefix
        XCTAssertEqual(output.count, data.count + 8)
        
        AssertRoundtrip(input)
    }
    
    
//MARK:- Vectors
    
    func testVector3f() throws {
        struct Object: BinaryCodable {
            let p: SIMD3<Float>
            let v: SIMD3<Float>
        }
        let input = Object(p: [0, 1, 2], v: [-5,-5,0])
        
        let data = try BinaryEncoder.encode(input)
        
        XCTAssertEqual(data.count, 3 * 4 + 3 * 4)
        AssertEqual(try BinaryDecoder.decode(Object.self, data: data), input)
        
        AssertRoundtrip(SIMD3<Float>(253.23553,476.3252,347.6346))
    }
    
    func testVector4f() throws {
        struct Object: BinaryCodable {
            let p: SIMD4<Float>
            let v: SIMD4<Float>
        }
        let input = Object(p: [0, 1, 2, 3], v: [-5,-5,0, 1])
        
        let data = try BinaryEncoder.encode(input)
        
        XCTAssertEqual(data.count, 4 * 4 + 4 * 4)
        AssertEqual(try BinaryDecoder.decode(Object.self, data: data), input)
        
        AssertRoundtrip(SIMD4<Float>(253.23553,476.3252,347.6346,100000))
    }
    
//MARK:- Matrices
    
    func testMatrix4x4f() throws {
        AssertRoundtrip(matrix_identity_float4x4)
        
        let mat = matrix_float4x4([0,1,2,3], [4,5,6,7], [8,9,10,11], [12,13,14,15])
        AssertRoundtrip(mat)
        
        let data = try BinaryEncoder.encode(mat)
        
        // 4x4 matrix of floats (4 bytes)
        XCTAssertEqual(data.count, 4 * 4 * 4)
    }
}

/// Assert equal without Equal protocol
private func AssertEqual<T>(_ lhs: T, _ rhs: T, file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(String(describing: lhs), String(describing: rhs), file: file, line: line)
}

private func AssertRoundtrip<T: BinaryCodable>(_ original: T, file: StaticString = #file, line: UInt = #line) {
    do {
        let data = try BinaryEncoder.encode(original)
        let roundtripped = try BinaryDecoder.decode(T.self, data: data)
        AssertEqual(original, roundtripped, file: file, line: line)
    } catch {
        XCTFail("Unexpected error: \(error)", file: file, line: line)
    }
}
