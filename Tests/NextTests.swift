//
//  NextTests.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 8/13/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import XCTest
import AsyncResponse

class NextTests: XCTestCase {

    func testResponse() {

        let expectation = expectationWithDescription("next anyway")

        operation(1)
            .next { value -> Response<Int> in
                XCTAssertTrue(NSThread.isMainThread())
                return operation(2)
            }.next { value -> Int in
                XCTAssertTrue(NSThread.isMainThread())
                return value + 1
            }.success { value in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(3, value)
                expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testResponseThenStream() {

        let expectation = expectationWithDescription("next anyway")
        let values = [2, 1]
        var expected: [Int] = []

        operation(1)
            .next { value -> StreamResponse<Int> in
                XCTAssertTrue(NSThread.isMainThread())
                return streamOperation(values)
            }.next { value -> Int in
                XCTAssertTrue(NSThread.isMainThread())
                return value + 1
            }.success { value in
                XCTAssertTrue(NSThread.isMainThread())
                expected.append(value)
                if expected.count == values.count {
                    expectation.fulfill()
                }
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertEqual([3, 2], expected)
    }

    func testStream() {

        let expectation = expectationWithDescription("next anyway")
        let values = [2, 1]
        var expected: [Int] = []

        streamOperation(values)
            .next { value -> Response<Int> in
                XCTAssertTrue(NSThread.isMainThread())
                return operation(value * 2)
            }.next { value -> Int in
                XCTAssertTrue(NSThread.isMainThread())
                return value + 1
            }.success { value in
                XCTAssertTrue(NSThread.isMainThread())
                expected.append(value)
                if expected.count == values.count {
                    expectation.fulfill()
                }
        }

        waitForExpectationsWithTimeout(10, handler: nil)
        
        XCTAssertEqual([5, 3], expected)
    }

    func testResponseInBackground() {

        let expectation = expectationWithDescription("next anyway")

        operation(1)
            .nextInBackground { value -> Response<Int> in
                XCTAssertFalse(NSThread.isMainThread())
                return operation(2)
            }.nextInBackground { value -> Int in
                XCTAssertFalse(NSThread.isMainThread())
                return value + 1
            }.success { value in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(3, value)
                expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testResponseThenStreamInBackground() {

        let expectation = expectationWithDescription("next anyway")
        let values = [2, 1]
        var expected: [Int] = []

        operation(1)
            .nextInBackground { value -> StreamResponse<Int> in
                XCTAssertFalse(NSThread.isMainThread())
                return streamOperation(values)
            }.nextInBackground { value -> Int in
                XCTAssertFalse(NSThread.isMainThread())
                return value + 1
            }.success { value in
                XCTAssertTrue(NSThread.isMainThread())
                expected.append(value)
                if expected.count == values.count {
                    expectation.fulfill()
                }
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertEqual([3, 2], expected)
    }

    func testStreamInBackground() {

        let expectation = expectationWithDescription("next anyway")
        let values = [2, 1]
        var expected: [Int] = []

        streamOperation(values)
            .nextInBackground { value -> Response<Int> in
                XCTAssertFalse(NSThread.isMainThread())
                return operation(value * 2)
            }.nextInBackground { value -> Int in
                XCTAssertFalse(NSThread.isMainThread())
                return value + 1
            }.success { value in
                XCTAssertTrue(NSThread.isMainThread())
                expected.append(value)
                if expected.count == values.count {
                    expectation.fulfill()
                }
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertEqual([5, 3], expected)
    }

    func testResponseAsVoid() {
        let expectation = expectationWithDescription("as void")

        let response = operation(20)

        response.asVoid().success { [weak response] _ in
            XCTAssertEqual(20, response?.result?.success)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)

    }

    func testStreamAsVoid() {
        let expectation = expectationWithDescription("as void")

        let values = [20, 10, 0, -11]
        var expected: [Int] = []
        let response = streamOperation(values)

        response.asVoid().success { [unowned response] _ in
            expected.append(response.result!.success!)
            if expected.count == values.count {
                expectation.fulfill()
            }
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertEqual(expected, values)
    }
}
