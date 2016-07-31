//
//  BaseResponse.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 7/24/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation

extension NSLocking {
    func synchronized<T>(@noescape block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
}

struct Completion<Value> {
    let queue: dispatch_queue_t
    let completion: Result<Value> -> Void
}

public class BaseResponse<T>: CustomStringConvertible, CustomDebugStringConvertible {

    private let resultLock = NSLock()

    var _result: Result<T>? = nil

    var completions: [Completion<T>] = []

    public var label: String? = nil

    public var result: Result<T>? {
        return synchronized { _result }
    }

    public var description: String {
        let resultDescription: String
        if let result = result {
            resultDescription = result.description
        } else {
            resultDescription = "pending..."
        }

        var properties = ""
        if let label = label {
            properties += "label='\(label)' "
        }
        properties += "result='\(resultDescription)'"

        return "<\(self.dynamicType) \(String(format:"%p", unsafeBitCast(self, Int.self))) " + properties + ">"
    }

    public var debugDescription: String {
        return description
    }

    public init(_ value: T) {
        done(.Success(value))
    }

    public init(error: ErrorType) {
        done(.Error(error))
    }

    public init(@noescape resolvers: (success: (T) -> Void, failure: (ErrorType) -> Void) throws -> Void) {
        do {
            try resolvers(success: { self.done(.Success($0)) }, failure: { error in
                self.done(.Error(error))
            })
        } catch {
            self.done(.Error(error))
        }
    }

    func synchronized<T>(@noescape block: () -> T) -> T {
        return resultLock.synchronized(block)
    }

    public func withLabel(label: String) -> Self {
        self.label = label
        return self
    }

    func executeCompletions(completions: [Completion<T>], withResult result: Result<T>) {
        for completion in completions {
            completion.queue.executeConsideringZalgoAndWaldo { completion.completion(result) }
        }
    }

    func done(completedResult: Result<T>) {
        fatalError("should be implmeented by subclasses")
    }
}
