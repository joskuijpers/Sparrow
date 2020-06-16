import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SparrowEngineTests.allTests),
        testCase(BoundsTests.allTests),
    ]
}
#endif
