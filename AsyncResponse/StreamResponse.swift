//
//  StreamResponse.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 7/30/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

private protocol StreamType {
    func stopStreaming()
}

public class StreamResponse<T>: BaseResponse<T>, ResponseType, StreamType {

    private var children: [StreamType] = []
    private let stopStreamingOperation: (() -> Void)?

    public override init(_ value: T) {
        self.stopStreamingOperation = nil
        super.init(value)
    }

    public override init(error: ErrorType) {
        self.stopStreamingOperation = nil
        super.init(error: error)
    }

    public init(stopStreaming: (() -> Void)? = nil, @noescape resolvers: (success: (T) -> Void, failure: (ErrorType) -> Void) throws -> Void) {
        self.stopStreamingOperation = stopStreaming
        super.init(resolvers: resolvers)
    }

    public class func asyncResponse(stopStreaming stopStreaming: (() -> Void)? = nil) -> (response: StreamResponse<T>, success: (T) -> Void, failure: (ErrorType) -> Void) {
        var success: ((T) -> Void)!
        var failure: ((ErrorType) -> Void)!

        let response = StreamResponse(stopStreaming: stopStreaming) {
            success = $0
            failure = $1
        }
        return (response, success, failure)
    }

    override func done(completedResult: Result<T>) {
        let completions: [Completion<T>] = synchronized {
            _result = completedResult
            return self.completions
        }

        executeCompletions(completions, withResult: completedResult)
    }

    public func stopStreaming() {
        let children: [StreamType] = synchronized {
            completions.removeAll()
            let children = self.children
            self.children.removeAll()
            return children
        }

        stopStreamingOperation?() // thread-safe, since it's immutable

        children.forEach { $0.stopStreaming() }
    }

    public func always(on queue: dispatch_queue_t, completion: Result<T> -> Void) -> Self {
        let completion = Completion(queue: queue, completion: completion)

        synchronized {
            if let result = _result {
                executeCompletions([completion], withResult: result)
            }
            completions.append(completion)
        }

        return self
    }

    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> Response<U>) -> StreamResponse<U> {

        let (monitorResponse, success, failure) = StreamResponse<U>.asyncResponse()
        synchronized { children.append(monitorResponse) }

        monitorResponse.label = "StreamResponse.Next"

        always(on: queue) { result in
            do {
                try after(result)
                    .always(on: zalgo) { nextResult in
                        switch nextResult {
                        case .Success(let value):
                            success(value)
                        case .Error(let error):
                            failure(error)
                        }
                }
            } catch {
                failure(error)
            }
        }
        
        return monitorResponse
    }
}

extension StreamResponse {

    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> U) -> StreamResponse<U> {
        return nextAnyway(on: queue) { result in
            return Response<U> { success, _ in
                success(try after(result))
                }.withLabel("NextAnyway.Map")
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
            return Response { success, failure in
                switch result {
                case .Success(let value):
                    success(value)
                case .Error(let error):
                    try recovery(error).always(on: queue) { recoveryResult in
                        switch recoveryResult {
                        case .Success(let value):
                            success(value)
                        case .Error(let error):
                            failure(error)
                        }
                    }
                }
                }.withLabel("Recover")
        }
    }

    public func recover(on queue: dispatch_queue_t = defaultQueue, recovery: ErrorType throws -> T) -> StreamResponse<T> {
        return recover(on: queue) { error -> Response<T> in
            return Response { success, _ in
                try success(recovery(error))
                }.withLabel("Recover.Map")
        }
    }

    @available(*, unavailable, message="Cannot return an optional Response")
    public func recover(on queue: dispatch_queue_t = defaultQueue, recovery: ErrorType throws -> Response<T>?) -> StreamResponse<T> { fatalError() }
}
