//
//  SingleResponseType.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 8/6/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

public protocol SingleResponseType: ResponseType {

    @warn_unused_result
    func nextAnyway<U>(on queue: dispatch_queue_t, after: Result<T> throws -> Response<U>) -> Response<U>

    @warn_unused_result
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

    @warn_unused_result
    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> U) -> Response<U> {
        return nextAnyway(on: queue) { result in
            return Response<U> { $0.resolve(.Success(try after(result))) }.withLabel("NextAnyway.Map")
        }
    }

    @available(*, deprecated, message="After cannot return an optional Response<U>?. Did you forget to unwrap it?")
    @warn_unused_result
    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> Response<U>?) -> Response<U> { fatalError() }

    @available(*, deprecated, message="After cannot return an optional StreamResponse<U>?. Did you forget to unwrap it?")
    @warn_unused_result
    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> StreamResponse<U>?) -> StreamResponse<U> { fatalError() }
}

extension SingleResponseType {

    @warn_unused_result
    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> Response<U>) -> Response<U> {
        return nextAnyway(on: queue) { try after($0.get()) }
    }

    @warn_unused_result
    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> U) -> Response<U> {
        return nextAnyway(on: queue) { try after($0.get()) }
    }

    @warn_unused_result
    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> StreamResponse<U>) -> StreamResponse<U> {
        return nextAnyway(on: queue) { try after($0.get()) }
    }

    @available(*, deprecated, message="After cannot return an optional Response<U>?. Did you forget to unwrap it?")
    @warn_unused_result
    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> Response<U>?) -> Response<U> { fatalError() }

    @available(*, deprecated, message="After cannot return an optional StreamResponse<U>?. Did you forget to unwrap it?")
    @warn_unused_result
    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> StreamResponse<U>?) -> StreamResponse<U> { fatalError() }
}

extension SingleResponseType {

    @warn_unused_result
    public func nextInBackground<U>(after: T throws -> Response<U>) -> Response<U> {
        return next(on: defaultBackgroundQueue, after: after)
    }

    @warn_unused_result
    public func nextInBackground<U>(after: T throws -> U) -> Response<U> {
        return next(on: defaultBackgroundQueue, after: after)
    }

    @warn_unused_result
    public func nextInBackground<U>(after: T throws -> StreamResponse<U>) -> StreamResponse<U> {
        return next(on: defaultBackgroundQueue, after: after)
    }

    @available(*, deprecated, message="After cannot return an optional Response<U>?. Did you forget to unwrap it?")
    @warn_unused_result
    public func nextInBackground<U>(after: T throws -> Response<U>?) -> Response<U> { fatalError() }

    @available(*, deprecated, message="After cannot return an optional StreamResponse<U>?. Did you forget to unwrap it?")
    @warn_unused_result
    public func nextInBackground<U>(after: T throws -> StreamResponse<U>?) -> StreamResponse<U> { fatalError() }
}

extension SingleResponseType {

    @warn_unused_result
    public func asVoid() -> Response<Void> {
        return next(on: zalgo) { _ in return }
    }
}

extension SingleResponseType {

    @warn_unused_result
    public func recover(on queue: dispatch_queue_t = defaultQueue, recovery: ErrorType throws -> Response<T>) -> Response<T> {
        return nextAnyway(on: queue) { result in
            return RecoverResponse(result: result, on: queue, recovery: recovery)
        }
    }

    @warn_unused_result
    public func recover(on queue: dispatch_queue_t = defaultQueue, recovery: ErrorType throws -> T) -> Response<T> {
        return recover(on: queue) { error -> Response<T> in
            return Response { try $0.resolve(.Success(recovery(error))) }.withLabel("Recover.Map")
        }
    }

    @available(*, deprecated, message="Recovery cannot return an optional Response<T>?. Did you forget to unwrap it?")
    @warn_unused_result
    public func recover(on queue: dispatch_queue_t = defaultQueue, recovery: ErrorType throws -> Response<T>?) -> Response<T> { fatalError() }
}
