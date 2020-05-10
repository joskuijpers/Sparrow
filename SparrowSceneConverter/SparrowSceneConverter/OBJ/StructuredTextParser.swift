//
//  StructuredTextParser.swift
//  SparrowSceneConverter
//
//  Created by Jos Kuijpers on 10/05/2020.
//  Copyright © 2020 Jos Kuijpers. All rights reserved.
//

import Foundation

class StructuredTextParser {
    var source: String
    var index: String.Index
    var input: String.UnicodeScalarView
    var offset = 0
    
    let whitespaceSet = CharacterSet.whitespaces
    let identifierSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
    let textSet = CharacterSet.alphanumerics.union(.punctuationCharacters)
    let floatSet = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: ".-e"))
    let whitespaceNewlineSet = CharacterSet.whitespacesAndNewlines
    
    init(input: String) {
        self.input = input.unicodeScalars
        self.index = input.startIndex
        self.source = input
    }
    
    func char() -> Character? {
        let v = input[index]
        
        index = input.index(after: index)
        
        return Character(v)
    }
    
    // Find a valid identifier with a space behind it
    func identifier() -> Substring? {
        var newIndex = index
        var newOffset = offset

        while newIndex < input.endIndex, identifierSet.contains(input[newIndex]) {
            newIndex = input.index(after: newIndex)
            newOffset += 1
        }

        let result = source[index..<newIndex]
        index = newIndex
        offset = newOffset
        skipWhitespace()
        
        return result
    }
    
    /// Match with a string and consume
    func consume(_ string: String) -> Bool {
        let scalars = string.unicodeScalars
        var newOffset = offset
        var newIndex = index
        
        for c in scalars {
            guard newIndex < input.endIndex, input[newIndex] == c else {
                return false
            }
            newOffset += 1
            newIndex = input.index(after: newIndex)
        }
        
        // Matched
        index = newIndex
        offset = newOffset

        return true
    }
    
    /// Match a character without consuming
    func match(_ char: Unicode.Scalar) -> Bool {
        return input[index] == char
    }
    
    /// Match any text until the next space
    func text() -> Substring {
        var newIndex = index
        var newOffset = offset

        while textSet.contains(input[newIndex]), index < input.endIndex {
            newIndex = input.index(after: newIndex)
            newOffset += 1
        }
        
        let result = source[index..<newIndex]
        index = newIndex
        offset = newOffset
        skipWhitespace()
        
        return result
    }
    
    /// Skip any whitespace
    func skipWhitespace() {
        while index < input.endIndex, whitespaceSet.contains(input[index]) {
            index = input.index(after: index)
            offset += 1
        }
    }
    
    /// Skip everything until a newline
    func skipLine() {
        while index < input.endIndex, input[index] != "\n" {
            index = input.index(after: index)
            offset += 1
        }
        skipNewlines()
    }
    
    func skipWhitespaceAndNewlines() {
        while index < input.endIndex, whitespaceNewlineSet.contains(input[index]) {
            index = input.index(after: index)
            offset += 1
        }
    }
    
    /// Skip newlines
    func skipNewlines() {
        while index < input.endIndex, input[index] == "\n" {
            index = input.index(after: index)
            offset += 1
        }
    }
    
    /// Parse a single floating point value
    func parseFloat1() -> Float {
        var newIndex = index
        var newOffset = offset
        
        while floatSet.contains(input[newIndex]), index < input.endIndex {
            newIndex = input.index(after: newIndex)
            newOffset += 1
        }
        
        let result = source[index..<newIndex]
        if let f = Float(result) {
            index = newIndex
            offset = newOffset
            
            skipWhitespace()
            
            return f
        }
            
        fatalError("Could not parse float1 at \(offsetToLocation(offset))")
    }
    
    /// Parse two floating point values separated by a space
    func parseFloat2() -> float2 {
        return float2(parseFloat1(), parseFloat1())
    }
    
    /// Parse three floating point values separated by a space
    func parseFloat3() -> float3 {
        return float3(parseFloat1(), parseFloat1(), parseFloat1())
    }
    
    func restOfLine() -> Substring {
        var newIndex = index
        var newOffset = offset

        while index < input.endIndex, input[newIndex] != "\n" {
            newIndex = input.index(after: newIndex)
            newOffset += 1
        }
        
        let result = source[index..<newIndex]
        index = newIndex
        offset = newOffset
        
        skipWhitespace()
        
        return result
    }
    
    
    /// Find location for offset
    func offsetToLocation(_ search: Int) -> SourceLocation {
        var line = 0
        var column = 0
        var index = input.startIndex
        var offset = 0
        
        while index < input.endIndex {
            if offset == search {
                return SourceLocation(line: line, column: column)
            }
            
            if input[index] == "\n" {
                line += 1
                column = 0
            } else {
                column += 1
            }
            
            index = input.index(after: index)
            offset += 1
        }
        
        return SourceLocation(line: -1, column: -1)
    }
    
    struct SourceLocation: CustomStringConvertible {
        let line: Int
        let column: Int
        
        var description: String {
            if line == -1 && column == -1 {
                return "?:?"
            }
            return "\(line + 1):\(column + 1)"
        }
    }
}
