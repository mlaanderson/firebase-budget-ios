//
//  Configuration.swift
//  Budget
//
//  Created by Mike Kari Anderson on 6/24/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation
import Firebase

struct Period {
    var start: Date;
    var end: Date;
    
    init(start: Date, end: Date) {
        self.start = start;
        self.end = end;
    }
}

class Configuration : BudgetRecord {
    
    var categories: [String]
    var start: String
    var length: String
    
    var startDate: Date {
        get {
            return Date.parseFb(value: self.start)!
        }
        set(value) {
            self.start = value.toFbString()
        }
    }
    
    var lengthTime: Timespan {
        get {
            return Timespan.parse(value: self.length)!
        }
        
        set(value) {
            self.length = String(value)
        }
    }
    
    required init?(_ snapshot: DataSnapshot) {
        categories = [String]()
        start = ""
        length = ""
        
        super.init(snapshot)
        
        if self.fromObject(value: snapshot.value as AnyObject) == false { return nil }
    }
    
    required init?(data: AnyObject) {
        categories = [String]()
        start = ""
        length = ""
        
        
        super.init(data: data)
        if !self.fromObject(value: data) { return nil }
    }
    
    private func fromObject(value: AnyObject) -> Bool {
        guard
            let categories = value["categories"] as? [String],
            let periods = value["periods"] as? [String:Any?],
            let start = periods["start"] as? String,
            let length = periods["length"] as? String
            else {
                return false
        }
        
        self.categories = categories
        self.start = start
        self.length = length
        
        return true
    }
    
    override func asObject() -> [AnyHashable: Any] {
        var result: [AnyHashable:Any] = [:]
        
        result["categories"] = self.categories
        result["category"] = [["start":self.start],["length":self.length]]
        
        return result
    }
    
    func calculatePeriod(date: Date) -> Period {
        let start = date.periodCalc(start: self.start, length: self.length)
        let end = start + self.length - "1 day"
        
        return Period(start: start, end: end)
    }
}
