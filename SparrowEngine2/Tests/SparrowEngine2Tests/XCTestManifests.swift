import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SparrowEngine2Tests.allTests),
        testCase(BoundsTests.allTests),
    ]
}
#endif
