//
//  Resolver.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 8/6/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

public protocol Resolver: Disposable {

    associatedtype T
    func resolve(result: Result<T>)
}

extension Resolver {
    public func resolveSuccess(value: T) {
        return resolve(.Success(value))
    }

    public func resolveError(error: ErrorType) {
        return resolve(.Error(error))
    }
}

public struct ResponseResolver<T>: Resolver {

    let resolver: StreamResponseResolver<T>

    public func resolve(result: Result<T>) { resolver.resolve(result) }

    public func dispose() { resolver.dispose() }
}

public struct StreamResponseResolver<T>: Resolver {

    let response: BaseResponse<T>

    public func element(result: Result<T>) { response.element(result) }
    public func resolve(result: Result<T>) { response.resolve(result) }

    public func dispose() { response.dispose() }
}

public struct BlockResponseResolver<T>: Resolver {

    let elementBlock: Result<T> -> Void
    let resolveBlock: Result<T> -> Void
    let disposeBlock: () -> Void

    public func element(result: Result<T>) { elementBlock(result) }
    public func resolve(result: Result<T>) { resolveBlock(result) }

    public func dispose() { disposeBlock() }
}
