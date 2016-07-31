//
//  GCD.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 7/18/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

extension dispatch_queue_t {

    public func async<SuccessData>(block: () throws -> SuccessData) -> Response<SuccessData> {
        return Response { success, failure in
            executeConsideringZalgoAndWaldo {
                do {
                    try success(block())
                } catch {
                    failure(error)
                }
            }
        }.withLabel("dispatch_async")
    }

    public func after<SuccessData>(delay: NSTimeInterval, block: () throws -> SuccessData) -> Response<SuccessData> {
        let delta = delay * NSTimeInterval(NSEC_PER_SEC)
        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(delta))

        return Response { success, failure in
            dispatch_after(when, self) {
                do {
                    try success(block())
                } catch {
                    failure(error)
                }
            }
        }.withLabel("dispatch_after")
    }
}
