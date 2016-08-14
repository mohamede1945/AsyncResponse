//
//  StreamResponse.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 7/30/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

public class StreamResponse<T>: BaseResponse<T>, StreamResponseType {

    public convenience init(@noescape resolution: StreamResponseResolver<T> -> Void) {
        self.init { resolver -> Disposable in
            resolution(resolver)
            return NoOperationDisposable()
        }
    }

    public override init(@noescape resolution: StreamResponseResolver<T> -> Disposable) {
        super.init  { resolver -> Disposable in
            return resolution(resolver)
        }
    }

    public class func asyncResponse(disposable disposable: Disposable = NoOperationDisposable()) -> (response: StreamResponse<T>, resolver: StreamResponseResolver<T>) {

        var resolver: StreamResponseResolver<T>!
        let response = StreamResponse { (r: StreamResponseResolver) -> Disposable in
            resolver = r
            return disposable
        }
        return (response, resolver)
    }

    @warn_unused_result
    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> Response<U>) -> StreamResponse<U> {

        let (monitorResponse, monitorResolver) = StreamResponse<U>.asyncResponse()
        monitorResponse.label = "NextAnywayMonitor"

        func next(result: Result<T>, resolving: Bool) {
            do {
                try after(result)
                    .addListener(BlockResponseResolver<U>(
                        elementBlock: nil,
                        resolveBlock: {
                            if !resolving {
                                monitorResolver.element($0)
                            } else {
                                monitorResolver.resolve($0)
                            }
                        },
                        disposeBlock: nil), on: queue)
            } catch {
                if !resolving {
                    monitorResolver.element(.Error(error))
                } else {
                    monitorResolver.resolve(.Error(error))
                }
            }
        }

        addListener(
            BlockResponseResolver<T>(
                elementBlock: { next($0, resolving: false) },
                resolveBlock: { next($0, resolving: true) },
                disposeBlock: nil),
            on: queue)

        return monitorResponse
    }
}

