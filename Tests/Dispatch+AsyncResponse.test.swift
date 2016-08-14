//
//  Dispatch+AsyncResponse.test.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 8/14/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import XCTest
import AsyncResponse

class Dispatch_AsyncResponseTests: XCTestCase {
    
    func testDispatch_async() {

        let expectation = expectationWithDescription("async")

        var called = false
        dispatch_get_global_queue(0, 0).async { () -> Int in
            XCTAssertFalse(NSThread.isMainThread())
            return 20
            }.success { value in
                called = true

                XCTAssertEqual(20, value)
                expectation.fulfill()
        }
        XCTAssertFalse(called)
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testDispatch_asyncError() {

        let expectation = expectationWithDescription("async")

        var called = false
        dispatch_get_global_queue(0, 0).async { () -> Int in
            XCTAssertFalse(NSThread.isMainThread())
            throw Error.GeneralError
            }.error { error in
                called = true

                XCTAssertEqual(Error.GeneralError, error as? Error)
                expectation.fulfill()
        }
        XCTAssertFalse(called)
        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testDispatch_after() {

        let expectation = expectationWithDescription("after")

        var called = false
        dispatch_get_global_queue(0, 0).after(0.1) { () -> Int in
            XCTAssertFalse(NSThread.isMainThread())
            return 20
            }.success { value in
                called = true

                XCTAssertEqual(20, value)
                expectation.fulfill()
        }
        XCTAssertFalse(called)

        waitForExpectationsWithTimeout(1, handler: nil)
    }

    func testDispatch_afterError() {

        let expectation = expectationWithDescription("after")

        var called = false
        dispatch_get_global_queue(0, 0).after(0.1) { () -> Int in
            XCTAssertFalse(NSThread.isMainThread())
            throw Error.CustomError
            }.error { error in
                called = true

                XCTAssertEqual(Error.CustomError, error as? Error)
                expectation.fulfill()
        }
        XCTAssertFalse(called)

        waitForExpectationsWithTimeout(1, handler: nil)
    }
}
