//
//  race.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 7/19/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

public extension CollectionType where Generator.Element: ResponseType {

    func race() -> Response<(index: Int, value: Generator.Element.T)> {
        guard !isEmpty else {
            fatalError("firstToFinish cannot be invoked with empty array.")
        }

        let (composite, success, failure) = Response<(index: Int, value: Generator.Element.T)>.asyncResponse()
        let lock = NSLock()
        let totalCount = count
        for (index, response) in enumerate() {

            response.always(on: zalgo) { result in
                lock.lock()
                defer { lock.unlock() }

                switch result {
                case .Success(let data):
                    guard !composite.completed else { return }
                    success((index: index, value: data))
                case .Error(let error):
                    guard !composite.completed else { return }
                    failure(error)
                }
            }
        }
        return composite
    }
}
