//
//  Configuration.swift
//  Budget
//
//  Created by Mike Kari Anderson on 6/10/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation
import Firebase

class ConfigurationStructure {
    private static let DEFAULT_CATEGORIES : [String] = [
        "Income",
        "Charity",
        "Saving",
        "Housing",
        "Utilities",
        "Food",
        "Clothing",
        "Transportation",
        "Medical",
        "Insurance",
        "Personal",
        "Recreation",
        "Debt"
    ]
    private static let DEFAULT_PERIOD_START = "2016-06-24"
    private static let DEFAULT_PERIOD_LENGTH = "2 weeks"
    
    var categories: [String]
    var periodStart: String
    var periodLength: String
    var showWizard: Bool
    
    private var didLoad = false
    private var observers = [() -> Void]()
    
    private func fire() {
        repeat {
            let observer = observers.removeFirst()
            observer()
        } while observers.count > 0
    }
    
    func observe(with: @escaping () -> Void) {
        if didLoad == true {
            with()
        } else {
            observers.append(with)
        }
    }
    
    init() {
        self.categories = ConfigurationStructure.DEFAULT_CATEGORIES
        self.periodStart = "2016-06-24"
        self.periodLength = "2 weeks"
        self.showWizard = true
    }
    
    init(ref: DatabaseReference) {
        self.categories = ConfigurationStructure.DEFAULT_CATEGORIES
        self.periodStart = "2016-06-24"
        self.periodLength = "2 weeks"
        self.showWizard = true
        
        ref.child("config").observeSingleEvent(of: .value) { snapshot in
            let value = snapshot.value as! [String: Any]
            let periods = value["periods"] as? [String: Any]
            
            if value["categories"] == nil {
                self.categories = ConfigurationStructure.DEFAULT_CATEGORIES
            } else {
                self.categories = value["categories"] as! [String]
            }
            
            if value["showWizard"] != nil {
                self.showWizard = value["showWizard"] as! Bool
            } else {
                self.showWizard = false
            }
            
            if periods != nil && periods?["start"] != nil {
                self.periodStart = periods?["start"] as! String
            } else {
                self.periodStart = ConfigurationStructure.DEFAULT_PERIOD_START
            }
            
            if periods != nil && periods?["length"] != nil {
                self.periodStart = periods?["start"] as! String
            } else {
                self.periodStart = ConfigurationStructure.DEFAULT_PERIOD_START
            }
            
            self.didLoad = true
            self.fire()
        }
    }
}
