//
//  Cash.swift
//  Budget
//
//  Created by Mike Kari Anderson on 6/23/18.
//  Copyright © 2018 Mike Kari Anderson. All rights reserved.
//

import Foundation

class Cash {
    var hundreds: Int = 0
    var fifties: Int = 0
    var twenties: Int = 0
    var tens: Int = 0
    var fives: Int = 0
    var ones: Int = 0
    var quarters: Int = 0
    var dimes: Int = 0
    var nickels: Int = 0
    var pennies: Int = 0
    
    init() {}
    
    init(hundreds: Int = 0, fifties: Int = 0, twenties: Int = 0, tens: Int = 0, fives: Int = 0, ones: Int = 0, quarters: Int = 0, dimes: Int = 0, nickels: Int = 0, pennies: Int = 0) {
        self.hundreds = hundreds
        self.fifties = fifties
        self.twenties = twenties
        self.tens = tens
        self.fives = fives
        self.ones = ones
        self.quarters = quarters
        self.dimes = dimes
        self.nickels = nickels
        self.pennies = pennies
    }
    
    init(_ val: Double) {
        var value = abs(val)
        
        while value >= 100.0 {
            value -= 100.0
            self.hundreds += 1
        }
        
        while value >= 50.0 {
            value -= 50.0
            self.fifties += 1
        }
        
        while value >= 20.0 {
            value -= 20.0
            self.twenties += 1
        }
        
        while value >= 10.0 {
            value -= 10.0
            self.tens += 1
        }
        
        while value >= 5.0 {
            value -= 5.0
            self.fives += 1
        }
        
        while value >= 1.0 {
            value -= 1.0
            self.ones += 1
        }
        
        while value >= 0.25 {
            value -= 0.25
            self.quarters += 1
        }
        
        while value >= 0.10 {
            value -= 0.10
            self.dimes += 1
        }
        
        while value >= 0.05 {
            value -= 0.05
            self.nickels += 1
        }
        
        // ensure floating point bits aren't lost
        // round to the nearest whole penny
        while value >= 0.005 {
            value -= 0.01
            self.pennies += 1
        }
    }
    
    public static func + (left: Cash, right: Cash) -> Cash {
        let result = Cash()
        result.hundreds = left.hundreds + right.hundreds
        result.fifties = left.fifties + right.fifties
        result.twenties = left.twenties + right.twenties
        result.tens = left.tens + right.tens
        result.fives = left.fives + right.fives
        result.ones = left.ones + right.ones
        result.quarters = left.quarters + right.quarters
        result.dimes = left.dimes + right.dimes
        result.nickels = left.nickels + right.nickels
        result.pennies = left.pennies + right.pennies
        
        return result
    }
    
    public static func + (left: Cash, right: Double) -> Cash {
        return left + Cash(right)
    }
    
    public static func + (left: Double, right: Cash) -> Cash {
        return Cash(left) + right
    }
    
}

extension Double {
    func toCash() -> Cash {
        return Cash(self)
    }
    
    init(_ cashValue: Cash) {
        self = Double(cashValue.hundreds) * 100.0 +
            Double(cashValue.fifties) * 50.0 +
            Double(cashValue.twenties) * 20.0 +
            Double(cashValue.tens) * 10.0 +
            Double(cashValue.fives) * 5.0 +
            Double(cashValue.ones) +
            Double(cashValue.quarters) * 0.25 +
            Double(cashValue.dimes) * 0.10 +
            Double(cashValue.nickels) * 0.05 +
            Double(cashValue.pennies) * 0.01
    }
}

