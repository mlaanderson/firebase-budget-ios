import Foundation
class Promise<T> {
    typealias ResolveHandler = (T?) -> ()
    typealias RejectHandler = (Any?) -> ()
    typealias FinallyHandler = () -> ()
    typealias PromiseHandler = (@escaping ResolveHandler, @escaping RejectHandler) -> ()
    
    private var isResolved: Bool = false
    private var isRejected: Bool = false
    private var resolveHandlers = [ResolveHandler]()
    private var rejectHandlers = [RejectHandler]()
    private var finallyHandlers = [FinallyHandler]()
    
    private var resolvedValue: T?
    private var rejectedValue: Any?
    
    init(_ completion:@escaping PromiseHandler) {
        completion(self.resolve, self.reject)
    }
    
    func resolve(_ value: T?) {
        isResolved = true
        resolvedValue = value
        
        for handler in resolveHandlers {
            handler(resolvedValue)
        }
        
        for handler in finallyHandlers {
            handler()
        }
    }
    
    func reject(_ error: Any?) {
        isRejected = true
        rejectedValue = error
        
        for handler in rejectHandlers {
            handler(rejectedValue)
        }
        
        for handler in finallyHandlers {
            handler()
        }
    }
    
    func then(_ handler:@escaping ResolveHandler) -> Promise<T> {
        if isRejected { return self }
        if isResolved {
            handler(resolvedValue)
            return self
        }
        resolveHandlers.append(handler)
        
        return self
    }
    
    func error(_ handler:@escaping RejectHandler) -> Promise<T> {
        if isResolved { return self }
        if isRejected {
            handler(rejectedValue)
            return self
        }
        rejectHandlers.append(handler)
        
        return self
    }
    
    func finally(_ handler:@escaping FinallyHandler) -> Promise<T> {
        if isResolved || isRejected {
            handler()
            return self
        }
        finallyHandlers.append(handler)
        return self
    }
    
    
    static func reject<U>(_ reason: Any? = nil) -> Promise<U> {
        let result = Promise<U>() { resolve, reject in }
        
        result.reject(reason)
        
        return result
    }
    
    static func resolve<U>(_ value: U? = nil) -> Promise<U> {
        let result = Promise<U>() { resolve, reject in }
        
        result.resolve(value)
        
        return result
    }
    
    
    static func all<U>(_ promises: [Promise<U>]) -> Promise<[U?]> {
        if promises.count <= 0 { return Promise<[U?]>.resolve([]) }
        
        let result = Promise<[U?]>() { resolve, reject in
            for promise in promises {
                let _ = promise.then() { value in
                    if promises.filter({ $0.isResolved == false }).count == 0 {
                        let values: [U?] = promises.map({ $0.resolvedValue })
                        resolve(values)
                    }
                }.error() { reason in
                    reject(reason)
                }
            }
        }
        return result
    }
    
    static func race<U>(_ promises: [Promise<U>]) -> Promise<U> {
        var isResolved = false
        var isRejected = false
        let result = Promise<U>() { resolve, reject in
            for promise: Promise<U> in promises {
                let _ = promise.then() { value in
                    if isResolved == false && isRejected == false {
                        isResolved = true
                        resolve(value)
                    }
                }.error() { reason in
                    if isResolved == false && isRejected == false {
                        isRejected = true
                        reject(reason)
                    }
                }
            }
        }
        return result
    }
}
