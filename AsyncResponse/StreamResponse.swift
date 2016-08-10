//
//  StreamResponse.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 7/30/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

public class StreamResponse<T>: BaseResponse<T>, StreamResponseType {

    public init(@noescape resolution: StreamResponseResolver<T> -> Void) {
        super.init  { resolver -> Disposable? in
            resolution(resolver)
            return nil
        }
    }

    public init(@noescape resolution: StreamResponseResolver<T> -> Disposable) {
        super.init  { resolver -> Disposable? in
            return resolution(resolver)
        }
    }

    private override init(@noescape resolution: StreamResponseResolver<T> -> Disposable?) {
        super.init(resolution: resolution)
    }

    public class func asyncResponse(disposable disposable: Disposable? = nil) -> (response: StreamResponse<T>, resolver: StreamResponseResolver<T>) {

        var resolver: StreamResponseResolver<T>!
        let response = StreamResponse { (r: StreamResponseResolver) -> Disposable? in
            resolver = r
            return disposable
        }
        return (response, resolver)
    }

    @warn_unused_result
    public func nextAnyway<U>(on queue: dispatch_queue_t, after: Result<T> throws -> Response<U>) -> StreamResponse<U> {

        let (monitorResponse, monitorResolver) = StreamResponse<U>.asyncResponse()
        monitorResponse.label = "NextAnywayMonitor"

        func next(result: Result<T>, intermediate: Bool) {
            do {
                try after(result)
                    .addListener(BlockResponseResolver<U>(
                        elementBlock: { _ in },
                        resolveBlock: {
                            if intermediate {
                                monitorResolver.element($0)
                            } else {
                                monitorResolver.resolve($0)
                            }
                        },
                        disposeBlock: { }), on: queue)
            } catch {
                if intermediate {
                    monitorResolver.element(.Error(error))
                } else {
                    monitorResolver.resolve(.Error(error))
                }
            }
        }

        addListener(
            BlockResponseResolver<T>(
                elementBlock: { next($0, intermediate: true) },
                resolveBlock: { next($0, intermediate: true) },
                disposeBlock: { }),
            on: queue)

        return monitorResponse
    }
}

