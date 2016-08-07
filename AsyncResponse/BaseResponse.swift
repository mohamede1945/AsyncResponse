//
//  BaseResponse.swift
//  AsyncResponse
//
//  Created by Mohamed Afifi on 7/24/16.
//  Copyright © 2016 Varaw. All rights reserved.
//

import Foundation



struct Completion<Value> {
    let queue: dispatch_queue_t
    let completion: Result<Value> -> Void
}

public class BaseResponse<T>: CustomStringConvertible, CustomDebugStringConvertible {

    private let resultLock = NSLock()

    var _completed: Bool = false

    var _result: Result<T>? = nil

    var completions: [Completion<T>] = []

    private var listeners: [(dispatch_queue_t, BlockResponseResolver<T>)] = []

    private var _diposable: Disposable?

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
        resolve(.Success(value))
    }

    public init(error: ErrorType) {
        resolve(.Error(error))
    }

    public init(@noescape resolution: StreamResponseResolver<T> -> Disposable?) {
        let resolver = StreamResponseResolver<T>(response: self)
        _diposable = resolution(resolver)
    }

    func synchronized<T>(@noescape block: () throws -> T) rethrows -> T {
        return try resultLock.synchronized(block)
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

    public func always(on queue: dispatch_queue_t, completion: Result<T> -> Void) -> Self {

        let completion = Completion(queue: queue, completion: completion)

        let result: Result<T>? = synchronized {
            if !_completed {
                completions.append(completion)
            }
            return _result
        }

        if let result = result {
            executeCompletions([completion], withResult: result)
        }

        return self
    }

    func addListener(listener: BlockResponseResolver<T>, on queue: dispatch_queue_t) -> Self {

        let (result, completed): (Result<T>?, Bool) = synchronized {
            if !_completed {
                listeners.append((queue, listener))
            }
            return (_result, _completed)
        }

        if let result = result {
            queue.executeConsideringZalgoAndWaldo {
                if completed {
                    listener.resolve(result)
                } else {
                    listener.element(result)
                }
            }
        }

        return self
    }

    func resolve(result: Result<T>) {
        let (multipleResolution, completions, listeners): (Bool, [Completion<T>], [(dispatch_queue_t, BlockResponseResolver<T>)]) = synchronized {
            let multipleCompletion = _completed
            _completed = true

            _result = result

            let completions = self.completions
            self.completions.removeAll()

            let listeners = self.listeners
            self.listeners.removeAll()

            return (multipleCompletion, completions, listeners)
        }

        if multipleResolution {
            NSLog("[AsyncResponse] [Warning] Response '\(self)' is resolved multiple times.")
        }

        executeCompletions(completions, withResult: result)

        for (queue, resolver) in listeners {
            queue.executeConsideringZalgoAndWaldo {
                resolver.resolve(result)
            }
        }
    }

    func element(result: Result<T>) {
        let (completions, listeners): ([Completion<T>], [(dispatch_queue_t, BlockResponseResolver<T>)]) = synchronized {
            _result = result
            return (self.completions, self.listeners)
        }

        executeCompletions(completions, withResult: result)

        for (queue, resolver) in listeners {
            queue.executeConsideringZalgoAndWaldo {
                resolver.element(result)
            }
        }
    }

    public func dispose() {
        let (resolvers, disposable): ([BlockResponseResolver<T>], Disposable?) = synchronized {

            let diposable = _diposable
            _diposable = nil

            let resolvers = self.listeners.map { $0.1 }
            self.listeners.removeAll()
            completions.removeAll()

            return (resolvers, diposable)
        }

        disposable?.dispose()

        resolvers.forEach { $0.dispose() }
    }
}
