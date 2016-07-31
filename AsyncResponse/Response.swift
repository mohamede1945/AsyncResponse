//
//  Response.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 7/30/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

public class Response<T>: BaseResponse<T>, ResponseType {

    public override init(_ value: T) {
        super.init(value)
    }

    public override init(error: ErrorType) {
        super.init(error: error)
    }

    public override init(@noescape resolvers: (success: (T) -> Void, failure: (ErrorType) -> Void) throws -> Void) {
        super.init(resolvers: resolvers)
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

    public class func asyncResponse() -> (response: Response<T>, success: (T) -> Void, failure: (ErrorType) -> Void) {
        var success: ((T) -> Void)!
        var failure: ((ErrorType) -> Void)!
        let response = Response {
            success = $0
            failure = $1
        }
        return (response, success, failure)
    }

    override func done(completedResult: Result<T>) {
        let (multipleCompletion, completions): (Bool, [Completion<T>]) = synchronized {
            let multipleCompletion = _result != nil

            _result = completedResult
            let completions = self.completions
            self.completions.removeAll()
            return (multipleCompletion, completions)
        }

        if multipleCompletion {
            NSLog("[AsyncResponse] [Warning] Response '\(self)' is completed multiple times.")
        }

        executeCompletions(completions, withResult: completedResult)
    }

    public func always(on queue: dispatch_queue_t, completion: Result<T> -> Void) -> Self {

        let completion = Completion(queue: queue, completion: completion)

        synchronized {
            if let result = _result {
                executeCompletions([completion], withResult: result)
            } else {
                completions.append(completion)
            }
        }

        return self
    }

    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> Response<U>) -> Response<U> {

        let (monitorResponse, _, _) = Response<U>.asyncResponse()
        monitorResponse.label = "NextAnywayMonitor"

        always(on: queue) { result in
            do {
                try after(result)
                    .always(on: zalgo) { monitorResponse.done($0) }
            } catch {
                monitorResponse.done(.Error(error))
            }
        }

        return monitorResponse
    }

    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> StreamResponse<U>) -> StreamResponse<U> {

        let (monitorResponse, _, _) = StreamResponse<U>.asyncResponse()

        monitorResponse.label = "NextAnywayMonitor"

        always(on: queue) { result in
            do {
                try after(result)
                    .always(on: zalgo) { monitorResponse.done($0) }
            } catch {
                monitorResponse.done(.Error(error))
            }
        }

        return monitorResponse
    }
}

extension Response {
    public var completed: Bool {
        return result != nil
    }
}

extension Response {

    public func nextAnyway<U>(on queue: dispatch_queue_t = defaultQueue, after: Result<T> throws -> U) -> Response<U> {
        return nextAnyway(on: queue) { result in
            return Response<U> { success, _ in
                success(try after(result))
            }.withLabel("NextAnyway.Map")
        }
    }

    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> Response<U>) -> Response<U> {
        return nextAnyway(on: queue) { try after($0.get()) }
    }

    public func next<U>(on queue: dispatch_queue_t = defaultQueue, after: T throws -> U) -> Response<U> {
        return nextAnyway(on: queue) { try after($0.get()) }
    }

    public func nextInBackground<U>(after: T throws -> Response<U>) -> Response<U> {
        return next(on: defaultBackgroundQueue, after: after)
    }

    public func nextInBackground<U>(after: T throws -> U) -> Response<U> {
        return next(on: defaultBackgroundQueue, after: after)
    }

    public func asVoid() -> Response<Void> {
        return next(on: zalgo) { _ in return }
    }

    public func recover(on queue: dispatch_queue_t = defaultQueue, recovery: ErrorType throws -> Response<T>) -> Response<T> {
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

    public func recover(on queue: dispatch_queue_t = defaultQueue, recovery: ErrorType throws -> T) -> Response<T> {
        return recover(on: queue) { error -> Response<T> in
            return Response { success, _ in
                try success(recovery(error))
            }.withLabel("Recover.Map")
        }
    }
}
