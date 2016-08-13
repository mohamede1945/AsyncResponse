//
//  RecoverTests.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 8/13/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import XCTest
import AsyncResponse

class RecoverTests: XCTestCase {

    func testResponseNotRecovering() {

        let expectation = expectationWithDescription("recover")

        operation(1)
            .recover { error -> Response<Int> in
                XCTFail()
                return operation(2)
            }.recover { error -> Int in
                XCTFail()
                return 1
            }.success { value in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(1, value)
                expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testStreamNotRecovering() {

        let expectation = expectationWithDescription("next anyway")
        let values = [2, 1]
        var expected: [Int] = []

        streamOperation(values)
            .recover { error -> Response<Int> in
                XCTFail()
                return operation(1)
            }.recover { error -> Int in
                XCTAssertTrue(NSThread.isMainThread())
                return 1
            }.success { value in
                XCTAssertTrue(NSThread.isMainThread())
                expected.append(value)
                if expected.count == values.count {
                    expectation.fulfill()
                }
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertEqual([2, 1], expected)
    }

    func testResponseRecoveringByResponse() {

        let expectation = expectationWithDescription("recover")

        operation(1, error: Error.GeneralError)
            .recover { error -> Response<Int> in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(Error.GeneralError, error as? Error)
                return operation(2)
            }.success { value in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(2, value)
                expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testResponseRecoveringByBlock() {

        let expectation = expectationWithDescription("recover")

        operation(1, error: Error.GeneralError)
            .recover { error -> Int in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(Error.GeneralError, error as? Error)
                return 33
            }.success { value in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(33, value)
                expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testStreamRecoveringByResponse() {

        let expectation = expectationWithDescription("next anyway")
        let values = [2, 1]
        var expected: [Int] = []

        streamOperation(values, errors: [1: Error.CustomError])
            .recover { error -> Response<Int> in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(Error.CustomError, error as? Error)
                return operation(44)
            }.success { value in
                XCTAssertTrue(NSThread.isMainThread())
                expected.append(value)
                if expected.count == values.count {
                    expectation.fulfill()
                }
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertEqual([2, 44], expected)
    }

    func testStreamRecoveringByBlock() {

        let expectation = expectationWithDescription("next anyway")
        let values = [2, 1]
        var expected: [Int] = []

        streamOperation(values, errors: [1: Error.CustomError])
            .recover { error -> Int in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(Error.CustomError, error as? Error)
                return 70
            }.success { value in
                XCTAssertTrue(NSThread.isMainThread())
                expected.append(value)
                if expected.count == values.count {
                    expectation.fulfill()
                }
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        XCTAssertEqual([2, 70], expected)
    }

    func testResponseRecoveringWithError() {

        let expectation = expectationWithDescription("recover")

        operation(1, error: Error.GeneralError)
            .recover { error -> Int in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(Error.GeneralError, error as? Error)
                throw Error.CustomError
            }.error { error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(Error.CustomError, error as? Error)
                expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testStreamRecoveringWithError() {

        let expectation = expectationWithDescription("next anyway")
        let values = [2, 1]

        streamOperation(values, errors: [1: Error.CustomError])
            .recover { error -> Int in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(Error.CustomError, error as? Error)
                throw Error.GeneralError
            }.success { value in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(2, value)
            }.error { error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(Error.GeneralError, error as? Error)
                expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }
}
