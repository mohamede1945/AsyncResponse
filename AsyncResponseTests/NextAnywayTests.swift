//
//  NextAnywayTests.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 8/13/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import XCTest
import AsyncResponse

class NextAnywayTests: XCTestCase {

    func testResponse() {

        let expectation = expectationWithDescription("next anyway")

        operation(1)
            .nextAnyway { result -> Response<Int> in
                XCTAssertTrue(NSThread.isMainThread())
                return operation(2)
            }.nextAnyway { result -> Int in
                XCTAssertTrue(NSThread.isMainThread())
                return result.success! + 1
            }.success { value in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(3, value)
                expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testStream() {

        let expectation = expectationWithDescription("next anyway")
        let values = [2, 1]
        var expected: [Int] = []

        streamOperation(values)
            .nextAnyway { result -> Response<Int> in
                XCTAssertTrue(NSThread.isMainThread())
                return operation(result.success! * 2)
            }.nextAnyway { result -> Int in
                XCTAssertTrue(NSThread.isMainThread())
                return result.success! + 1
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
}
