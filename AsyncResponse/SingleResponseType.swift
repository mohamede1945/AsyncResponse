//
//  SingleResponseType.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 8/6/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

public protocol SingleResponseType: ResponseType {

    func nextAnyway<U>(on queue: dispatch_queue_t, after: Result<T> throws -> Response<U>) -> Response<U>

    func nextAnyway<U>(on queue: dispatch_queue_t, after: Result<T> throws -> StreamResponse<U>) -> StreamResponse<U>
}

extension SingleResponseType {

    public var completed: Bool {
        return result != nil
    }

    public var succeeded: Bool {
        return result?.succeeded == true
    }

    public var failed: Bool {
        return result?.failed == true
    }
}

extension SingleResponseType {

    public func nextAnyway<U>(after: Result<T> throws -> Response<U>) -> Response<U> {
        return nextAnyway(on: defaultQueue, after: after)
    }

    public func nextAnyway<U>(after: Result<T> throws -> StreamResponse<U>) -> StreamResponse<U> {
        return nextAnyway(on: defaultQueue, after: after)
    }

    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> U) -> Response<U> {
        return nextAnyway(on: queue) { result in
            return Response<U> { $0.resolve(.Success(try after(result))) }.withLabel("NextAnyway.Map")
        }
    }

    @available(*, unavailable, message="Cannot return an optional Response")
    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> Response<U>?) -> Response<U> { fatalError() }

    @available(*, unavailable, message="Cannot return an optional StreamResponse")
    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> StreamResponse<U>?) -> StreamResponse<U> { fatalError() }
}

extension SingleResponseType {

    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> Response<U>) -> Response<U> {
        return nextAnyway(on: queue) { try after($0.get()) }
    }

    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> U) -> Response<U> {
        return nextAnyway(on: queue) { try after($0.get()) }
    }

    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> StreamResponse<U>) -> StreamResponse<U> {
        return nextAnyway(on: queue) { try after($0.get()) }
    }

    @available(*, unavailable, message="Cannot return an optional Response")
    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> Response<U>?) -> Response<U> { fatalError() }

    @available(*, unavailable, message="Cannot return an optional StreamResponse")
    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> StreamResponse<U>?) -> StreamResponse<U> { fatalError() }
}

extension SingleResponseType {

    public func nextInBackground<U>(after: T throws -> Response<U>) -> Response<U> {
        return next(on: defaultBackgroundQueue, after: after)
    }

    public func nextInBackground<U>(after: T throws -> U) -> Response<U> {
        return next(on: defaultBackgroundQueue, after: after)
    }

    public func nextInBackground<U>(after: T throws -> StreamResponse<U>) -> StreamResponse<U> {
        return next(on: defaultBackgroundQueue, after: after)
    }

    @available(*, unavailable, message="Cannot return an optional Response")
    public func nextInBackground<U>(after: T throws -> Response<U>?) -> Response<U> { fatalError() }

    @available(*, unavailable, message="Cannot return an optional StreamResponse")
    public func nextInBackground<U>(after: T throws -> StreamResponse<U>?) -> StreamResponse<U> { fatalError() }
}

extension SingleResponseType {

    public func asVoid() -> Response<Void> {
        return next(on: zalgo) { _ in return }
    }
}

extension SingleResponseType {

    public func recover(on queue: dispatch_queue_t = defaultQueue, recovery: ErrorType throws -> Response<T>) -> Response<T> {
        return nextAnyway(on: queue) { result in
            return Response<T> { (resolver: ResponseResolver) -> Void in
                switch result {
                case .Success(let value):
                    resolver.resolve(.Success(value))
                case .Error(let error):
                    try recovery(error).always(on: queue) { recoveryResult in
                        switch recoveryResult {
                        case .Success(let value):
                            resolver.resolve(.Success(value))
                        case .Error(let error):
                            resolver.resolve(.Error(error))
                        }
                    }
                }
            }.withLabel("Recover")
        }
    }

    public func recover(on queue: dispatch_queue_t = defaultQueue, recovery: ErrorType throws -> T) -> Response<T> {
        return recover(on: queue) { error -> Response<T> in
            return Response { try $0.resolve(.Success(recovery(error))) }.withLabel("Recover.Map")
        }
    }

    @available(*, unavailable, message="Cannot return an optional Response")
    public func recover(on queue: dispatch_queue_t = defaultQueue, recovery: ErrorType throws -> Response<T>?) -> Response<T> { fatalError() }
}
