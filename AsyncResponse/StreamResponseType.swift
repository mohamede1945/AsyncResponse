//
//  StreamResponseType.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 8/6/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

public protocol StreamResponseType: ResponseType {

    @warn_unused_result
    func nextAnyway<U>(on queue: dispatch_queue_t, after: Result<T> throws -> Response<U>) -> StreamResponse<U>
}

extension StreamResponse {

    @warn_unused_result
    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> U) -> StreamResponse<U> {
        return nextAnyway(on: queue) { result in
            return Response<U> { $0.resolve(.Success(try after(result))) }.withLabel("NextAnyway.Map")
        }
    }

    @available(*, deprecated, message="After cannot return an optional Response<U>?. Did you forget to unwrap it?")
    @warn_unused_result
    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> Response<U>?) -> StreamResponse<U> { fatalError() }
}

extension StreamResponse {

    @warn_unused_result
    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> Response<U>) -> StreamResponse<U> {
        return nextAnyway(on: queue) { try after($0.get()) }
    }

    @warn_unused_result
    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> U) -> StreamResponse<U> {
        return nextAnyway(on: queue) { try after($0.get()) }
    }

    @available(*, deprecated, message="After cannot return an optional Response<U>?. Did you forget to unwrap it?")
    @warn_unused_result
    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> Response<U>?) -> StreamResponse<U> { fatalError() }
}

extension StreamResponse {

    @warn_unused_result
    public func nextInBackground<U>(after: T throws -> Response<U>) -> StreamResponse<U> {
        return next(on: defaultBackgroundQueue, after: after)
    }

    @warn_unused_result
    public func nextInBackground<U>(after: T throws -> U) -> StreamResponse<U> {
        return next(on: defaultBackgroundQueue, after: after)
    }

    @available(*, deprecated, message="After cannot return an optional Response<U>?. Did you forget to unwrap it?")
    @warn_unused_result
    public func nextInBackground<U>(after: T throws -> Response<U>?) -> StreamResponse<U> { fatalError() }
}

extension StreamResponse {

    @warn_unused_result
    public func asVoid() -> StreamResponse<Void> {
        return next(on: zalgo) { _ in return }
    }
}

extension StreamResponse {

    @warn_unused_result
    public func recover(on queue: dispatch_queue_t = defaultQueue, recovery: ErrorType throws -> Response<T>) -> StreamResponse<T> {
        return nextAnyway(on: queue) { result in
            return RecoverResponse(result: result, on: queue, recovery: recovery)
        }
    }

    @warn_unused_result
    public func recover(on queue: dispatch_queue_t = defaultQueue, recovery: ErrorType throws -> T) -> StreamResponse<T> {
        return recover(on: queue) { error -> Response<T> in
            return Response { $0.resolve(.Success(try recovery(error))) }.withLabel("Recover.Map")
        }
    }

    @available(*, deprecated, message="Recovery cannot return an optional Response<U>?. Did you forget to unwrap it?")
    @warn_unused_result
    public func recover(on queue: dispatch_queue_t = defaultQueue, recovery: ErrorType throws -> Response<T>?) -> StreamResponse<T> { fatalError() }
}
