//
//  StreamableResponseTests.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 7/26/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import XCTest
@testable import AsyncResponse

class StreamableResponseTests: XCTestCase {

    func testStreamOfRespones() {

        let expectation = expectationWithDescription("stream expect")

        let values = [10, 1, 2, 3, 4, 5, 6]
        var actual: [Int] = []

        streamOperation(values)
            .success { value in
                actual.append(value)
                if actual.count == values.count { expectation.fulfill() }
            }.error { _ in XCTFail() }

        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertEqual(values, actual)
    }

    func testStreamOfResponesWithErrors() {

        let expectation = expectationWithDescription("stream expect")

        let values = [10, 1, 2, 3, 4, 5, 6]
        let errors = [1: Error.CustomError, 4: Error.GeneralError]
        var actual: [Int] = []
        var actualErrors: [Error] = []

        streamOperation(values, errors: errors)
            .success { value in
                actual.append(value)
                if actual.count + errors.count == values.count { expectation.fulfill() }
            }.error { error in
                guard let error = error as? Error else { XCTFail(); return }
                actualErrors.append(error)
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertEqual([10, 2, 3, 5, 6], actual)
        XCTAssertEqual([Error.CustomError, Error.GeneralError], actualErrors)
    }

    func testInit() {
        let response1 = StreamResponse(10)
        XCTAssertEqual(response1.result?.success, 10)
        var called = false
        response1.success(on: zalgo) { value in
            called = true
            XCTAssertEqual(value, 10)
        }
        XCTAssertTrue(called)

        let response2 = StreamResponse<UInt>(error: Error.CustomError)
        XCTAssertEqual(response2.result?.error as? Error, Error.CustomError)
    }

    func testTransformStreamOfRespones() {

        let expectation = expectationWithDescription("stream expect")

        let values = [10, 1, 2, 3, 4, 5, 6]
        var actual: [String] = []

        streamOperation(values)
            .next { value in
                return "\(value)"
            }
            .success { value in
                actual.append(value)
                if actual.count == values.count { expectation.fulfill() }
            }.error { _ in XCTFail() }

        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertEqual(["10", "1", "2", "3", "4", "5", "6"], actual)
    }

    func testAsyncResponseThenStreamable() {

        let expectation = expectationWithDescription("stream expect")

        let values = [10, 1, 2, 3, 4, 5, 6]
        var actual: [String] = []

        operation(100)
            .nextInBackground { (data) -> StreamResponse<Int> in
                XCTAssertFalse(NSThread.isMainThread())
                actual.append("\(data)+++\(data)")
                return streamOperation(values)
            }
            .nextInBackground { (data) -> Response<String> in
                XCTAssertFalse(NSThread.isMainThread())
                return Response("\(data)-\(data)")
            }.always { value in
                XCTAssertTrue(NSThread.isMainThread())
                actual.append(value.success!)
                if actual.count == values.count + 1 { expectation.fulfill() }
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        let expected = ["100+++100", "10-10", "1-1", "2-2", "3-3", "4-4", "5-5", "6-6"]
        XCTAssertEqual(expected, actual)
    }

    func testSyncResponseThenStreamable() {

        let expectation = expectationWithDescription("stream expect")

        let values = [10, 1, 2, 3, 4, 5, 6]
        var actual: [String] = []

        Response(100)
            .next { (n) -> StreamResponse<Int> in
                XCTAssertTrue(NSThread.isMainThread())
                actual.append("\(n)+++\(n)")
                return streamOperation(values)
            }.next { (v) -> Response<String> in
                XCTAssertTrue(NSThread.isMainThread())
                return Response("\(v)-\(v)")
            }.success { value in
                XCTAssertTrue(NSThread.isMainThread())
                actual.append(value)
                if actual.count == values.count + 1 { expectation.fulfill() }
            }.error(on: zalgo) { _ in XCTFail() }

        waitForExpectationsWithTimeout(10, handler: nil)

        let expected = ["100+++100", "10-10", "1-1", "2-2", "3-3", "4-4", "5-5", "6-6"]
        XCTAssertEqual(expected, actual)
    }

    func testSyncResponseThenStreamableZalgo() {

        let expectation = expectationWithDescription("stream expect")

        let values = [10, 1, 2, 3, 4, 5, 6]
        var actual: [String] = []

        Response(100)
            .next(on: zalgo) { (n) -> StreamResponse<Int> in
                XCTAssertTrue(NSThread.isMainThread())
                actual.append("\(n)+++\(n)")
                return streamOperation(values)
            }.next(on: zalgo) { (v) -> Response<String> in
                XCTAssertTrue(NSThread.isMainThread())
                return Response("\(v)-\(v)")
            }.success(on: zalgo) { value in
                XCTAssertTrue(NSThread.isMainThread())
                actual.append(value)
                if actual.count == values.count + 1 { expectation.fulfill() }
            }.error(on: zalgo) { _ in XCTFail() }

        waitForExpectationsWithTimeout(10, handler: nil)

        let expected = ["100+++100", "10-10", "1-1", "2-2", "3-3", "4-4", "5-5", "6-6"]
        XCTAssertEqual(expected, actual)
    }

    func testResponseDeallocated() {

        class Test {
            static var deallocated = false
            let (response1, resolver1) = StreamResponse<Int>.asyncResponse()

            init() {
                response1.always(on: zalgo) { [weak self] _ in
                    XCTAssertNotNil(self?.response1)
                }
                resolver1.resolveSuccess(1)
            }

            deinit {
                Test.deallocated = true
            }
        }

        weak var weakValue: Test?
        autoreleasepool {
            let value = Test()
            weakValue = value
            XCTAssertFalse(Test.deallocated)
        }
        XCTAssertNil(weakValue)
        XCTAssertTrue(Test.deallocated)
    }

    func testNestedResponsesDeallocated() {

        class Test {
            static var deallocated = false
            let (response1, resolver1) = StreamResponse<Int>.asyncResponse()

            init() {
                response1
                    .next { $0 + 1 }
                    .next { $0 * $0 }
                    .always(on: zalgo) { [weak self] _ in
                        let _ = self // use self
                }
            }

            deinit {
                Test.deallocated = true
            }
        }

        weak var weakValue: Test?
        autoreleasepool {
            let value = Test()
            weakValue = value
            value.resolver1.resolveSuccess(1)
            XCTAssertFalse(Test.deallocated)
            value.resolver1.resolveSuccess(1)
        }
        XCTAssertNil(weakValue)
        XCTAssertTrue(Test.deallocated)
    }

    func testStreamResponsesDeallocated() {

        class Test {

            let expectation: XCTestExpectation

            static var deallocated = false
            var response: StreamResponse<String>!
            var actual: [String] = []

            init(expectation: XCTestExpectation) {
                self.expectation = expectation

                let values = [10, 1, 2, 3, 4, 5, 6]

                response = Response(100)
                    .next(on: zalgo) { (n) -> StreamResponse<Int> in
                        self.actual.append("\(n)+++\(n)")
                        return streamOperation(values)
                    }.next(on: zalgo) { (v) -> Response<String> in
                        self.actual.append("\(v)-\(v)")
                        return Response("\(v)-\(v)")
                    }.success(on: zalgo) { value in
                        if self.actual.count == values.count + 1 { expectation.fulfill() }
                    }.error(on: zalgo) { _ in XCTFail() }
            }

            deinit {
                Test.deallocated = true
            }
        }

        weak var weakValue: Test?
        weak var weakResponse: StreamResponse<String>?
        autoreleasepool {
            var value: Test? = Test(expectation: expectationWithDescription("stream expect"))
            weakValue = value
            weakResponse = value?.response

            XCTAssertFalse(Test.deallocated)
            weak var value1 = value
            value = nil
            XCTAssertFalse(Test.deallocated)

            waitForExpectationsWithTimeout(10, handler: nil)

            value1?.response.dispose()
        }
        XCTAssertNil(weakValue)
        XCTAssertNil(weakResponse)
        XCTAssertTrue(Test.deallocated)
    }

    func testStreamResponsesStopEarlyDeallocated() {

        class Test {
            static var deallocated = false
            var response: StreamResponse<String>!
            var actual: [String] = []
            var parentResponse: StreamResponse<Int>?

            init() {
                let values = [10, 1, 2, 3, 4, 5, 6]

                response = Response(100)
                    .next(on: zalgo) { (n) -> StreamResponse<Int> in
                        self.actual.append("\(n)+++\(n)")
                        let s = streamOperation(values)
                        self.parentResponse = s
                        return s
                    }.next(on: zalgo) { (v) -> Response<String> in
                        self.actual.append("\(v)-\(v)")
                        return Response("\(v)-\(v)")
                    }.success(on: zalgo) { value in

                    }.error(on: zalgo) { _ in XCTFail() }
            }

            deinit {
                Test.deallocated = true
            }
        }

        weak var weakValue: Test?
        autoreleasepool {
            let value = Test()
            // stop early
            value.parentResponse?.dispose()
            XCTAssertEqual(["100+++100"], value.actual ?? [])
            weakValue = value
        }
        XCTAssertNil(weakValue)
        XCTAssertTrue(Test.deallocated)
    }

    func testStreamChainStartingStreamDeallocation() {

        class TestResponse: Response<Int> {
            static var deallocated = false
            deinit {
                TestResponse.deallocated = true
            }
            init() {
                super.init(resolution: { _ -> Void in})
            }
        }

        weak var weakStream: StreamResponse<Int>?
        autoreleasepool {
            let streamAndResolver = StreamResponse<Int>.asyncResponse()

            let expectation = expectationWithDescription("wait for next")

            streamAndResolver.response.next { _ -> Response<Int> in
                expectation.fulfill()
                return TestResponse()
            }
            weakStream = streamAndResolver.response

            streamAndResolver.resolver.element(.Success(1))

            waitForExpectationsWithTimeout(10, handler: nil)
        }

        XCTAssertNil(weakStream)
        XCTAssertTrue(TestResponse.deallocated)
    }

    func testStreamChainStartingResponseDeallocation() {

        weak var weakStream: StreamResponse<Int>?
        autoreleasepool {
            let streamAndResolver = StreamResponse<Int>.asyncResponse()

            let expectation = expectationWithDescription("wait for 1st next")

            Response(100)
                .next { _ -> StreamResponse<Int> in
                    expectation.fulfill()
                    return streamAndResolver.response
                }.next { _ in
                    return Response(1)
            }
            weakStream = streamAndResolver.response

            waitForExpectationsWithTimeout(10, handler: nil)
        }

        XCTAssertNil(weakStream)
    }
}
