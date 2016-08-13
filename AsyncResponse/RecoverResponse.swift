//
//  RecoverResponse.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 8/13/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

public class RecoverResponse<T>: Response<T> {

    public init(result: Result<T>, on queue: dispatch_queue_t, recovery: ErrorType throws -> Response<T>) {
        super.init { resolver -> Disposable in
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
            return NoOperationDisposable()
        }
    }
}
