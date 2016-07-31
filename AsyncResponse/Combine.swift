//
//  Combine.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 7/19/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

public extension CollectionType where Generator.Element: ResponseType {

    func combine(aggregateErrors: Bool = false) -> Response<[Generator.Element.T]> {

        let (composite, success, failure) = Response<[Generator.Element.T]>.asyncResponse()

        let respones = Array(self)

        let progress = NSProgress(totalUnitCount: Int64(respones.count))
        progress.cancellable = false
        progress.pausable = false

        guard !isEmpty else {
            success([])
            return composite
        }

        var combinedValues: [Int: Generator.Element.T] = [:]
        var combinedErrors: [Int: ErrorType] = [:]
        let lock = NSLock()

        var pendingCount = respones.count
        for (index, response) in respones.enumerate() {

            response.always(on: zalgo) { result in
                lock.lock()
                defer { lock.unlock() }
                guard !composite.completed else { return }

                pendingCount -= 1

                switch result {
                case .Success(let data):
                    combinedValues[index] = data
                case .Error(let error):
                    guard aggregateErrors else {
                        failure(error)
                        return
                    }
                    combinedErrors[index] = error
                }

                if pendingCount == 0 {
                    if !combinedErrors.isEmpty {
                        failure(Error.Combine(combinedErrors.map { $0 }))
                    } else {
                        success(combinedValues.sort{ $0.0 < $1.0 }.map { $1 })
                    }
                }
            }
        }
        return composite
    }
}

extension Response {

    func combine<U>(aggregateErrors aggregateErrors: Bool = false, with other: Response<U>) -> Response<(T, U)> {
        return [self.asVoid(), other.asVoid()].combine().next {_ in 
            return (self.result!.success!, other.result!.success!)
        }
    }

    func combine<U, V>(aggregateErrors aggregateErrors: Bool = false, with other: Response<U>, and other2: Response<V>) -> Response<(T, U, V)> {
        return [self.asVoid(), other.asVoid(), other2.asVoid()].combine().next {_ in
            return (self.result!.success!, other.result!.success!, other2.result!.success!)
        }
    }
}
