//
//  ResultTests.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 8/2/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import XCTest
import AsyncResponse

class ResultTests: XCTestCase {

    func testSuccessResult() {
        let result = Result.Success(1)

        XCTAssertTrue(result.succeeded)
        XCTAssertFalse(result.failed)
        XCTAssertEqual(1, result.success)
        XCTAssertNil(result.error)
        XCTAssertEqual(1, try result.get())
        XCTAssertEqual("Success(1)", result.debugDescription)
        XCTAssertEqual("Success(1)", result.description)
    }

    func testErrorResult() {
        let result = Result<Int>.Error(Error.GeneralError)

        XCTAssertTrue(result.failed)
        XCTAssertFalse(result.succeeded)
        XCTAssertEqual(Error.GeneralError, result.error as? Error)
        XCTAssertNil(result.success)
        do {
            let _ = try result.get()
            XCTFail()
        } catch {
            XCTAssertEqual(error as? Error, Error.GeneralError)
        }
        XCTAssertEqual("Error(GeneralError)", result.debugDescription)
        XCTAssertEqual("Error(GeneralError)", result.description)
    }
}
