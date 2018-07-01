//
//  RecurringTransaction.swift
//  Budget
//
//  Created by Mike Kari Anderson on 6/23/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Firebase

class RecurringTransaction: BudgetRecord {
    var amount: Double = 0.0
    var cash: Bool
    var category: String
    var end: String
    var name: String
    var note: String?
    var period: String
    var start: String
    var transfer: Bool
    
    var deposit : Bool {
        get { return amount >= 0 }
    }
    
    required init?(_ snapshot: DataSnapshot) {
        self.category = ""
        self.end = ""
        self.period = ""
        self.start = ""
        self.name = ""
        self.cash = false
        self.transfer = false
        
        super.init(snapshot)
        
        if !self.fromObject(value: snapshot.value as AnyObject) { return nil }
    }
    
    required init?(data: AnyObject) {
        self.category = ""
        self.end = ""
        self.period = ""
        self.start = ""
        self.name = ""
        self.cash = false
        self.transfer = false
        
        super.init(data: data)
        
        if !self.fromObject(value: data) { return nil }
    }
    
    private func fromObject(value: AnyObject) -> Bool {
        guard
            let amount = value["amount"] as? Double,
            let category = value["category"] as? String,
            let end = value["end"] as? String,
            let name = value["name"] as? String,
            let period = value["period"] as? String,
            let start = value["start"] as? String
            else {
                return false
        }
        
        self.amount = amount
        self.category = category
        self.end = end
        self.name = name
        self.period = period
        self.start = start
        
        self.cash = value["cash"] as? Bool ?? false
        self.note = value["note"] as? String
        self.transfer = value["transfer"] as? Bool ?? false
        
        return true
    }
    
    override func asObject() -> [AnyHashable: Any] {
        var result: [AnyHashable:Any] = [:]
        
        result["amount"] = self.amount
        result["category"] = self.category
        result["end"] = self.end
        result["name"] = self.name
        result["period"] = self.period
        result["start"] = self.start
        
        // nil values are ignored on the firebase end, just set them
        result["note"] = self.note
        
        // avoid storing false boolean values since nils are also parsed
        if self.cash { result["cash"] = true }
        if self.transfer { result["transfer"] = true }
        
        return result
    }
}
