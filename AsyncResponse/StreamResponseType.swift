//
//  StreamResponseType.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 8/6/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

public protocol StreamResponseType: ResponseType {

    func nextAnyway<U>(on queue: dispatch_queue_t, after: Result<T> throws -> Response<U>) -> StreamResponse<U>
}

extension StreamResponse {

    func nextAnyway<U>(after: Result<T> throws -> Response<U>) -> StreamResponse<U> {
        return nextAnyway(on: defaultQueue, after: after)
    }

    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> U) -> StreamResponse<U> {
        return nextAnyway(on: queue) { result in
            return Response<U> { $0.resolve(.Success(try after(result))) }.withLabel("NextAnyway.Map")
        }
    }

    @available(*, unavailable, message="Cannot return an optional Response")
    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> Response<U>?) -> StreamResponse<U> { fatalError() }
}

extension StreamResponse {

    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> Response<U>) -> StreamResponse<U> {
        return nextAnyway(on: queue) { try after($0.get()) }
    }

    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> U) -> StreamResponse<U> {
        return nextAnyway(on: queue) { try after($0.get()) }
    }

    @available(*, unavailable, message="Cannot return an optional Response")
    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> Response<U>?) -> StreamResponse<U> { fatalError() }
}

extension StreamResponse {

    public func nextInBackground<U>(after: T throws -> Response<U>) -> StreamResponse<U> {
        return next(on: defaultBackgroundQueue, after: after)
    }

    public func nextInBackground<U>(after: T throws -> U) -> StreamResponse<U> {
        return next(on: defaultBackgroundQueue, after: after)
    }

    @available(*, unavailable, message="Cannot return an optional Response")
    public func nextInBackground<U>(after: T throws -> Response<U>?) -> StreamResponse<U> { fatalError() }
}

extension StreamResponse {

    public func asVoid() -> StreamResponse<Void> {
        return next(on: zalgo) { _ in return }
    }
}

extension StreamResponse {

    public func recover(on queue: dispatch_queue_t = defaultQueue, recovery: ErrorType throws -> Response<T>) -> StreamResponse<T> {
        return nextAnyway(on: queue) { result in
            return Response { (resolver: ResponseResolver) -> Void in
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

    public func recover(on queue: dispatch_queue_t = defaultQueue, recovery: ErrorType throws -> T) -> StreamResponse<T> {
        return recover(on: queue) { error -> Response<T> in
            return Response { $0.resolve(.Success(try recovery(error))) }.withLabel("Recover.Map")
        }
    }

    @available(*, unavailable, message="Cannot return an optional Response")
    public func recover(on queue: dispatch_queue_t = defaultQueue, recovery: ErrorType throws -> Response<T>?) -> StreamResponse<T> { fatalError() }
}
