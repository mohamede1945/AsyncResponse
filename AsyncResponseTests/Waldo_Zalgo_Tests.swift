//
//  Waldo_Zalgo_Tests.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 8/14/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import XCTest
@testable import AsyncResponse

class Waldo_Zalgo_Tests: XCTestCase {

    func testZalgoMain() {

        var called = false
        zalgo.executeConsideringZalgoAndWaldo {
            XCTAssertTrue(NSThread.isMainThread())
            called = true
        }
        XCTAssertTrue(called)
    }

    func testZalgoBackgorund() {

        let expectation = expectationWithDescription("background")

        dispatch_async(dispatch_get_global_queue(0, 0)) { 
            var called = false
            zalgo.executeConsideringZalgoAndWaldo {
                XCTAssertFalse(NSThread.isMainThread())
                called = true
            }
            XCTAssertTrue(called)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testWaldoMain() {

        let expectation = expectationWithDescription("background")

        var called = false
        waldo.executeConsideringZalgoAndWaldo {
            XCTAssertFalse(NSThread.isMainThread())
            called = true
            expectation.fulfill()
        }
        XCTAssertFalse(called)

        waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testWaldoBackground() {

        let expectation = expectationWithDescription("background")

        dispatch_async(dispatch_get_global_queue(0, 0)) {
            var called = false
            waldo.executeConsideringZalgoAndWaldo {
                XCTAssertFalse(NSThread.isMainThread())
                called = true
            }
            XCTAssertTrue(called)
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testMainQueue() {

        let expectation = expectationWithDescription("background")

        var called = false
        dispatch_get_main_queue().executeConsideringZalgoAndWaldo {
            XCTAssertTrue(NSThread.isMainThread())
            called = true
            expectation.fulfill()
        }
        XCTAssertFalse(called)

        waitForExpectationsWithTimeout(2, handler: nil)
    }

    func testBackgroundQueue() {

        let expectation = expectationWithDescription("background")

        var called = false
        dispatch_get_global_queue(0, 0).executeConsideringZalgoAndWaldo {
            XCTAssertFalse(NSThread.isMainThread())
            called = true
            expectation.fulfill()
        }
        XCTAssertFalse(called)

        waitForExpectationsWithTimeout(2, handler: nil)
    }

}
