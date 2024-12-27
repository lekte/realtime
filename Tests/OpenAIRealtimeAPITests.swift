import XCTest
@testable import OpenAIRealtimeAPI

final class OpenAIRealtimeAPITests: XCTestCase {
    func testInitialization() {
        let sdk = OpenAIRealtimeAPI(modelId: "test-model", ephemeralToken: "test-token")
        XCTAssertNotNil(sdk)
    }
}
