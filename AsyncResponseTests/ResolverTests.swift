//
//  ResolverTests.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 8/14/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import XCTest
@testable import AsyncResponse


class ResolverTests: XCTestCase {

    func testStreamResponseResolver() {
        let response = DummyResponse { (resolver: StreamResponseResolver<Int>) -> Disposable in

            resolver.element(.Success(1))
            resolver.element(.Error(Error.GeneralError))
            resolver.resolve(.Success(100))
            resolver.dispose()

            return NoOperationDisposable()
        }

        assertResult([.Success(1), .Error(Error.GeneralError)], actual: response.elements)
        assertResult([.Success(100)], actual: response.resolves)
        XCTAssertEqual(1, response.disposes)
    }

    func testResponseResolver() {
        let response = DummyResponse { (resolver: ResponseResolver<Int>) -> Disposable in

            resolver.resolve(.Success(1))
            resolver.resolve(.Error(Error.GeneralError))
            resolver.resolve(.Success(100))
            resolver.dispose()
            return NoOperationDisposable()
        }

        assertResult([], actual: response.elements)
        assertResult([.Success(1), .Error(Error.GeneralError), .Success(100)], actual: response.resolves)
        XCTAssertEqual(1, response.disposes)
    }

    func testBlockResponseResolver() {

        var elements: [Result<Int>] = []
        var resolves: [Result<Int>] = []
        var disposes = 0

        let resolver = BlockResponseResolver(elementBlock: { elements.append($0)
            }, resolveBlock: { resolves.append($0) }, disposeBlock: { disposes += 1 })

        resolver.element(.Success(1))
        resolver.element(.Error(Error.GeneralError))
        resolver.element(.Success(100))
        resolver.resolve(.Error(Error.CustomError))
        resolver.dispose()

        assertResult([.Success(1), .Error(Error.GeneralError), .Success(100)], actual: elements)
        assertResult([.Error(Error.CustomError)], actual: resolves)
        XCTAssertEqual(1, disposes)
    }

    private func assertResult(expected: [Result<Int>], actual: [Result<Int>], file: StaticString = #file, line: UInt = #line) {

        XCTAssertEqual(expected.count, actual.count, file: file, line: line)
        if expected.count == actual.count {
            for i in 0..<expected.count {
                let expectedResult = expected[i]
                let actualResult = actual[i]
                XCTAssertEqual(expectedResult.success, actualResult.success)
                XCTAssertEqual(expectedResult.error as? Error, actualResult.error as? Error)
            }
        }
    }
}


private class DummyResponse<T>: BaseResponse<T> {

    var resolves: [Result<T>] = []
    var elements: [Result<T>] = []

    var disposes = 0

    override init(@noescape resolution: StreamResponseResolver<T> -> Disposable) {
        super.init(resolution: resolution)
    }

    init(@noescape resolution: ResponseResolver<T> -> Disposable) {
        super.init { superResolver in
            let resolver = ResponseResolver(resolver: superResolver)
            return resolution(resolver)
        }
    }

    private override func resolve(result: Result<T>) {
        resolves.append(result)
    }

    private override func element(result: Result<T>) {
        elements.append(result)
    }

    private override func dispose() {
        disposes += 1
    }
}
