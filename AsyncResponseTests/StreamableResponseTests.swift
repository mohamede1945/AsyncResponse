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
            .nextAnyway(on: zalgo) { (n) -> StreamResponse<Int> in
                actual.append("\(n.success!)+++\(n.success!)")
                return streamOperation(values)
            }.nextAnyway(on: zalgo) { (v) -> Response<String> in
                return Response("\(v.success!)-\(v.success!)")
            }.always(on: zalgo) { value in
                actual.append(value.success!)
                if actual.count == values.count + 1 { expectation.fulfill() }
        }

        waitForExpectationsWithTimeout(10, handler: nil)

        let expected = ["100+++100", "10-10", "1-1", "2-2", "3-3", "4-4", "5-5", "6-6"]
        XCTAssertEqual(expected, actual)
    }

    func testSyncResponseThenStreamableDEADLOCK() {

        let expectation = expectationWithDescription("stream expect")

        let values = [10, 1, 2, 3, 4, 5, 6]
        var actual: [String] = []

        Response(100)
            .nextAnyway(on: zalgo) { (n) -> StreamResponse<Int> in
                actual.append("\(n.success!)+++\(n.success!)")
                return streamOperation(values)
            }.nextAnyway(on: defaultQueue) { (v) -> Response<String> in
                return Response("\(v.success!)-\(v.success!)")
            }.success(on: zalgo) { value in
                actual.append(value)
                if actual.count == values.count + 1 { expectation.fulfill() }
            }.error(on: zalgo) { _ in XCTFail() }

        waitForExpectationsWithTimeout(10, handler: nil)

        let expected = ["100+++100", "10-10", "1-1", "2-2", "3-3", "4-4", "5-5", "6-6"]
        XCTAssertEqual(expected, actual)
    }
}

