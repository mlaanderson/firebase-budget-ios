//
//  Observable.swift
//  Budget
//
//  Created by Mike Kari Anderson on 6/23/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation

class Historical<T> {
    let current: T
    let previous: T?
    init(_ current: T, _ previous: T? = nil) {
        self.current = current
        self.previous = previous
    }
}


class ObservableWithData<T: RawRepresentable, U> : Observable<T, Historical<U>>  where T.RawValue == Int {
    
}
