//
//  Transaction.swift
//  Budget
//
//  Created by Mike Kari Anderson on 6/23/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Firebase

class BudgetRecord {
    var id: String?
    var ref: DatabaseReference?
    
    required init?(_ snapshot: DataSnapshot) {
        self.ref = snapshot.ref
        self.id = snapshot.key
    }
    
    required init?(data: AnyObject) {
        self.id = nil
        self.ref = nil
    }
    
    func asObject() -> [AnyHashable: Any] {
        return [:]
    }
}

