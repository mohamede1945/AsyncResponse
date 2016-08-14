//
//  DisposableTests.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 8/14/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import XCTest
import AsyncResponse

class DisposableTests: XCTestCase {
    
    func testImplementingDisposable() {
        class Dummy: Disposable {
            static var calls = 0
            private func dispose() {
                Dummy.calls += 1
            }
        }

        let (response1, _) = Response<Int>.asyncResponse(disposable: Dummy())
        response1.dispose()

        XCTAssertEqual(1, Dummy.calls)

        let response2 = Response<Int> { _ -> Disposable in
            return Dummy()
        }
        response2.dispose()

        XCTAssertEqual(2, Dummy.calls)
    }

    func testNoOperationDisposable() {

        let (response1, _) = StreamResponse<Int>.asyncResponse(disposable: NoOperationDisposable())
        response1.dispose()
        // no side effects
    }

    func testBlockDisposable() {

        var calls = 0
        let response = StreamResponse<Int> { _ -> Disposable in
            return BlockDisposable {
                calls += 1
            }
        }

        response.dispose()

        XCTAssertEqual(1, calls)
    }
}
