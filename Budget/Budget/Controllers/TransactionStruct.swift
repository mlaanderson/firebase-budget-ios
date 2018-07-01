//
//  Transaction.swift
//  Budget
//
//  Created by Mike Kari Anderson on 6/9/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation
import Firebase

struct TransactionStruct {
    var ref: DatabaseReference?
    var id: String
    var date: String
    var category: String
    var name: String
    var amount: Double
    var cash: Bool
    var paid: Bool
    var transfer: Bool
    var note: String?
    var check: String?
    var recurring: String?
    
    
    var DateVal : Date {
        return Date.parseFb(value: self.date)!
    }
    
    init(date: String, category: String, name: String, amount: Double, cash: Bool?, paid: Bool?, transfer: Bool?, note: String?, check: String?, recurring: String?) {
        self.ref = nil
        self.id = ""
        self.date = date
        self.category = category
        self.name = name
        self.amount = amount
        self.cash = cash == nil ? false : cash!
        self.paid = paid == nil ? false : paid!
        self.transfer = transfer == nil ? false : transfer!
        self.note = note
        self.check = check
        self.recurring = recurring
    }
    
    init?(snapshot: DataSnapshot) {
        guard
            let value = snapshot.value as? [String: AnyObject],
            let category = value["category"] as? String,
            let date = value["date"] as? String,
            let name = value["name"] as? String,
            let amount = value["amount"] as? Double,
            let cash = value["cash"] as? Bool?,
            let paid = value["paid"] as? Bool?,
            let transfer = value["transfer"] as? Bool?,
            let note = value["note"] as? String?,
            let check = value["check"] as? String?,
            let recurring = value["recurring"] as? String?
        else {
            return nil
        }
        
        self.ref = snapshot.ref
        self.id = snapshot.key
        self.date = date
        self.category = category
        self.name = name
        self.amount = amount
        self.cash = cash == nil ? false : cash!
        self.paid = paid == nil ? false : paid!
        self.transfer = transfer == nil ? false : transfer!
        self.note = note
        self.check = check
        self.recurring = recurring
    }
    
    init?(ref: DatabaseReference, record: [String: Any]) {
        self.ref = ref;
        self.id = ref.key
        self.date = record["date"] as! String
        self.category = record["category"] as! String
        self.name = record["name"] as! String
        self.amount = Double(truncating: record["amount"] as! NSNumber)
        self.cash = Bool(truncating: (record["cash"] ?? 0) as! NSNumber)
        self.paid = Bool(truncating: (record["paid"] ?? 0) as! NSNumber)
        self.transfer = Bool(truncating: (record["transfer"] ?? 0) as! NSNumber)
        self.note = record["note"] as! String?
        self.check = record["check"] as! String?
        self.recurring = record["recurring"] as! String?
    }
    
    func optStringToAny(value: String?) -> Any? {
        if value == nil { return nil }
        if (value!.isEmpty) { return nil }
        return value as Any
    }
    
    func optBoolToAny(value: Bool?) -> Any? {
        if value == nil { return nil }
        if value! == false { return nil }
        return true as Any
    }
    
    func toAnyObject() -> Any {
        let note : Any? = optStringToAny(value: self.note)
        let check : Any? = optStringToAny(value: self.check)
        let recurring : Any? = optStringToAny(value: self.recurring)
        let cash : Any? = optBoolToAny(value: self.cash)
        let paid : Any? = optBoolToAny(value: self.paid)
        let transfer : Any? = optBoolToAny(value: self.transfer)

        return [
            "date": date,
            "category": category,
            "name": name,
            "amount": amount,
            "cash": cash,
            "paid": paid,
            "transfer": transfer,
            "note": note,
            "check": check,
            "recurring": recurring
        ]
    }
    
}
