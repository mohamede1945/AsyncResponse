//
//  dispatch_queue_t+AsyncResponse.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 7/18/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation
import Dispatch

extension dispatch_queue_t {

    public func async<T>(block: () throws -> T) -> Response<T> {
        return Response { (resolver: ResponseResolver) in
            executeConsideringZalgoAndWaldo {
                do {
                    try resolver.resolve(.Success(block()))
                } catch {
                    resolver.resolve(.Error(error))
                }
            }
        }.withLabel("dispatch_async")
    }

    public func after<T>(delay: NSTimeInterval, block: () throws -> T) -> Response<T> {
        let delta = delay * NSTimeInterval(NSEC_PER_SEC)
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(delta))

        return Response { (resolver: ResponseResolver) in
            dispatch_after(when, self) {
                do {
                    try resolver.resolve(.Success(block()))
                } catch {
                    resolver.resolve(.Error(error))
                }
            }
        }.withLabel("dispatch_after")
    }
}
