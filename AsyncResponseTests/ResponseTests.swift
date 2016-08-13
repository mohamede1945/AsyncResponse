//
//  AsyncResponseTests.swift
//  AsyncResponseTests
//
//  Created by Mohamed Afifi on 7/26/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import XCTest
import AsyncResponse

class ResponseTests: XCTestCase {

    func testDescription() {
        let (response, resolver) = Response<Int>.asyncResponse()

        let reference = String(format:"%p", unsafeBitCast(response, Int.self))

        XCTAssertEqual("<Response<Int>: \(reference) result=pending...; always=0; branches=0>", response.description)
        XCTAssertEqual("<Response<Int>: \(reference) result=pending...; always=0; branches=0>", response.debugDescription)

        response.label = "test"

        XCTAssertEqual("<Response<Int>: \(reference) label=test; result=pending...; always=0; branches=0>", response.description)
        XCTAssertEqual("<Response<Int>: \(reference) label=test; result=pending...; always=0; branches=0>", response.debugDescription)

        resolver.resolve(.Success(1))

        XCTAssertEqual("<Response<Int>: \(reference) label=test; result=Success(1); always=0; branches=0>", response.description)
        XCTAssertEqual("<Response<Int>: \(reference) label=test; result=Success(1); always=0; branches=0>", response.debugDescription)
    }

    func testInitWithValue() {
        let response1 = Response(10)
        XCTAssertTrue(response1.completed)
        XCTAssertTrue(response1.succeeded)
        XCTAssertFalse(response1.failed)
        XCTAssertEqual(10, response1.result?.success)

        let response2 = Response<String>(error: NSError(domain: "", code: 0, userInfo: nil))
        XCTAssertTrue(response2.completed)
        XCTAssertFalse(response2.succeeded)
        XCTAssertTrue(response2.failed)
    }

    func testInitWithResolverOptional() -> Void {
        let response1 = Response(resolver: { (resolver: (String?, NSError?) -> Void) in
            resolver("10", nil)
        })
        XCTAssertTrue(response1.completed)
        XCTAssertTrue(response1.succeeded)
        XCTAssertFalse(response1.failed)
        XCTAssertEqual("10", response1.result?.success)

        let response2 = Response(resolver: { (resolver: (String?, NSError?) -> Void) in
            resolver(nil, Error.CustomError as NSError)
        })
        XCTAssertTrue(response2.completed)
        XCTAssertFalse(response2.succeeded)
        XCTAssertTrue(response2.failed)
    }

    func testInitWithResolver() -> Void {
        let response1 = Response(resolver: { (resolver: (String, NSError?) -> Void) in
            resolver("10", nil)
        })
        XCTAssertTrue(response1.completed)
        XCTAssertTrue(response1.succeeded)
        XCTAssertFalse(response1.failed)
        XCTAssertEqual("10", response1.result?.success)

        let response2 = Response(resolver: { (resolver: (String, NSError?) -> Void) in
            resolver("10", Error.CustomError as NSError)
        })
        XCTAssertTrue(response2.completed)
        XCTAssertFalse(response2.succeeded)
        XCTAssertTrue(response2.failed)
    }

    func testInitWithResolversThrowingError() -> Void {

        var called = false
        Response<Int> { _, _ in
            throw Error.CustomError
            }.error (on: zalgo) { error in
                called = true
                XCTAssertEqual(error as? Error, Error.CustomError)
        }
        XCTAssertTrue(called)
    }

    func testAsyncResponse() {
        let (response1, resolver1) = Response<Int>.asyncResponse()
        XCTAssertFalse(response1.completed)
        resolver1.resolve(.Success(1))
        XCTAssertTrue(response1.completed)
        XCTAssertTrue(response1.succeeded)
        XCTAssertFalse(response1.failed)
        XCTAssertEqual(1, response1.result?.success)

        let (response2, resolver2) = Response<Int>.asyncResponse()
        XCTAssertFalse(response2.completed)
        resolver2.resolve(.Error(Error.GeneralError))
        XCTAssertTrue(response2.completed)
        XCTAssertFalse(response2.succeeded)
        XCTAssertTrue(response2.failed)
        XCTAssertEqual(Error.GeneralError._domain, response2.result?.error?._domain)
        XCTAssertEqual(Error.GeneralError._code, response2.result?.error?._code)
    }

    func testCompleted() {

        let expectation = expectationWithDescription("async expect")

        let queue = defaultBackgroundQueue
        let response = operation(1, queue: queue)
        XCTAssertFalse(response.completed)
        response.always { [weak response] result in

            XCTAssertTrue(response?.completed == true)
            XCTAssertTrue(response?.succeeded == true)
            XCTAssertTrue(response?.failed == false)

            XCTAssertTrue(NSThread.isMainThread())
            switch result {
            case .Success(1): break
            default: XCTFail()
            }
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testAlwaysSuccess() {

        let expectation = expectationWithDescription("async expect")

        let queue = defaultBackgroundQueue
        operation(1, queue: queue)
            .always(on: defaultBackgroundQueue) { result in
                XCTAssertFalse(NSThread.isMainThread())
                switch result {
                case .Success(1): break
                default: XCTFail()
                }
                expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testNestedAlways() {

        let expectation = expectationWithDescription("async expect")

        let queue = defaultBackgroundQueue
        let response = operation(1, queue: queue)
        XCTAssertFalse(response.completed)
        response.always(on: dispatch_get_main_queue()) { [weak response] result in
            XCTAssertTrue(NSThread.isMainThread())

            response?.always { result2 in
                switch result2 {
                case .Success(1): break
                default: XCTFail()
                }
                expectation.fulfill()
            }
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testAlwaysFailure() {

        let expectation = expectationWithDescription("async expect")

        let queue = defaultBackgroundQueue
        let response = operation(1, error: Error.GeneralError, queue: queue)
        response.always { [weak response] result in
            XCTAssertTrue(NSThread.isMainThread())

            XCTAssertTrue(response?.completed == true)
            XCTAssertTrue(response?.succeeded == false)
            XCTAssertTrue(response?.failed == true)

            switch result {
            case .Error(Error.GeneralError): break
            default: XCTFail()
            }
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testSuccess() {

        let expectation = expectationWithDescription("async expect")

        let queue = dispatch_get_main_queue()
        operation(1, queue: queue)
            .success { successData in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(1, successData)
                expectation.fulfill()
            }.error { _ in
                XCTFail()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testError() {

        let expectation = expectationWithDescription("async expect")

        let queue = dispatch_get_main_queue()
        operation(1, error: Error.GeneralError, queue: queue)
            .error { error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(Error.GeneralError, error as? Error)
                expectation.fulfill()
            }.success { _ in
                XCTFail()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testMultipleSuccess() {
        let expectation1 = expectationWithDescription("async expect 1")
        let expectation2 = expectationWithDescription("async expect 2")
        let expectation3 = expectationWithDescription("async expect 3")

        let queue = dispatch_get_main_queue()
        operation(1, queue: queue)
            .success { successData in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(1, successData)
                expectation1.fulfill()

            }.success(on: defaultBackgroundQueue) { successData in
                XCTAssertFalse(NSThread.isMainThread())
                XCTAssertEqual(1, successData)
                expectation2.fulfill()
            }.success(on: dispatch_get_main_queue()) { successData in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(1, successData)
                expectation3.fulfill()
            }.error { _ in
                XCTFail()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testMultipleError() {
        let expectation1 = expectationWithDescription("async expect 1")
        let expectation2 = expectationWithDescription("async expect 2")
        let expectation3 = expectationWithDescription("async expect 3")

        let queue = dispatch_get_main_queue()
        operation(1, error: Error.GeneralError, queue: queue)
            .success { successData in
                XCTFail()
            }.error(on: defaultBackgroundQueue) { error in
                XCTAssertFalse(NSThread.isMainThread())
                XCTAssertEqual(Error.GeneralError, error as? Error)
                expectation1.fulfill()
            }.error(on: dispatch_get_main_queue()) { error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(Error.GeneralError, error as? Error)
                expectation2.fulfill()
            }.error { error in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(Error.GeneralError, error as? Error)
                expectation3.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testNextSuccess() {
        let expectation1 = expectationWithDescription("async expect 1")
        let expectation2 = expectationWithDescription("async expect 2")
        let expectation3 = expectationWithDescription("async expect 3")

        operation(11)
            .success { result in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(11, result)
                expectation1.fulfill()
            }.next(on: defaultBackgroundQueue) { result -> Response<String> in
                XCTAssertFalse(NSThread.isMainThread())
                return operation(result.description)
            }.success { result in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual("11", result)
                expectation2.fulfill()
            }.next { result -> Response<Int> in
                return operation(1)
            }.success { result in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(1, result)
                expectation3.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testNextFailureLast() {
        let expectation1 = expectationWithDescription("async expect 1")
        let expectation2 = expectationWithDescription("async expect 2")
        let expectation3 = expectationWithDescription("async expect 3")

        operation(22)
            .success { result in
                XCTAssertEqual(22, result)
                expectation1.fulfill()
            }.next { result -> Response<String> in
                return operation(result.description)
            }.success { result in
                XCTAssertEqual("22", result)
                expectation2.fulfill()
            }.next { result -> Response<Int> in
                return operation(1, error: Error.GeneralError)
            }.success { result in
                XCTFail()
                expectation3.fulfill()
            }.error { error in
                XCTAssertEqual(Error.GeneralError, error as? Error)
                expectation3.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testNextFailureFirst() {
        let expectation1 = expectationWithDescription("async expect 1")
        let expectation2 = expectationWithDescription("async expect 2")
        let expectation3 = expectationWithDescription("async expect 3")

        operation(1, error: Error.GeneralError)
            .success { result in
                XCTFail()
                expectation1.fulfill()
            }.error { error in
                XCTAssertEqual(Error.GeneralError, error as? Error)
                expectation1.fulfill()
            }.next { result -> Response<String> in
                return operation(result.description)
            }.success { result in
                XCTFail()
                expectation2.fulfill()
            }.error { error in
                XCTAssertEqual(Error.GeneralError, error as? Error)
                expectation2.fulfill()
            }.next { result -> Response<Int> in
                return operation(1)
            }.success { result in
                XCTFail()
                expectation3.fulfill()
            }.error { error in
                XCTAssertEqual(Error.GeneralError, error as? Error)
                expectation3.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testNextAlwaysSuccess() {
        let expectation1 = expectationWithDescription("async expect 1")
        let expectation2 = expectationWithDescription("async expect 2")
        let expectation3 = expectationWithDescription("async expect 3")

        operation(1)
            .success { result in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(1, result)
                expectation1.fulfill()
            }.nextAnyway(on: defaultBackgroundQueue) { result -> Response<String> in
                XCTAssertFalse(NSThread.isMainThread())
                if case .Success(let data) = result {
                    return operation(data.description)
                } else {
                    XCTFail()
                    return Response("")
                }
            }.success { result in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual("1", result)
                expectation2.fulfill()
            }.nextAnyway { result in
                return operation(1)
            }.success { result in
                XCTAssertTrue(NSThread.isMainThread())
                XCTAssertEqual(1, result)
                expectation3.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testNextAlwaysFailureLast() {
        let expectation1 = expectationWithDescription("async expect 1")
        let expectation2 = expectationWithDescription("async expect 2")
        let expectation3 = expectationWithDescription("async expect 3")

        operation(21)
            .success { result in
                XCTAssertEqual(21, result)
                expectation1.fulfill()
            }.nextAnyway { result -> Response<String> in
                if case .Success(let data) = result {
                    return operation(data.description)
                } else {
                    XCTFail()
                    return Response("")
                }
            }.success { result in
                XCTAssertEqual("21", result)
                expectation2.fulfill()
            }.nextAnyway { result -> Response<Int> in
                return operation(1, error: Error.GeneralError)
            }.success { result in
                XCTFail()
                expectation3.fulfill()
            }.error { error in
                XCTAssertEqual(Error.GeneralError, error as? Error)
                expectation3.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testNextAlwaysFailureFirst() {
        let expectation1 = expectationWithDescription("async expect 1")
        let expectation2 = expectationWithDescription("async expect 2")
        let expectation3 = expectationWithDescription("async expect 3")

        operation(1, error: Error.GeneralError)
            .success { result in
                XCTFail()
                expectation1.fulfill()
            }.error { error in
                XCTAssertEqual(Error.GeneralError, error as? Error)
                expectation1.fulfill()
            }.nextAnyway { result -> Response<String> in
                if case .Success = result {
                    XCTFail()
                    return Response("")
                } else {
                    return operation("hello 12")
                }
            }.success { result in
                XCTAssertEqual("hello 12", result)
                expectation2.fulfill()
            }.error { error in
                XCTFail()
                expectation2.fulfill()
            }.nextAnyway { result -> Response<Int> in
                return operation(1)
            }.success { result in
                XCTAssertEqual(1, result)
                expectation3.fulfill()
            }.error { error in
                XCTFail()
                expectation3.fulfill()
        }

        waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testMultipleCallsToSuccess() {

        let (response1, resolver1) = Response<Int>.asyncResponse()

        var numberOfCalls = 0
        response1
            .always { _ in
                numberOfCalls += 1
                XCTAssertEqual(1, numberOfCalls)
        }

        resolver1.resolve(.Success(1))
        resolver1.resolve(.Success(2)) // should call the always
        resolver1.resolve(.Success(3)) // should call the always
        XCTAssertEqual(3, response1.result?.success)
    }

    func testResponseDeallocated() {

        class Test {
            static var deallocated = false
            let (response1, resolver1) = Response<Int>.asyncResponse()

            init() {
                response1.always(on: zalgo) { _ in
                    XCTAssertNotNil(self.response1)
                }
                resolver1.resolve(.Success(1))
            }

            deinit {
                Test.deallocated = true
            }
        }
        
        weak var weakValue: Test?
        autoreleasepool {
            let value = Test()
            XCTAssertFalse(Test.deallocated)
            weakValue = value
        }
        XCTAssertNil(weakValue)
        XCTAssertTrue(Test.deallocated)
    }
}
