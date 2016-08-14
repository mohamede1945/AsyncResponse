//
//  Disposable.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 8/7/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

public protocol Disposable {
    func dispose()
}

public struct NoOperationDisposable: Disposable {

    public init() {
    }

    public func dispose() {
    }
}

public struct BlockDisposable: Disposable {

    public let disposeBlock: () -> Void

    public init(disposeBlock: () -> Void) {
        self.disposeBlock = disposeBlock
    }

    public func dispose() {
        disposeBlock()
    }
}
