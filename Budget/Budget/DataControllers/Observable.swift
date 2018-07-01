//
//  Observable.swift
//  Budget
//
//  Created by Mike Kari Anderson on 6/24/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation

private protocol Invocable: class {
    func invoke(_ data: AnyObject?)
}

private protocol Disposable: class {
    func dispose()
}

class Observable<T: RawRepresentable, U: AnyObject> where T.RawValue == Int {
    typealias EventHandler = (U?) -> ()
    
    // this is the wrapper class that allows us to remove handlers
    class HandlerWrapper: Invocable, Disposable {
        let handler: EventHandler
        let event: Observable
        let name: Int
        
        init(name: Int, handler:@escaping EventHandler, event: Observable) {
            self.handler = handler
            self.event = event
            self.name = name
        }
        
        func invoke(_ data: AnyObject? = nil) {
            handler(data as? U)
        }
        
        func dispose() {
            event.handlers[self.name] = event.handlers[self.name]?.filter { $0 !== self }
        }
    }
    
    class SingleHandlerWrapper: HandlerWrapper {
        override func invoke(_ data: AnyObject? = nil) {
            handler(data as? U)
            dispose()
        }
    }
    
    private var handlers = [Int:[HandlerWrapper]]()
    
    func on(_ name: T, handler:@escaping EventHandler) -> HandlerWrapper {
        let wrapper = HandlerWrapper(name: name.rawValue, handler: handler, event: self)
        if var list = self.handlers[name.rawValue] {
            list.append(wrapper)
        } else {
            self.handlers[name.rawValue] = [wrapper]
        }
        
        return wrapper
    }
    
    func off(_ name: T? = nil) {
        if name != nil {
            // stop observing for the event name
            if let list = handlers[name!.rawValue] {
                for handler in list {
                    handler.dispose()
                }
            }
        } else {
            // stop observing for all events
            for list in handlers.values {
                for handler in list {
                    handler.dispose()
                }
            }
        }
    }
    
    func once(_ name: T, handler:@escaping EventHandler) {
        let wrapper = SingleHandlerWrapper(name: name.rawValue, handler: handler, event: self)
        if var list = self.handlers[name.rawValue] {
            list.append(wrapper)
        } else {
            self.handlers[name.rawValue] = [wrapper]
        }
    }
    
    func emit(_ name: T, _ data: U? = nil) {
        if let list = self.handlers[name.rawValue] {
            for handler in list {
                handler.invoke(data)
            }
        }
    }
}
