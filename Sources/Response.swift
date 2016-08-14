//
//  Response.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 7/30/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

public class Response<T>: BaseResponse<T>, SingleResponseType {

    public override init(_ value: T) {
        super.init(value)
    }

    public override init(error: ErrorType) {
        super.init(error: error)
    }

    public convenience init(@noescape resolution: ResponseResolver<T> throws -> Void) {
        self.init { resolver -> Disposable in
            try resolution(resolver)
            return NoOperationDisposable()
        }
    }

    public init(@noescape resolution: ResponseResolver<T> throws -> Disposable) {
        super.init { superResolver in
            let resolver = ResponseResolver(resolver: superResolver)
            do {
                return try resolution(resolver)
            } catch {
                resolver.resolve(.Error(error))
                return NoOperationDisposable()
            }
        }
    }

    public convenience init(@noescape resolvers: (success: T -> Void, failure: ErrorType -> Void) throws -> Void) {
        self.init { (resolver: ResponseResolver) -> Void in
            let success: T -> Void = { value in
                resolver.resolve(.Success(value))
            }
            let failure: ErrorType -> Void = { error in
                resolver.resolve(.Error(error))
            }
            do {
                try resolvers(success: success, failure: failure)
            } catch {
                resolver.resolve(.Error(error))
            }
        }
    }

    public convenience init(@noescape resolver: ((T?, NSError?) -> Void) throws -> Void) {
        self.init(resolvers: { success, failure in
            try resolver { value, error in
                if let error = error {
                    failure(error)
                } else if let value = value {
                    success(value)
                } else {
                    fatalError("[AsyncResponse] 'init(resolver: ((Value?, NSError?) -> Void)' resolver(nil, nil) is invalid")
                }
            }
        })
    }

    public convenience init(@noescape resolver: ((T, NSError?) -> Void) throws -> Void) {
        self.init(resolvers: { success, failure in
            try resolver { value, error in
                if let error = error {
                    failure(error)
                } else {
                    success(value)
                }
            }
        })
    }

    public class func asyncResponse(disposable disposable: Disposable = NoOperationDisposable()) -> (response: Response<T>, resolver: ResponseResolver<T>) {
        var resolver: ResponseResolver<T>!
        let response = Response { r -> Disposable in
            resolver = r
            return disposable
        }
        return (response, resolver)
    }

    @warn_unused_result
    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> Response<U>) -> Response<U> {

        let (monitorResponse, monitorResolver) = Response<U>.asyncResponse()
        monitorResponse.label = "NextAnywayMonitor"

            addListener(
                BlockResponseResolver<T>(
                    elementBlock: nil,
                    resolveBlock: { result in
                        do {
                            try after(result)
                                .addListener(BlockResponseResolver<U>(
                                    elementBlock: nil, // will never be called
                                    resolveBlock: { monitorResolver.resolve($0) },
                                    disposeBlock: nil), on: queue)
                        } catch {
                            monitorResolver.resolve(.Error(error))
                        }
                    }, disposeBlock: nil),
                on: queue)

        return monitorResponse
    }

    @warn_unused_result
    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> StreamResponse<U>) -> StreamResponse<U> {

        let (monitorResponse, monitorResolver) = StreamResponse<U>.asyncResponse()
        monitorResponse.label = "NextAnywayMonitor"

        addListener(
            BlockResponseResolver<T>(
                elementBlock: nil,
                resolveBlock: { result in
                    do {
                        try after(result)
                            .addListener(BlockResponseResolver<U>(
                                elementBlock: { monitorResolver.element($0) },
                                resolveBlock: { monitorResolver.resolve($0) },
                                disposeBlock: nil), on: queue)
                    } catch {
                        monitorResolver.resolve(.Error(error))
                    }
                }, disposeBlock: nil),
            on: queue)

        return monitorResponse
    }
}
