//
//  ResponseType.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 7/30/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

public protocol ResponseType {
    associatedtype T

    var result: Result<T>? { get }

    func always(on queue: dispatch_queue_t, completion: Result<T> -> Void) -> Self
}

extension ResponseType {

    public var succeeded: Bool {
        return result?.succeeded == true
    }

    public var failed: Bool {
        return result?.failed == true
    }

    public func always(completion: Result<T> -> Void) -> Self {
        return always(on: defaultQueue, completion: completion)
    }

    public func success(on queue: dispatch_queue_t = defaultQueue, handler: T -> Void) -> Self {
        return always(on: queue) { result in
            switch result {
            case .Success(let value):
                handler(value)
            case .Error:
                break
            }
        }
    }

    public func error(on queue: dispatch_queue_t = defaultQueue, handler: ErrorType -> Void) -> Self {
        return always(on: queue) { result in
            switch result {
            case .Success:
                break
            case .Error(let error):
                handler(error)
            }
        }
    }
}
