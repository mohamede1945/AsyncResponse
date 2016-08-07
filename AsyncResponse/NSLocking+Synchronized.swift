//
//  NSLocking+Synchronized.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 8/7/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

extension NSLocking {
    func synchronized<T>(@noescape block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }
}
