//
//  RecurringTransaction.swift
//  Budget
//
//  Created by Mike Kari Anderson on 6/17/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation
import Firebase

class RecurringTransactionStruct {
    var ref: DatabaseReference?
    var id: String
    var amount: Double
    var cash: Bool?
    var category: String
    var end: String
    var name: String
    var note: String?
    var period: String
    var start: String
    var transfer: Bool?
    
    var StartVal : Date {
        return Date.parseFb(value: self.start)!
    }
    
    var EndVal : Date {
        return Date.parseFb(value: self.end)!
    }
    
    init(start: String, end: String, period: String, category: String, name: String, amount: Double, cash: Bool?, transfer: Bool?, note: String?) {
        self.ref = nil
        self.id = ""
        self.start = start
        self.end = end
        self.period = period
        self.category = category
        self.name = name
        self.amount = amount
        self.cash = cash == nil ? false : cash!
        self.transfer = transfer == nil ? false : transfer!
        self.note = note
    }
    
    init?(snapshot: DataSnapshot) {
        guard
            let value = snapshot.value as? [String: AnyObject],
            let start = value["start"] as? String,
            let end = value["end"] as? String,
            let period = value["period"] as? String,
            let category = value["category"] as? String,
            let name = value["name"] as? String,
            let amount = value["amount"] as? Double,
            let cash = value["cash"] as? Bool?,
            let transfer = value["transfer"] as? Bool?,
            let note = value["note"] as? String?
            else {
                return nil
        }
        
        self.ref = snapshot.ref
        self.id = snapshot.key
        self.start = start
        self.end = end
        self.period = period
        self.category = category
        self.name = name
        self.amount = amount
        self.cash = cash == nil ? false : cash!
        self.transfer = transfer == nil ? false : transfer!
        self.note = note
    }
    
    init?(ref: DatabaseReference, value: [String: AnyObject]) {
        guard
            let start = value["start"] as? String,
            let end = value["end"] as? String,
            let period = value["period"] as? String,
            let category = value["category"] as? String,
            let name = value["name"] as? String,
            let amount = value["amount"] as? Double,
            let cash = value["cash"] as? Bool?,
            let transfer = value["transfer"] as? Bool?,
            let note = value["note"] as? String?
            else {
                return nil
        }
        
        self.ref = ref
        self.id = ref.key
        self.start = start
        self.end = end
        self.period = period
        self.category = category
        self.name = name
        self.amount = amount
        self.cash = cash == nil ? false : cash!
        self.transfer = transfer == nil ? false : transfer!
        self.note = note
    }
}
