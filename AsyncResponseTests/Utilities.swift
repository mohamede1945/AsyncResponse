//
//  Utilities.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 7/26/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation
import AsyncResponse

enum Error: ErrorType {
    case GeneralError
    case CustomError
}

func operation<T>(value: T, error: Error? = nil, queue: dispatch_queue_t = dispatch_get_main_queue()) -> Response<T> {
    return queue.after(0.1) {
        if let error = error {
            throw error
        }
        return value
    }
}

func streamOperation<T>(values: [T], errors: [Int: Error] = [:], queue: dispatch_queue_t = dispatch_get_main_queue()) -> StreamResponse<T> {

    var stopped: Bool = false
    let lock = NSLock()

    let (response, success, failure) = StreamResponse<T>.asyncResponse(stopStreaming: {
        lock.lock()
        stopped = true
        lock.unlock()
    })

    func enqueue(index: Int) {

        guard index < values.count else {
            return
        }

        lock.lock()
        defer { lock.unlock() }
        guard !stopped else {
            return
        }

        queue.after(0.1) {
            if let error = errors[index] {
                failure(error)
            } else {
                success(values[index])
            }
            enqueue(index + 1)
        }
    }
    enqueue(0)
    return response
}
