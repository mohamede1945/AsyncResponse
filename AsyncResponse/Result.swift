//
//  Result.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 7/20/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

public enum Result<Value>: CustomStringConvertible, CustomDebugStringConvertible {
    case Success(Value)
    case Error(ErrorType)

    public var succeeded: Bool {
        return success != nil
    }

    public var failed: Bool {
        return error != nil
    }

    public var success: Value? {
        switch self {
        case .Success(let data):
            return data
        default:
            return nil
        }
    }

    public var error: ErrorType? {
        switch self {
        case .Error(let error):
            return error
        default:
            return nil
        }
    }

    public func get() throws -> Value {
        switch self {
        case .Success(let x): return x
        case .Error(let e): throw e
        }
    }

    public var debugDescription: String {
        return description
    }

    public var description: String {
        switch self {
        case .Success(let value):
            return "Success(\(value))"
        case .Error(let error):
            return "Error(\(error))"
        }
    }
}
