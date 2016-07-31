/*
 Copyright 2015, Max Howell; mxcl@me.com

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation

public var defaultQueue: dispatch_queue_t = dispatch_get_main_queue()
public var defaultBackgroundQueue: dispatch_queue_t = dispatch_get_global_queue(0, 0)

/**
 Zalgo is dangerous.

 Pass as the `on` parameter for a `then`. Causes the handler to be executed
 as soon as it is resolved. That means it will be executed on the queue it
 is resolved. This means you cannot predict the queue.

 In the case that the promise is already resolved the handler will be
 executed immediately.

 zalgo is provided for libraries providing promises that have good tests
 that prove unleashing zalgo is safe. You can also use it in your
 application code in situations where performance is critical, but be
 careful: read the essay at the provided link to understand the risks.

 - SeeAlso: http://blog.izs.me/post/59142742143/designing-apis-for-asynchrony
 */
public let zalgo: dispatch_queue_t = dispatch_queue_create("Zalgo", nil)

/**
 Waldo is dangerous.

 Waldo is zalgo, unless the current queue is the main thread, in which case
 we dispatch to the default background queue.

 If your block is likely to take more than a few milliseconds to execute,
 then you should use waldo: 60fps means the main thread cannot hang longer
 than 17 milliseconds. Don’t contribute to UI lag.

 Conversely if your then block is trivial, use zalgo: GCD is not free and
 for whatever reason you may already be on the main thread so just do what
 you are doing quickly and pass on execution.

 It is considered good practice for asynchronous APIs to complete onto the
 main thread. Apple do not always honor this, nor do other developers.
 However, they *should*. In that respect waldo is a good choice if your
 then is going to take a while and doesn’t interact with the UI.

 Please note (again) that generally you should not use zalgo or waldo. The
 performance gains are neglible and we provide these functions only out of
 a misguided sense that library code should be as optimized as possible.
 If you use zalgo or waldo without tests proving their correctness you may
 unwillingly introduce horrendous, near-impossible-to-trace bugs.

 - SeeAlso: zalgo
 */
public let waldo: dispatch_queue_t = dispatch_queue_create("Waldo", nil)

extension dispatch_queue_t {
    func executeConsideringZalgoAndWaldo(block: () -> Void) {
        if self === zalgo {
            block()
        } else if self === waldo {
            if NSThread.isMainThread() {
                dispatch_async(dispatch_get_global_queue(0, 0), block)
            } else {
                block()
            }
        } else {
            dispatch_async(self, block)
        }
    }
}
